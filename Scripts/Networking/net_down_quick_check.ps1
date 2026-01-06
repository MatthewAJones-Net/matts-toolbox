# netdown.ps1 - quick network triage - it will do some quick checks to help diagnose some problems quicker
# The checks it does are Check if the device has a network card and if it active > checks what IP DNS and Gateway the device has > Then will run pings to the DNS server > Then pings to Gateway
# Then will run pings to 8.8.8.8 and 1.1.1.1 > Then does a trace route for further Diagnostics

$TimeoutMs   = 1000
$TestHosts   = @("google.com","bbc.co.uk")
$PublicIPs   = @("1.1.1.1","8.8.8.8")
$TraceTarget = "google.com"

function Ping2([string]$Target) {
  $null = & ping.exe -n 2 -w $TimeoutMs $Target
  return ($LASTEXITCODE -eq 0)
}

Write-Host ""
Write-Host "=== Network Triage === $(Get-Date)"
Write-Host ""

$cfg = Get-NetIPConfiguration |
  Where-Object { $_.NetAdapter.Status -eq "Up" -and $_.IPv4Address } |
  Select-Object -First 1

if (-not $cfg) {
  Write-Host "No active adapter with IPv4. Enable Wi-Fi/Ethernet / check NIC." -ForegroundColor Red
  Read-Host "Press Enter to exit"
  exit 1
}

$ifIndex = $cfg.InterfaceIndex
$ip      = $cfg.IPv4Address.IPAddress
$gw      = $cfg.IPv4DefaultGateway.NextHop

Write-Host "Adapter: $($cfg.NetAdapter.Name)"
Write-Host "IP:      $ip"
Write-Host "GW:      $gw"
Write-Host ""

$sum = [ordered]@{
  IPValid   = $false
  DNS       = @()
  DNSPing   = @{}
  GWPing    = $null
  HostPing  = @{}
  PubPing   = @{}
  Verdict   = ""
}

try {
  Write-Host "1) IP check"
  if (-not $ip -or $ip -eq "0.0.0.0") {
    Write-Host "No IPv4. Likely DHCP/VLAN/physical." -ForegroundColor Red
    $sum.Verdict = "No IPv4 on PC (DHCP/VLAN/physical)."
    return
  }

  if ($ip -like "169.254.*") {
    Write-Host "APIPA ($ip). DHCP not giving an address." -ForegroundColor Red
    $sum.Verdict = "APIPA - DHCP not responding / wrong VLAN / NAC."
    return
  }

  if (-not $gw -or $gw -eq "0.0.0.0") {
    Write-Host "No default gateway. DHCP option/static routing issue." -ForegroundColor Red
    $sum.Verdict = "No default gateway (DHCP option 3 / routing)."
    return
  }

  Write-Host "IP looks valid." -ForegroundColor Green
  $sum.IPValid = $true
  Write-Host ""

  Write-Host "2) DNS check"
  $dns = (Get-DnsClientServerAddress -InterfaceIndex $ifIndex -AddressFamily IPv4).ServerAddresses
  $sum.DNS = $dns

  if (-not $dns -or $dns.Count -eq 0) {
    Write-Host "No DNS set. Name lookups will fail." -ForegroundColor Red
  } else {
    Write-Host ("DNS: " + ($dns -join ", ")) -ForegroundColor Gray
    foreach ($d in $dns) {
      $ok = Ping2 $d
      $sum.DNSPing[$d] = $ok
      if ($ok) { Write-Host "DNS reachable: $d" -ForegroundColor Green }
      else     { Write-Host "DNS NOT reachable: $d" -ForegroundColor Red }
    }
  }
  Write-Host ""

  Write-Host "3) Gateway ping"
  $gwOk = Ping2 $gw
  $sum.GWPing = $gwOk

  if ($gwOk) {
    Write-Host "Gateway reachable." -ForegroundColor Green
  } else {
    Write-Host "Can't ping gateway. Local VLAN/port issue OR gateway down." -ForegroundColor Red
    $sum.Verdict = "Gateway unreachable (local L2/VLAN/port) or gateway down."
    return
  }
  Write-Host ""

  Write-Host "4) External ping (hostnames)"
  $anyHostOk = $false
  foreach ($h in $TestHosts) {
    $ok = Ping2 $h
    $sum.HostPing[$h] = $ok
    if ($ok) { Write-Host "OK:   $h" -ForegroundColor Green; $anyHostOk = $true }
    else     { Write-Host "FAIL: $h" -ForegroundColor Red }
  }

  if ($anyHostOk) {
    $sum.Verdict = "Looks OK (at least one external host responded)."
    return
  }

  Write-Host ""
  Write-Host "Hostnames failed. Could be DNS or internet/edge." -ForegroundColor Yellow

  Write-Host ""
  Write-Host "5) Public IP ping (bypass DNS)"
  $anyPubOk = $false
  foreach ($p in $PublicIPs) {
    $ok = Ping2 $p
    $sum.PubPing[$p] = $ok
    if ($ok) { Write-Host "OK:   $p" -ForegroundColor Green; $anyPubOk = $true }
    else     { Write-Host "FAIL: $p" -ForegroundColor Red }
  }

  if ($anyPubOk) {
    $sum.Verdict = "Public IP reachable but hostnames fail = DNS issue."
    return
  }

  $sum.Verdict = "LAN OK, but no internet (edge/WAN/ISP/outbound ACL)."
}
finally {
  Write-Host ""
  Write-Host "=== Summary ==="
  Write-Host "IP valid:  $($sum.IPValid)"
  Write-Host "GW ping:   $($sum.GWPing)"
  if ($sum.DNS -and $sum.DNS.Count -gt 0) {
    Write-Host "DNS:       $($sum.DNS -join ', ')"
    foreach ($k in $sum.DNSPing.Keys) { Write-Host " - DNS $k ping: $($sum.DNSPing[$k])" }
  } else {
    Write-Host "DNS:       (none)"
  }
  foreach ($k in $sum.HostPing.Keys) { Write-Host "Ping $k : $($sum.HostPing[$k])" }
  foreach ($k in $sum.PubPing.Keys)  { Write-Host "Ping $k : $($sum.PubPing[$k])" }

  Write-Host ""
  Write-Host "Verdict: $($sum.Verdict)" -ForegroundColor Cyan
  Write-Host ""

  # Always run tracert at the end (best effort)
  Write-Host "=== Traceroute ==="
  Write-Host "tracert -d -h 20 $TraceTarget"
  & tracert.exe -d -h 20 $TraceTarget

  Write-Host ""
  Read-Host "Press Enter to close"
}
