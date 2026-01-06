# Replication Checker Nagios
# Designed by Matthew Jones 2023
# Ver1.5 - 28/01/2015
# Created this script to check the status of replcation of VM's and then report any problems to Centreon for the team to monitor


param($args)

# Nagios Service Status Information
$failure_msg = "Critical - Replication Error" 
$success_msg = "OK - All Replication is good"
$warning_msg = "Warning - Replication Error" 

# Output replication status to a file
Get-VMReplication | Out-File "C:\Program Files\Centreon NSClient++\scripts\VMReplication.txt"

# Get Warnings
$warnings = Get-Content -Path "C:\Program Files\Centreon NSClient++\scripts\VMReplication.txt" | Select-String -pattern "Warning" -Quiet

# Get Criticals
$criticals = Get-Content -Path "C:\Program Files\Centreon NSClient++\scripts\VMReplication.txt" | Select-String -pattern "Critical" -Quiet

# Get Errors
$errors = Get-Content -Path "C:\Program Files\Centreon NSClient++\scripts\VMReplication.txt" | Select-String -pattern "Error" -Quiet

# Check if we have any warnings, criticals, or errors
if (!$warnings -and !$criticals -and !$errors)
{
    $nagios_status = 0
    $nagiosMessage = "OK - All VMs are replicating fine"
}
else
{
    if ($errors)
    {
        $nagios_status = 2
        $nagiosMessage = "Error - Replication Error"
    }
    elseif ($warnings)
    {	
        $nagios_status = 1
        $nagiosMessage = Get-Content -Path "C:\Program Files\Centreon NSClient++\scripts\VMReplication.txt" | Select-String -pattern "Warning"
    }
    elseif ($criticals)
    {
        $nagios_status = 2
        $nagiosMessage = Get-Content -Path "C:\Program Files\Centreon NSClient++\scripts\VMReplication.txt" | Select-String -pattern "Critical"
    }
}

# Remove line breaks from results
$nagiosMessage = $nagiosMessage -replace "`t|`n|`r",""
$nagiosMessage = $nagiosMessage -replace " ;|; ",";"

Write-Output $nagiosMessage
exit $nagios_status
