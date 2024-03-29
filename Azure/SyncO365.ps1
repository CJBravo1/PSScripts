if ($null -eq $admincreds)
    {
    $admincreds = get-credential -Message "Enter Admin Credentials"
    }
$ADServer = $env:LOGONSERVER -replace ‘\\’,""
Write-Host "Syncing Active Directory" -ForegroundColor Green
Invoke-Command -ComputerName $ADServer -Credential $adminCreds -ScriptBlock {repadmin /syncall /APed} | out-null
Write-Host "Syncing Office 365" -ForegroundColor Cyan
Invoke-Command -ComputerName SERVER -ScriptBlock {Start-Adsyncsynccycle -PolicyType Delta} -Credential $admincreds
