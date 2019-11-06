#Change Window Title
$host.ui.RawUI.WindowTitle = "Fairview.org"

R:
Write-Host "Enter your Fairview Credentials" -ForegroundColor Yellow
#Write-Host "This will connect you to the exchange environment" -ForegroundColor Yellow
#Start-Sleep 3
#Get Local User Name
$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()

$creds = Get-Credential $windowsIdentity.Name

#Connect to Modules
$Exchange = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://EXCH-PRIMARY-1.Fairview.org/powershell -Name Microsoft.Exchange
$exchUtil = New-PSSession exch-utility-vm
$lync = New-PSSession -ConnectionUri https://lyncfe1.fairview.org/ocspowershell -Name Microsoft.Lync -Credential $creds

#Import PS Sessions
Write-Host "Connecting to Exchange" -ForegroundColor Green
Import-PSSession $Exchange
Write-Host "Connecting to Lync" -ForegroundColor Green
Import-PSSession $lync -WarningAction SilentlyContinue
Write-Host "Connecting to Active Directory" -ForegroundColor Green
#Import-Module ActiveDirectory -PSSession $exchUtil

Clear-Host

echo "Windows PowerShell"
echo "Copyright (C) 2009 Microsoft Corporation. All rights reserved."
echo ""
Write-Host "Welcome to Fairview.org" -ForegroundColor Green
Write-Host "Have a lot of fun!!!" -ForegroundColor cyan
