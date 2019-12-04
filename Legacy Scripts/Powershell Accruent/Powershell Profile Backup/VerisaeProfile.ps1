#Change Window Title
$host.ui.RawUI.WindowTitle = "Verisae.int"

#Map Network Drives
#New-PSDrive -Name Z -PSProvider FileSystem -Root \\mspnas01\software
#New-PSDrive -Name Y -PSProvider FileSystem -Root \\mspwfs01\it
#New-PSDrive -Name X -PSProvider FileSystem -Root \\mspnas01\it
#New-PSDrive -Name V -PSProvider FileSystem -Root \\mspwfs01\verisaedocs

#Variables

#Active Directory
$Accruent = "OU=Accruent,DC=verisae,DC=int"
$DisabledUsers = "OU=Disabled Users,DC=verisae,DC=int"
$DisabledComputers = "OU=Disabled Computers,DC=verisae,DC=int"
$pass = ConvertTo-SecureString "Ver_Cruent16!" -AsPlainText -Force
$People = "OU=People,DC=verisae,DC=int"
$remoteComputers = "OU=Remote Computers,DC=verisae,DC=int"
$VHQComputers = "OU=VHQ Computers,DC=verisae,DC=int"
$VHQComputersW10 = "OU=VHQ Computers - Win10,DC=verisae,DC=int"
$VHQLab = "OU=VHQ Lab,DC=verisae,DC=int"
$domainInfo = Get-WMIObject Win32_NTDomain
$VPNVHQ = "VPN users (VHQ FW)"

#Exchange
#$msolcred = Get-Credential cjorenby@verisae.com -Message "Enter Office 365 Admin Password"
$mspvdc02 = New-PSSession -ComputerName mspvdc02.verisae.int

#PSSessions
$mspvdc06 = New-PSSession -ComputerName mspvdc06.verisae.int
#$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $msolcred -Authentication Basic -AllowRedirection
#$ComplianceSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $MSOLcred -Authentication Basic -AllowRedirection
#$protectionsession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.protection.outlook.com/powershell-liveid/ -Credential $msolcred -Authentication Basic -AllowRedirection

#Connect to Office 365 environment
#Write-Host "Connecting to Azure Active Directory" -ForegroundColor Magenta
#Connect-MsolService -Credential $msolcred -WarningAction SilentlyContinue

#Import PSSessions
#Write-Host "Connecting to Exchange" -ForegroundColor Cyan
#Import-PSSession $ExchangeSession -DisableNameChecking -WarningAction SilentlyContinue | out-null
#Import-PSSession $ComplianceSession -DisableNameChecking -WarningAction SilentlyContinue | out-null
#Import-PSSession $protectionsession -DisableNameChecking -WarningAction SilentlyContinue | out-null
Import-Module ADSync -PSSession $mspvdc02
Import-Module ActiveDirectory -PSSession $mspvdc06


Write-Host "Welcome to Verisae.int" -Foreground Red
Write-Host "Domain Controller:$($domainInfo.domaincontrollername)" -ForegroundColor Red
Write-Host "Have a lot of fun..." -Foreground Green

