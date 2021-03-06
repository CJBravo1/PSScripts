#Exchange
$msolcred = Get-Credential -Message "Enter Office 365 Admin Password"

#PSSessions
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri  https://outlook.office365.com/powershell-liveid/?proxyMethod=RPS -Credential $msolcred -Authentication Basic -AllowRedirection
$ComplianceSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $MSOLcred -Authentication Basic -AllowRedirection
$protectionsession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.protection.outlook.com/powershell-liveid/ -Credential $msolcred -Authentication Basic -AllowRedirection

#Connect to Office 365 environment
#Write-Host "Connecting to Azure Active Directory" -ForegroundColor Magenta
Connect-MsolService -Credential $msolcred -WarningAction SilentlyContinue

#Import PSSessions
#Write-Host "Connecting to Exchange" -ForegroundColor Cyan
Import-PSSession $ExchangeSession -DisableNameChecking -WarningAction SilentlyContinue | out-null
Import-PSSession $ComplianceSession -DisableNameChecking -WarningAction SilentlyContinue | out-null
#Import-PSSession $protectionsession -DisableNameChecking -WarningAction SilentlyContinue | out-null

#Re-Write WindowTitle
$MSOLDomains = Get-MsolDomain
$domain = $MSOLDomains[0].Name
$Host.UI.RawUI.WindowTitle="$domain"

Clear-Host
Write-Host "Windows PowerShell"
Write-Host "Copyright (C) Microsoft Corporation. All rights reserved."
Write-Host ""
Write-Host "Have a lot of fun..." -ForegroundColor Green
Write-Host ""