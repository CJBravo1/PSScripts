Write-Host "Force Domain Controller Replication" -ForegroundColor Green
#Get Credentials
$CurrentUser = $env:USERNAME
if ($null -eq $adminCreds)
{
    $adminCreds = Get-Credential "DOMAIN\$CurrentUser"
}
#Invoke AD Sync Command
$ADServer = $env:LOGONSERVER -replace ‘\\’,""
Write-Host "Syncing Active Directory On Server $ADServer" -ForegroundColor Green
Invoke-Command -ComputerName $ADServer -Credential $adminCreds -ScriptBlock {repadmin /syncall /APed} | out-null