Write-Host "Use this script to get the necessary information for the Excel Spreadsheet in this same folder" -ForegroundColor Green -BackgroundColor Blue

Write-Host "Enter your Office 365 Credentials"
$cred = Get-Credential -Message "Enter your Office 365 Credentials"

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell-liveid/ -Credential $cred -Authentication Basic -AllowRedirection
Import-PSSession $session -DisableNameChecking -WarningAction SilentlyContinue | out-null

Write-Host "Enter the Distribution Group's Email Address" -ForegroundColor Green
$GivenAddress = Read-Host

Get-DistributionGroup -Identity $GivenAddress | select name,primarysmtpaddress,displayname,alias

Write-Host "End of script"

pause

Write-Host "Really the end end of script"