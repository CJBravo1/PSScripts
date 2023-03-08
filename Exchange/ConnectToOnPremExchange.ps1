#Check for existing PS Session
$PSSession = Get-PSSession | Where-Object {$_.configurationName -like "*exchange"}

#Check for Admin Creds
if ($null -eq $adminCreds)
{
    $adminCreds = Get-Credential -Message "Enter your Admin Credentials"
}

if ($null -eq $PSSession)
{
    $ExchServer = Read-Host "Enter Exchange Server"
    $ExchSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$ExchServer/powershell" -Credential $adminCreds
    Import-PSSession $ExchSession
    $acceptedDomain = Get-AcceptedDomain | where {$_.Default -eq $true}
    $host.ui.rawui.windowtitle="$acceptedDomain Onprem Exchange"
    Write-Host "Have a lot of fun..." -ForegroundColor Green
}