Write-Host "Connecting to Active Directory" -ForegroundColor Green
$ADServer = $env:LOGONSERVER -replace "\\",""
Write-Host "AD Server: $ADServer" -ForegroundColor Yellow
$CurrentUser = $env:USERNAME
$adminCreds = Get-Credential "DOMAIN\$CurrentUser"
$ActiveDirectory = New-PSSession -ComputerName $ADServer -Credential $adminCreds
Import-Module ActiveDirectory -PSSession $ActiveDirectory