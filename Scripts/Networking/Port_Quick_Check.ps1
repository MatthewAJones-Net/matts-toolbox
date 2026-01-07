#Port_Quick_Check.ps1 is a quick network tool to check if a port is open.You also have the option to Scan all ports 
#If the port not open it will do a quick ping to check if the host is alive from your device
#It will also give you a trace route to the device


param(
  [Parameter(Mandatory = $true)]
  [string]$Target
)

function Pause-End {
  Write-Host ""
  [void](Read-Host "Press Enter to close")
}

function Fail-Out([string]$msg) {
  Write-Host $msg
  Pause-End
}

function Resolve-Ip([string]$t) {
  try {
    return ([System.Net.Dns]::GetHostAddresses($t)[0]).IPAddressToString
  } catch {
    return $null
  }
}

function Test-TcpPort([string]$ip, [int]$port, [int]$timeoutMs) {
  $client = New-Object Net.Sockets.TcpClient
  try {
    $task = $client.ConnectAsync($ip, $port)
    if ($task.Wait($timeoutMs) -and $client.Connected) { return $true }
    return $false
  } catch {
    return $false
  } finally {
    $client.Close()
  }
}

function Scan-Ports([string]$ip, [int[]]$ports, [int]$timeoutMs) {
  $open    = New-Object System.Collections.Generic.List[int]
  $notOpen = New-Object System.Collections.Generic.List[int]

  $ports = $ports | Sort-Object -Unique
  $total = $ports.Count
  $i = 0

  Write-Host ""
  Write-Host "Scanning $total ports on $ip (timeout ${timeoutMs}ms each)..."
  Write-Host ""

  foreach ($p in $ports) {
    $i++
    Write-Progress -Activity "Port scan" -Status "Testing $p ($i of $total)" -PercentComplete (($i / $total) * 100)

    if (Test-TcpPort -ip $ip -port $p -timeoutMs $timeoutMs) {
      $open.Add($p) | Out-Null
      Write-Host ("OPEN     : {0}" -f $p)
    } else {
      $notOpen.Add($p) | Out-Null
    }
  }

  Write-Progress -Activity "Port scan" -Completed

  Write-Host ""
  if ($open.Count -eq 0) {
    Write-Host "Open TCP ports: (none found)"
  } else {
    Write-Host "Open TCP ports: $($open -join ', ')"
  }

  Write-Host ""
  if ($notOpen.Count -eq 0) {
    Write-Host "Not open ports: (none)"
  } else {
    Write-Host "Not open ports:"
    Write-Host (($notOpen | Sort-Object) -join ', ')
  }
}

# ---- Main ----

Write-Host ""
Write-Host "Select a test:"
Write-Host "  1) HTTP        (80)"
Write-Host "  2) HTTPS       (443)"
Write-Host "  3) SSH         (22)"
Write-Host "  4) SFTP (SSH)  (22)"
Write-Host "  5) SMTP        (25)"
Write-Host "  6) SMTP TLS    (587)"
Write-Host "  7) SMTPS       (465)"
Write-Host "  8) SIP         (5060)  (TCP)"
Write-Host "  9) SIP TLS     (5061)  (TCP)"
Write-Host " 10) RDP         (3389)"
Write-Host " 11) Custom single port"
Write-Host " 12) Scan common ports (safe shortlist)"
Write-Host " 13) Scan a custom range (capped)"
Write-Host ""

$choice = Read-Host "Enter choice (1-13)"

# Resolve once up front
$ip = Resolve-Ip $Target
if (-not $ip) { Fail-Out "FAIL: Could not resolve hostname."; return }

Write-Host ""
Write-Host "Target : $Target"
Write-Host "IP     : $ip"
Write-Host ""

$timeoutSingleMs = 2000
$timeoutScanMs   = 300

switch ($choice) {
  "1"  { $port = 80;   $service = "HTTP" }
  "2"  { $port = 443;  $service = "HTTPS" }
  "3"  { $port = 22;   $service = "SSH" }
  "4"  { $port = 22;   $service = "SFTP (SSH)" }
  "5"  { $port = 25;   $service = "SMTP" }
  "6"  { $port = 587;  $service = "SMTP TLS (Submission)" }
  "7"  { $port = 465;  $service = "SMTPS" }
  "8"  { $port = 5060; $service = "SIP (TCP)" }
  "9"  { $port = 5061; $service = "SIP TLS (TCP)" }
  "10" { $port = 3389; $service = "RDP" }

  "11" {
    $port = Read-Host "Enter custom port number"
    if (-not ($port -as [int]) -or $port -lt 1 -or $port -gt 65535) {
      Fail-Out "Invalid port number."
      return
    }
    $port = [int]$port
    $service = "Custom"
  }

  "12" {
    # Safe shortlist: common infra + web + mgmt + db + a few typical alt-web ports
    $common = @(
      20,21,22,23,25,53,67,68,80,110,111,123,135,137,138,139,143,161,389,443,445,
      465,587,636,993,995,1433,1521,2049,3306,3389,5060,5061,5432,5900,6379,8080,8443,9200
    )

    Scan-Ports -ip $ip -ports $common -timeoutMs $timeoutScanMs
    Pause-End
    return
  }

  "13" {
    $start = Read-Host "Start port"
    $end   = Read-Host "End port"

    if (-not ($start -as [int]) -or -not ($end -as [int])) {
      Fail-Out "Ports must be numbers."
      return
    }

    $start = [int]$start
    $end   = [int]$end

    if ($start -lt 1 -or $end -gt 65535 -or $start -gt $end) {
      Fail-Out "Invalid range."
      return
    }

    $count = ($end - $start + 1)

    # Safety cap to avoid accidental mega-scans
    $maxPorts = 256
    if ($count -gt $maxPorts) {
      Fail-Out "Range too large ($count ports). This tool caps scans to $maxPorts ports. Use a smaller range."
      return
    }

    $ports = $start..$end
    Scan-Ports -ip $ip -ports $ports -timeoutMs $timeoutScanMs
    Pause-End
    return
  }

  default {
    Fail-Out "Invalid selection."
    return
  }
}

# ---- Single port test path ----

Write-Host "Service: $service"
Write-Host "Port   : $port"
Write-Host ""

if (Test-TcpPort -ip $ip -port $port -timeoutMs $timeoutSingleMs) {
  Write-Host "OK: TCP port $port is OPEN on $ip"
  Pause-End
  return
}

Write-Host "WARN: TCP port $port is NOT open on $ip"

Write-Host ""
Write-Host "Ping test:"
try {
  Test-Connection $ip -Count 2 | Select Address, ResponseTime | Format-Table
} catch {
  Write-Host "Ping failed or blocked."
}

Write-Host ""
Write-Host "Traceroute:"
tracert -d -h 15 $ip

Write-Host ""
Write-Host "Result: Port is closed, filtered, or service not listening."
Pause-End



