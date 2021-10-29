#Get Credentials
$CurrentUser = $env:USERNAME
$CurrentUserEmail = "$CurrentUser@DOMAIN.com"

if ($null -eq $adminCreds)
{
    $adminCreds = Get-Credential "DOMAIN\a$CurrentUser"
}
$MailRelayServer = "smtp.DOMAIN.local"
$ToAddress = Read-Host -Prompt "Enter To Address"
Send-MailMessage -to $ToAddress -From $CurrentUserEmail -Bcc $CurrentUserEmail -Body "Testing Mailfow Please reply to this message" -Subject "Testing Mailflow $MailRelayServer" -SmtpServer $MailRelayServer
Write-Host "Mail Relay $MailRelayServer" -ForegroundColor Yellow
Write-Host "Test Message Sent to $ToAddress" -ForegroundColor Green
Write-Host "Test Message Sent to $CurrentUserEmail" -ForegroundColor Cyan