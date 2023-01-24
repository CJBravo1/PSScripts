#Mailbox Recon Script
#Written by Chris Jorenby

#Change Window Title
#$host.ui.RawUI.WindowTitle = "Mailbox Recon"
#Clear-Host
Write-Host "Mailbox Recon" -ForegroundColor Green
Write-Host "Use this script to gather all Microsoft Exchange Online Resources" -ForegroundColor Yellow

#Check for $adminCreds
$CurrentUser = $env:USERNAME
if ($null -eq $adminCreds)
{
    $adminCreds =  Get-Credential -Message "Enter Microsoft 365 Credentials"
}

#Check for Current Exchange PSSession
$PSSession = Get-AcceptedDomain

if ($null -eq $PSSession)
    {
    #Make new session
    Write-Host "Connect to Exchange Online" -ForegroundColor Yellow
    Connect-ExchangeOnline -Credential $adminCreds
    Write-Host "Connect to Microsoft Online" -ForegroundColor Yellow
    Connect-MsolService -Credential $adminCreds
    }
#Get Exchange Domains
$domains = Get-AcceptedDomain
$PrimaryDomain = Get-AcceptedDomain | Where-Object {$_.Default -eq $true}

#Create Export Directory
$ExportDirectory = New-Item ".\$primaryDomain" -Type Directory

#Export Primary Domains
Write-Host "Primary Domain: $PrimaryDomain" -ForegroundColor Yellow
Write-Host "Exporting Accepted Domains" -ForegroundColor Green
$domains | Export-Csv -NoTypeInformation "$ExportDirectory\AcceptedDomains.csv"

#Write-Host "Removing Previous Recon Directories" -ForegroundColor Red
#Remove-Item .\ReconGroups -Recurse -Force -ErrorAction SilentlyContinue
#Remove-Item .\ReconMailboxes -Recurse -Force -ErrorAction SilentlyContinue

#Get Mailboxes
Write-Host "Gathering Mailboxes" -ForegroundColor Green
$mailboxes = Get-EXOMailbox -ResultSize Unlimited

#Separate Mailboxes
Write-Host "Separating Mailboxes" -ForegroundColor Yellow
New-Item -Path $ExportDirectory -Name ReconMailboxes -ItemType Directory 
$UserMailboxes = $mailboxes | Where-Object {$_.RecipientTypeDetails -eq "UserMailbox"}
$SharedMailboxes = $mailboxes | Where-Object {$_.RecipientTypeDetails -eq "SharedMailbox"}
$RoomMailboxes = $mailboxes | Where-Object {$_.RecipientTypeDetails -eq "RoomMailbox"}
$EquipmentMailboxes = $mailboxes | Where-Object {$_.RecipientTypeDetails -eq "EquipmentMailbox"}

#Export to CSV files
$UserMailboxes | Select-Object name,alias,samaccountname,primarysmtpaddress,userprincipalname,RecipientTypeDetails,Database,GrantSendOnBehalfTo,EmailAddresses,ForwardingAddress,ForwardingSMTPAddress | Export-Csv "$ExportDirectory\ReconMailboxes\UserMailboxes.csv" -NoTypeInformation
$SharedMailboxes | Select-Object name,alias,samaccountname,primarysmtpaddress,userprincipalname,RecipientTypeDetails,Database,GrantSendOnBehalfTo,EmailAddresses,ForwardingAddress,ForwardingSMTPAddress | Export-Csv "$ExportDirectory\ReconMailboxes\SharedMailboxes.csv" -NoTypeInformation
$RoomMailboxes | Select-Object name,alias,samaccountname,primarysmtpaddress,userprincipalname,RecipientTypeDetails,Database,GrantSendOnBehalfTo,EmailAddresses,ForwardingAddress,ForwardingSMTPAddress | Export-Csv "$ExportDirectory\ReconMailboxes\RoomMailboxes.csv" -NoTypeInformation
$EquipmentMailboxes | Select-Object name,alias,samaccountname,primarysmtpaddress,userprincipalname,RecipientTypeDetails,Database,GrantSendOnBehalfTo,EmailAddresses,ForwardingAddress,ForwardingSMTPAddress | Export-Csv "$ExportDirectory\ReconMailboxes\EquipmentMailboxes.csv" -NoTypeInformation

#Gather Shared Mailbox Members
Write-host "Gathering Shared Mailbox and Members" -foregroundcolor Green
$SharedMailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {$_.RecipientTypeDetails -eq "SharedMailbox"}
$SharedMailboxes | ForEach-Object {
    $mailbox = Get-mailbox -Identity $_.Alias -ResultSize Unlimited
    $members = get-Mailboxpermission -Identity $mailbox.Alias | Where-Object {$_.User -like "*@*.com" -or $_.User -like "*\*" -and $_.User -notlike "NT AUTHORITY\*"}
    #Write-Host "Gathering $mailbox Members" -ForegroundColor Green 
    #Write-Host "Showing "$members.count "Users" -ForegroundColor Yellow
    $members | Select-Object Identity,User,AccessRights | export-csv  -NoTypeInformation "$ExportDirectory\ReconMailboxes\SharedMailboxMembers.csv" -Append
    }


#Get Distribution Groups
Write-Host "Gathering Distribution Groups" -ForegroundColor Green
$ReconGroupExportDirectory = New-Item -Path $ExportDirectory -Name "ReconGroups" -Type Directory 
$ReconGroupMembersExportDirectory = New-Item -Path "$ReconGroupExportDirectory" -Name "ReconGroupMembers" -Type Directory 
$distroGroups = Get-DistributionGroup -ResultSize unlimited
$distroGroups | Select-Object name,displayname,alias,primarysmtpaddress | Export-Csv -NoTypeInformation "$ReconGroupExportDirectory\DistributionGroups.csv"
Write-Host "Gathering Group Membership" -ForegroundColor Green
foreach ($group in $distroGroups)
{
    $groupName = $group.Name
    #Write-Host "Processing $groupName" -ForegroundColor Green
    $groupMembers = Get-DistributionGroupMember -Identity "$group"
    $groupMembers | Export-Csv -NoTypeInformation "$ReconGroupMembersExportDirectory\$groupName.csv"
}

#Get Dynamic Distribution Groups
$ReconDynamicGroupExportDirectory = New-Item -path $ReconGroupExportDirectory -Name DynamicDistributionGroupMembers -ItemType Directory
Write-Host "Gathering Dynamic Distribution Groups" -ForegroundColor Green
$ddGroup = Get-DynamicDistributionGroup -Resultsize Unlimited

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
    #Write-Host "Processing $group" -ForegroundColor Yellow
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
Write-Host "End of Recon" -ForegroundColor Green
Write-Host "Export Directory is "$ExportDirectory.FullName -ForegroundColor Yellow
