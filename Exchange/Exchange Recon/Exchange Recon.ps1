﻿#Mailbox Recon Script
#Written by Chris Jorenby

#Change Window Title
#$host.ui.RawUI.WindowTitle = "Mailbox Recon"
#Clear-Host
Write-Host "Exchange Online Recon" -ForegroundColor Green
Write-Host "Use this script to gather all Microsoft Exchange Online Resources" -ForegroundColor Yellow

#Check for Current Exchange PSSession
$PSSession = Get-AcceptedDomain

if ($null -eq $PSSession)
    {
    #Make new session
    Write-Host "Connect to Exchange Online" -ForegroundColor Yellow
    Connect-ExchangeOnline 
    }

#Get Exchange Domains
$domains = Get-AcceptedDomain
$PrimaryDomain = Get-AcceptedDomain | Where-Object {$_.Default -eq $true}
Write-Host "Primary Domain $PrimaryDomain" -ForegroundColor Yellow

#Create Export Directory
$ExportDirectory = New-Item ".\$primaryDomain" -Type Directory

#Export Primary Domains
Write-Host "Primary Domain: $PrimaryDomain" -ForegroundColor Yellow
Write-Host "Exporting Accepted Domains" -ForegroundColor Green
$domains | Export-Csv -NoTypeInformation "$ExportDirectory\AcceptedDomains.csv"

#Get Mailboxes
Write-Host "Gathering Mailboxes" -ForegroundColor Green
$Mailboxes = Get-EXOMailbox -ResultSize Unlimited

#Export All Mailboxes
New-Item -Path $ExportDirectory -Name ReconMailboxes -ItemType Directory 
foreach ($mailbox in $Mailboxes)
{
    $Mailboxstatistics = Get-MailboxStatistics -Identity $mailbox.Identity
    $Table = [PSCustomObject]@{
        DisplayName =$mailbox.DisplayName
        Name = $mailbox.Name
        Alias = $mailbox.Alias
        #samaccountname = $mailbox.samaccountname
        primarysmtpaddress = $mailbox.primarysmtpaddress
        userprincipalname = $mailbox.userprincipalname
        RecipientTypeDetails = $mailbox.RecipientTypeDetails
        GrantSendOnBehalfTo = $mailbox.GrantSendOnBehalfTo
        ForwardingAddress = $mailbox.ForwardingAddress
        ForwardingSMTPAddress = $mailbox.ForwardingSmtpAddress
        MailboxSize = $Mailboxstatistics.TotalItemSize.Value
        EmailAddresses = $mailbox.EmailAddresses
    }
    #Export to CSV files
    $Table | Export-Csv "$ExportDirectory\ReconMailboxes\AllMailboxes.csv" -NoTypeInformation -Append

    #Gather Mailbox Permissions
    $members = get-Mailboxpermission -Identity $mailbox.Alias | Where-Object {$_.User -like "*@*.com" -or $_.User -like "*\*" -and $_.User -notlike "NT AUTHORITY\*"}
    foreach ($member in $members)
    {
        $AccessRights = $members.AccessRights | Out-String
        $Table = [PSCustomObject]@{
            Identity = $member.Identity
            User = $member.User
            MailboxType = $mailbox.RecipientTypeDetails
            AccessRights = $AccessRights
            }
    $Table | Export-Csv -NoTypeInformation "$ExportDirectory\ReconMailboxes\MailboxPermissions.csv" -Append
    }
}

#Get Distribution Groups
Write-Host "Gathering Distribution Groups" -ForegroundColor Green
$ReconGroupExportDirectory = New-Item -Path $ExportDirectory -Name "ReconGroups" -Type Directory 
$ReconGroupMembersExportDirectory = New-Item -Path "$ReconGroupExportDirectory" -Name "ReconGroupMembers" -Type Directory 
$distroGroups = Get-DistributionGroup -ResultSize unlimited
$distroGroups | Select-Object name,displayname,alias,primarysmtpaddress,EmailAddresses | Export-Csv -NoTypeInformation "$ReconGroupExportDirectory\DistributionGroups.csv"
Write-Host "Gathering Group Membership" -ForegroundColor Green
foreach ($group in $distroGroups)
{
    $groupName = $group.Name
    $groupMembers = Get-DistributionGroupMember -Identity "$group"
    $groupMembers | Export-Csv -NoTypeInformation "$ReconGroupMembersExportDirectory\$groupName.csv"
}

#Get Dynamic Distribution Groups
$ReconDynamicGroupExportDirectory = New-Item -path $ReconGroupExportDirectory -Name DynamicDistributionGroupMembers -ItemType Directory
Write-Host "Gathering Dynamic Distribution Groups" -ForegroundColor Green
$ddGroup = Get-DynamicDistributionGroup -Resultsize Unlimited -ErrorAction SilentlyContinue

#Get Group Members and Export as separate CSV Files
foreach ($group in $ddGroup) 
    {
    $groupAlias = $group.Alias
    Write-Host "Processing $groupAlias" -ForegroundColor Yellow
    Get-Recipient -RecipientPreviewFilter $group.RecipientFilter -OrganizationalUnit $group.RecipientContainer | Select-Object Name,DisplayName,Alias,Identity,Company,Office,PrimarySMTPAddress,UserPrincipalName,AcceptMessagesOnlyFromSendersOrMembers  | Export-Csv -NoTypeInformation "$ReconDynamicGroupExportDirectory\$groupAlias.csv"
    }


#Gather Office 365 Groups
Write-Host "Gathering Office 365 Groups" -ForegroundColor Green
$unifiedGroups = Get-UnifiedGroup -Resultsize Unlimited

#Create Blank Table

$CSV = New-Object PSObject
$csvTable = @()

foreach ($group in $unifiedGroups)
    {
    #Get Group's Members
    $members = Get-UnifiedGroupLinks -LinkType Member -Identity $group.PrimarySmtpAddress
    #Process Each Member for each group"
    foreach ($member in $members)
        {
        $CSV | Add-Member -NotePropertyName 'GroupName' -NotePropertyValue $group.DisplayName -Force
        $CSV | Add-Member -NotePropertyName 'GroupEmail' -NotePropertyValue $group.PrimarySmtpAddress -Force
        $CSV | Add-Member -NotePropertyName 'MemberName' -NotePropertyValue $member.Name -Force
        $CSV | Add-Member -NotePropertyName 'MemberEmail' -NotePropertyValue $member.PrimarySmtpAddress -Force

        #Export Data to table
        $csvTable += @($CSV)
        $CSV = New-Object PSObject
        }
    }
#Export Table to CSV File
Write-Host "Exporting Data to Office365Groups.csv" -ForegroundColor Green
$csvTable | Export-Csv -NoTypeInformation "$ExportDirectory\ReconGroups\Office365Groups.csv"

#Gather Public Folders
Write-Host "Gathering Public Folders" -ForegroundColor Green
if ($null -eq $publicFolders)
{
    Write-Host "No Public Folders Were Found!" -ForegroundColor Red
}

else 
{
    mkdir .\PublicFolders
    $publicFolders | Export-Csv -NoTypeInformation.PublicFolders\PublicFolders.csv
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Contact"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\ContactFolders.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Note"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\NoteFolders.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Appointment"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\CalendarFolders.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Journal"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\JournalFolders.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.StickyNote"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\StikcyNotes.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Task"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\TasksFolder.csv"
}

# Get the list of send and receive connectors
Write-Host "Gathering Inbound Connectors" -ForegroundColor Green
$InboundConnectors = Get-InboundConnector
foreach ($Connector in $InboundConnectors)
{
    $Results = [PSCustomObject]@{
        Identity = $Connector.Identity
        Name = $Connector.Name
        Enabled = $Connector.Enabled
        ConnectorType = $Connector.ConnectorType
        AssociatedAcceptedDomains = $Connector.AssociatedAcceptedDomains
        RequireTls = $Connector.RequireTls
        TlsSenderCertificateName = $connector.TlsSenderCertificateName
        RestrictDomainsToIPAddresses = $Connector.RestrictDomainsToIPAddresses
        RestrictDomainsToCertificate = $connector.RestrictDomainsToCertificate
        SenderDomains = $Connector.SenderDomains -join '; '
        SenderIPAddresses = $Connector.SenderIPAddresses -join ', '
    }
    $Results | Export-Csv -NoTypeInformation "$ExportDirectory\InboundConnectors.csv" -Append
}

$OutboundConnectors = Get-OutboundConnector
Write-Host "Gathering Outbound Connectors" -ForegroundColor Green
foreach ($Connector in $OutboundConnectors)
{
    $Results = [PSCustomObject]@{
        Identity = $Connector.Identity
        Name = $Connector.Name
        Enabled = $Connector.Enabled
        ConnectorType = $Connector.ConnectorType
        SmartHosts = $Connector.SmartHosts
        TlsDomain = $Connector.TlsDomain
        TlsSettings = $Connector.TlsSettings
        AllAcceptedDomains = $Connector.AllAcceptedDomains

    }
    $Results | Export-Csv -NoTypeInformation "$ExportDirectory\OutboundConnectors.csv" -Append
}
Write-Host "End of Recon" -ForegroundColor Green
Write-Host "Export Directory is "$ExportDirectory.FullName -ForegroundColor Yellow