#Author: Chris Jorenby
#Usage: Convert OnPremesis Distribution Group to Office 365 Distribution Group
#Theme: Colors based on the Minnesota Vikings!

clear

Write-Host "Remove Local Distribution Group to replace with Office 365 Distribution Group" -ForegroundColor Cyan

#Get Credentials
$msolcred = Get-Credential -Message "Enter Office 365 Admin Password"
$exchangeServer = server.domain.local

#Identify Modules
$CompanyNameExchange = New-PSSession -ConfigurationName microsoft.exchange -ConnectionUri $exchangeServer  -AllowRedirection
$CloudExchangeSession = Connect-ExchangeOnline -Credential $msolcred

#Identify Variables
$distroGroupList = Import-Csv .\DistributionGroups.csv


#Import Necessary Modules
Write-Host "Importing Modules" -ForegroundColor Magenta

Write-Host "Active Directory" -ForegroundColor Yellow
Import-Module ActiveDirectory

Write-Host "Microsoft Exchange" -ForegroundColor Yellow
Import-PSSession $CompanyNameExchange -DisableNameChecking -WarningAction SilentlyContinue -AllowClobber | out-null
Write-Host "Office 365 Exchange" -ForegroundColor Yellow
Import-PSSession $CloudExchangeSession -DisableNameChecking -WarningAction SilentlyContinue -AllowClobber | out-null

#Create Array to be used for Members and Distribution Groups
$ArrayTable = @()


#Get Distribution Group from Local Active Directory
foreach ($localgroup in $distroGroupList) 
    {
    #Declare Variables
    $localgroupDistroName = $localgroup.DistroName
    $localgroupEmail = $localgroup.DistroEmail
    
    #Get Distribution Group and Members
    $localdistroGroup = Invoke-Command -Session $CompanyNameExchange -ScriptBlock {Get-DistributionGroup -Identity $args[0]} -ArgumentList $localgroupDistroName
    $localdistroGroupMembers = Invoke-Command -Session $CompanyNameExchange -ScriptBlock {Get-DistributionGroupMember -Identity $args[0]} -ArgumentList $localgroupDistroName
            
     #For each member in the distribution group, add them to a the array
     foreach ($member in $localdistroGroupMembers)  
        {
        $Arrayline = New-Object PSObject
        $Arrayline | Add-Member -NotePropertyName "DistributionGroup" -NotePropertyValue  ("$localDistroGroup")
        $Arrayline | Add-Member -NotePropertyName "Member" -NotePropertyValue  ("$member")
        $Arrayline | Add-Member -NotePropertyName "Username" -NotePropertyValue  ($member.SamAccountName)
        $ArrayTable += @($arrayLine)
        Clear-Variable arrayline
        }
        


    #Remove Local Distribution Groups
    Write-Host "Removing $localgroupDistroName from Local Exchange Server" -ForegroundColor Magenta
    Invoke-Command -Session $CompanyNameExchange -ScriptBlock {Remove-DistributionGroup -Identity $args[0] -Confirm:$false} -ArgumentList $localgroupDistroName 
    }


#Show Table
$ArrayTable
#Sync All Domain Controllers
Write-Host "Syncing CompanyName.com Domain Controllers" -ForegroundColor Yellow
Write-Host "No output will be displayed" -ForegroundColor Yellow
Write-Host "And this will take some time..." -ForegroundColor Yellow
Write-Host "I think there's Coffee in the break room..." -ForegroundColor White
$DC = $env:LOGONSERVER -replace ‘\\’,""

#Replication Command
repadmin /syncall $DC /APed | Out-Null

write-host "Sync Complete" -ForegroundColor Yellow
Write-Host "Confirm the distribution group has been removed from Office 365 and the local exchange server before continuing" -ForegroundColor Yellow -BackgroundColor Magenta
pause

#Sync Local AD with Office 365
Write-Host "Syncing With Office 365 via boscorpaadc.CompanyName.com" -ForegroundColor Magenta
Write-Host "Please enter your DA Credentials to Access the Necessary Server" -ForegroundColor Yellow
Invoke-Command -ComputerName boscorpaadc.CompanyName.com -ScriptBlock {Start-AdsyncSyncCycle -PolicyType Delta} -Credential CompanyName\da_

Start-Sleep -Seconds 120

#Re-Create Distribution group in Office 365
#Create New Distribution Groups
Write-Host "Creating New Distribution Groups" -ForegroundColor Magenta
foreach ($group in $distroGroupList) 
    {
    #Write-Host "Re-Creating $group" -ForegroundColor Yellow
    New-DistributionGroup -Name $group.DistroName -DisplayName $group.DistroDisplayName -PrimarySmtpAddress $group.DistroEmail -Alias $group.DistroAlias
    }

#Add Members To New Distribution Groups
Write-Host "Adding Members to New Distribution Groups" -ForegroundColor Magenta
foreach ($groupMember in $ArrayTable)
    {
    #$GroupName = $groupMember | select DistributionGroup
    #$Member =  $groupMember| select Member
    #Write-Host "Adding $GroupMember to $GroupMember.DistributionGroup" -ForegroundColor Yellow
    Add-DistributionGroupMember -Identity $GroupMember.DistributionGroup -Member $GroupMember.UserName
    }
    
