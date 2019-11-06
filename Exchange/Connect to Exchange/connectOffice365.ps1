#Change Window Title
$host.ui.RawUI.WindowTitle = "Office 365"

#Get Login Credentials
$UserCredential = Get-Credential -Message "Enter your Office 365 Credentials"

#Make new session
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
#$protectionsession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.protection.outlook.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

#Connect to PsSession
Import-PSSession $Session -WarningAction SilentlyContinue
#Import-PSSession $protectionsession -WarningAction SilentlyContinue
Connect-MsolService -Credential $UserCredential

#Write-Host "Connected Domains" -ForegroundColor Green
#Get-MsolDomain -Status Verified

Write-Host "Have a lot of fun..." -ForegroundColor Green