#Mailbox Recon Script
#Written by Chris Jorenby

#Change Window Title
#$host.ui.RawUI.WindowTitle = "Mailbox Recon"
#Clear-Host
Write-Host "Mailbox Recon" -ForegroundColor Green
Write-Host "Use this script to gather all Microsoft Exchange Online Resources"

$PSSession = Get-PSSession | Where-Object {$_.ComputerName -eq "outlook.office365.com"}

if ($null -eq $PSSession)
    {
    #Make new session
    Write-Host "Connect to Exchange Online" -ForegroundColor Yellow
    Connect-ExchangeOnlineShell
    Write-Host "Connect to Microsoft Online" -ForegroundColor Yellow
    Connect-MsolService
    }

#Write-Host "Clearing ALL current csv files in this directory" -ForegroundColor Yellow -BackgroundColor Red
#Get Exchange Domains
$domains = Get-AcceptedDomain
$PrimaryDomain = $domains[0]

#Create Export Directory
$ExportDirectory = New-Item ".\$primaryDomain" -Type Directory
Write-Host "Removing Previous Recon Directories" -ForegroundColor Red
Remove-Item .\ReconGroups -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\ReconMailboxes -Recurse -Force -ErrorAction SilentlyContinue

#Get Mailboxes
Write-Host "Gathering Mailboxes" -ForegroundColor Cyan
$mailboxes = Get-EXOMailbox -ResultSize Unlimited

#Separate Mailboxes
Write-Host "Separating Mailboxes" -ForegroundColor Yellow
New-Item -Path $ExportDirectory -Name ReconMailboxes -ItemType Directory > $null
$UserMailboxes = $mailboxes | Where-Object {$_.RecipientTypeDetails -eq "UserMailbox"}
$SharedMailboxes = $mailboxes | Where-Object {$_.RecipientTypeDetails -eq "SharedMailbox"}
$RoomMailboxes = $mailboxes | Where-Object {$_.RecipientTypeDetails -eq "RoomMailbox"}
$EquipmentMailboxes = $mailboxes | Where-Object {$_.RecipientTypeDetails -eq "EquipmentMailbox"}

$UserMailboxes | Select-Object name,alias,samaccountname,primarysmtpaddress,userprincipalname,RecipientTypeDetails,Database,GrantSendOnBehalfTo,EmailAddresses,ForwardingAddress,ForwardingSMTPAddress | Export-Csv "$ExportDirectory\ReconMailboxes\UserMailboxes.csv" -NoTypeInformation
$SharedMailboxes | Select-Object name,alias,samaccountname,primarysmtpaddress,userprincipalname,RecipientTypeDetails,Database,GrantSendOnBehalfTo,EmailAddresses,ForwardingAddress,ForwardingSMTPAddress | Export-Csv "$ExportDirectory\ReconMailboxes\SharedMailboxes.csv" -NoTypeInformation
$RoomMailboxes | Select-Object name,alias,samaccountname,primarysmtpaddress,userprincipalname,RecipientTypeDetails,Database,GrantSendOnBehalfTo,EmailAddresses,ForwardingAddress,ForwardingSMTPAddress | Export-Csv "$ExportDirectory\ReconMailboxes\RoomMailboxes.csv" -NoTypeInformation
$EquipmentMailboxes | Select-Object name,alias,samaccountname,primarysmtpaddress,userprincipalname,RecipientTypeDetails,Database,GrantSendOnBehalfTo,EmailAddresses,ForwardingAddress,ForwardingSMTPAddress | Export-Csv "$ExportDirectory\ReconMailboxes\EquipmentMailboxes.csv" -NoTypeInformation

#Gather Shared Mailbox Members
Write-host "Gathering Shared Mailbox and their members" -foregroundcolor Cyan
$SharedMailboxes = Get-EXOMailbox -ResultSize Unlimited | Where-Object {$_.RecipientTypeDetails -eq "RoomMailbox" -or $_.RecipientTypeDetails -eq "SharedMailbox"}

#Gather Shared Mailbox Members
$csvLine = New-Object PSObject
$csvTable = @()
$SharedMailboxes | ForEach-Object {
    $mailbox = Get-EXOMailbox -Identity $_.Alias -ResultSize Unlimited
    $Members = Get-EXOMailboxPermission -Identity $mailbox.Alias
    $Members = $Members | Where-Object {$_.User -like "*@*.com"}
    
    #Separate each User in the mailbox and add to the table
    foreach ($user in $Members) {
        $csvLine | Add-Member -NotePropertyName "MailboxName" -NotePropertyValue $mailbox.Alias
        $csvLine | Add-Member -NotePropertyName "Member" -NotePropertyValue $User.User
        $csvLine | Add-Member -NotePropertyName "AccessRights" -NotePropertyValue $user.AccessRights
        $csvTable += @($csvLine)
        $csvLine = New-Object PSObject
        }
    
    #Export the Table to a CSV file    
    $csvTable | Export-Csv -NoTypeInformation "$ExportDirectory\ReconMailboxes\SharedMailboxMembers.csv" -Append
    }

#Get Distribution Groups
Write-Host "Gathering Distribution Groups"
$ReconGroupExportDirectory = New-Item -Path $ExportDirectory -Name "ReconGroups" -Type Directory 
$ReconGroupMembersExportDirectory = New-Item -Path "$ReconGroupExportDirectory" -Name "ReconGroupMembers" -Type Directory 
$distroGroups = Get-DistributionGroup -ResultSize unlimited
$distroGroups | Select-Object name,displayname,alias,primarysmtpaddress | Export-Csv -NoTypeInformation "$ReconGroupExportDirectory\DistributionGroups.csv"
Write-Host "Processing Group Memberships" -ForegroundColor Yellow
foreach ($group in $distroGroups)
{
    $groupName = $group.Name
    #Write-Host "Processing $groupName" -ForegroundColor Cyan
    $groupMembers = Get-DistributionGroupMember -Identity "$group"
    $groupMembers | Export-Csv -NoTypeInformation "$ReconGroupMembersExportDirectory\$groupName.csv"
}

#Get Dynamic Distribution Groups
mkdir .\ReconGroups\DynamicDistributionGroupMembers > $null
Write-Host "Gathering Dynamic Distribution Groups" -ForegroundColor Cyan
$ddGroup = Get-DynamicDistributionGroup -Resultsize Unlimited

#Get Group Members and Export as separate CSV Files
foreach ($group in $ddGroup) 
    {
    $groupAlias = $group.Alias
    Write-Host "Processing $groupAlias" -ForegroundColor Yellow
    Get-Recipient -RecipientPreviewFilter $group.RecipientFilter -OrganizationalUnit $group.RecipientContainer | Select-Object Name,DisplayName,Alias,Identity,Company,Office,PrimarySMTPAddress,UserPrincipalName,AcceptMessagesOnlyFromSendersOrMembers  | Export-Csv -NoTypeInformation "$ExportDirectory\ReconGroups\DynamicDistributionGroupMembers\$groupAlias.csv"
    }


#Gather Office 365 Groups
Write-Host "Gathering Office 365 Groups" -ForegroundColor Cyan
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
Write-Host "Exporting Data to Office365Groups.csv" -ForegroundColor Cyan
$csvTable | Export-Csv -NoTypeInformation "$ExportDirectory\ReconGroups\Office365Groups.csv"

#Gather Public Folders
Write-Host "Gathering Public Folders" -ForegroundColor Magenta
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
Write-Host "End of Recon" -ForegroundColor Green -BackgroundColor Blue