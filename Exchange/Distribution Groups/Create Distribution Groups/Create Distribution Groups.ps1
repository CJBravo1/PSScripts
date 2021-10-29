#Author: Chris Jorenby
#Usage: Create Office 365 Distribution Group
clear

#Get Credentials
$msolcred = Get-Credential -Message "Enter Office 365 Admin Password"

#Identify Modules
$CloudExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell-liveid/ -Credential $msolcred -Authentication Basic -AllowRedirection

#Import CSV
$distroGroupList = Import-Csv .\DistributionGroups.csv

#Import Necessary Modules
Write-Host "Importing Modules" -ForegroundColor Magenta

Write-Host "Office 365 Exchange" -ForegroundColor Yellow
Import-PSSession $CloudExchangeSession -DisableNameChecking -WarningAction SilentlyContinue -AllowClobber | out-null


#Create New Distribution Groups
Write-Host "Creating New Distribution Groups" -ForegroundColor Magenta
foreach ($group in $distroGroupList) 
    {
    #Write-Host "Creating $group" -ForegroundColor Yellow
    New-DistributionGroup -Name $group.DistroName -DisplayName $group.DistroDisplayName -PrimarySmtpAddress $group.DistroEmail -Alias $group.DistroAlias
    }

#Add Members To New Distribution Groups
Write-Host "Adding Members to New Distribution Groups" -ForegroundColor Magenta
foreach ($groupMember in $ArrayTable)
    {
    Add-DistributionGroupMember -Identity $GroupMember.DistributionGroup -Member $GroupMember.UserName
    }