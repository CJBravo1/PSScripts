#Change Window Title
$host.ui.RawUI.WindowTitle = "Exchange Onpremises"
$PSSession = Get-PSSession | where {$_.configurationName -like "*exchange"}

if ($PSSession -eq $null)
{
    $ExchServer = Read-Host "Enter Exchange Server"
    $ExchSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$ExchServer/powershell"
    Import-PSSession $ExchSession
}