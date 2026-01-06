$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, Size, FreeSpace

foreach ($d in $disk) {
    $deviceID = $d.DeviceID
    $size = [math]::Round($d.Size / 1GB, 2)
    $freeSpace = [math]::Round($d.FreeSpace / 1GB, 2)
    $usedSpace = [math]::Round(($d.Size - $d.FreeSpace) / 1GB, 2)
    
    Write-Host "DISK-$deviceID Size:$size GB Used:$usedSpace GB Free:$freeSpace GB"
}
