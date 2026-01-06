# SSID you want static IP for
$TargetSSID = "MyOfficeWiFi"
$Interface = "Wi-Fi"

# Static IP settings
$IPAddress = "192.168.1.50"
$Prefix = 24
$Gateway = "192.168.1.1"
$DNS = "8.8.8.8","1.1.1.1"

# Get current SSID
$CurrentSSID = (netsh wlan show interfaces) | Select-String '^ *SSID' | ForEach-Object { ($_ -split ':')[1].Trim() }

if ($CurrentSSID -eq $TargetSSID) {
    Write-Host "Connected to $TargetSSID - applying static IP..."
    Set-NetIPInterface -InterfaceAlias $Interface -Dhcp Disabled -ErrorAction SilentlyContinue
    New-NetIPAddress -InterfaceAlias $Interface -IPAddress $IPAddress -PrefixLength $Prefix -DefaultGateway $Gateway -ErrorAction SilentlyContinue
    Set-DnsClientServerAddress -InterfaceAlias $Interface -ServerAddresses $DNS
}
else {
    Write-Host "Not connected to $TargetSSID - reverting to DHCP..."
    Set-NetIPInterface -InterfaceAlias $Interface -Dhcp Enabled
    Set-DnsClientServerAddress -InterfaceAlias $Interface -ResetServerAddresses
}
