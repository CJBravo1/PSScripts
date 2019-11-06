Write-Host "Force Domain Controller Replication, and then sysc BosCorpAADC to Office365" -ForegroundColor Green
#Creates variable to grab the server name of the closest Domain Controller to run the DC replication from.
$DC = $env:LOGONSERVER -replace ‘\\’,""

#Replication Command
repadmin /syncall $DC /APed

#Creates variable with command to run Domain to O365 sync
$Script =
{
    & "C:\Program Files\Microsoft Azure AD Sync\Bin\DirectorySyncClientCmd.exe" delta
}

#Command to kick off Sync command
Invoke-Command -ComputerName BOSCORPAADC.accruent.com -ScriptBlock $Script