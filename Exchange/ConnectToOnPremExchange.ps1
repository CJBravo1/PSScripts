#Change Window Title
$host.ui.RawUI.WindowTitle = "Exchange Onpremises"
$PSSession = Get-PSSession | where {$_.configurationName -like "*exchange"}

if ($adminCreds -eq $null)
{
    $adminCreds = Get-Credential -Message "Enter your Admin Credentials"
}

if ($PSSession -eq $null)
{
    $ExchServer = Read-Host "Enter Exchange Server"
    $ExchSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$ExchServer/powershell" -Credential $adminCreds
    Import-PSSession $ExchSession
}