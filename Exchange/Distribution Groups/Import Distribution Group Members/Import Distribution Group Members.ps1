#Author: Chris Jorenby
#Usage: Create Office 365 Distribution Group
clear

#Get Credentials
$msolcred = Get-Credential -Message "Enter Office 365 Admin Password"

#Import Necessary Modules
Write-Host "Importing Modules" -ForegroundColor Magenta
#Identify Modules
$CloudExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell-liveid/ -Credential $msolcred -Authentication Basic -AllowRedirection

Write-Host "Office 365 Exchange" -ForegroundColor Yellow
Import-PSSession $CloudExchangeSession -DisableNameChecking -WarningAction SilentlyContinue -AllowClobber | out-null

#Import CSV
$csv = Import-Csv .\DistributionGroupMembers.CSV

foreach ($member in $csv)
    {
    $GroupEmail = $member."Distribution Group Email"
    $memberEmail = $member."Member Email"
    Add-DistributionGroupMember -Identity $GroupEmail -Member $memberEmail
    }