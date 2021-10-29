#Mailbox Recon Script
#Written by Chris Jorenby

#Change Window Title
$host.ui.RawUI.WindowTitle = "Mailbox Recon"
#Clear-Host
Write-Host "Mailbox Recon" -ForegroundColor Green
Write-Host "Use this script to gather all Exchange resources"

$PSSession = Get-PSSession | Where-Object {$_.configurationName -like "*exchange"}

if ($null -eq $PSSession)
{
    $ExchServer = Read-Host "Enter Exchange Server"
    $ExchSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$ExchServer/powershell"
    Import-PSSession $ExchSession
}

#Write-Host "Clearing ALL current csv files in this directory" -ForegroundColor Yellow -BackgroundColor Red
Write-Host "Removing Previous Recon Directories" -ForegroundColor Red
Remove-Item .\ReconGroups -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\ReconMailboxes -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\PublicFolders -Recurse -Force -ErrorAction SilentlyContinue

#Get Mailboxes
Write-Host "Gathering Mailboxes" -ForegroundColor Cyan
$mailboxes = get-Mailbox -ResultSize Unlimited

#Separate Mailboxes
Write-Host "Separating Mailboxes" -ForegroundColor Yellow
New-Item -Path .\ -Name ReconMailboxes -ItemType Directory > $null
$UserMailboxes = $mailboxes | Where-Object {$_.RecipientTypeDetails -eq "UserMailbox"}
$SharedMailboxes = $mailboxes | Where-Object {$_.RecipientTypeDetails -eq "SharedMailbox"}
$RoomMailboxes = $mailboxes | Where-Object {$_.RecipientTypeDetails -eq "RoomMailbox"}
$EquipmentMailboxes = $mailboxes | Where-Object {$_.RecipientTypeDetails -eq "EquipmentMailbox"}

$UserMailboxes | Select-Object name,alias,samaccountname,primarysmtpaddress,userprincipalname,RecipientTypeDetails,ServerName,Database,GrantSendOnBehalfTo,EmailAddresses,ForwardingAddress,ForwardingSMTPAddress | Export-Csv .\ReconMailboxes\UserMailboxes.csv -NoTypeInformation
$SharedMailboxes | Select-Object name,alias,samaccountname,primarysmtpaddress,userprincipalname,RecipientTypeDetails,ServerName,Database,GrantSendOnBehalfTo,EmailAddresses,ForwardingAddress,ForwardingSMTPAddress | Export-Csv .\ReconMailboxes\SharedMailboxes.csv -NoTypeInformation
$RoomMailboxes | Select-Object name,alias,samaccountname,primarysmtpaddress,userprincipalname,RecipientTypeDetails,ServerName,Database,GrantSendOnBehalfTo,EmailAddresses,ForwardingAddress,ForwardingSMTPAddress | Export-Csv .\ReconMailboxes\RoomMailboxes.csv -NoTypeInformation
$EquipmentMailboxes | Select-Object name,alias,samaccountname,primarysmtpaddress,userprincipalname,RecipientTypeDetails,ServerName,Database,GrantSendOnBehalfTo,EmailAddresses,ForwardingAddress,ForwardingSMTPAddress | Export-Csv .\ReconMailboxes\EquipmentMailboxes.csv -NoTypeInformation

#Gather Shared Mailbox Members
Write-host "Gathering Shared Mailbox and their members" -foregroundcolor Cyan
$SharedMailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {$_.RecipientTypeDetails -eq "RoomMailbox" -or $_.RecipientTypeDetails -eq "SharedMailbox"}

#Create Table
$csvLine = New-Object PSObject
$csvTable = @()
$SharedMailboxes | ForEach-Object {
    $mailbox = Get-Mailbox -Identity $_.Alias
    $Members = Get-MailboxPermission -Identity $mailbox.Alias | Where-Object {$_.User -like "*@*.com" -or $_.User -like "*\*" -and $_.User -notlike "NT AUTHORITY\*"}
    #$Members = $Members | Where-Object {$_.User -like "*@*.com" -or $_.User -like "*\*" -and $_.User -notlike "NT AUTHORITY\*"}
    
    #Separate each User in the mailbox and add to the table
    foreach ($user in $Members) {
        $csvLine | Add-Member -NotePropertyName "MailboxName" -NotePropertyValue $mailbox.Alias
        $csvLine | Add-Member -NotePropertyName "Member" -NotePropertyValue $User.User
        $csvLine | Add-Member -NotePropertyName "AccessRights" -NotePropertyValue $user.AccessRights
        $csvTable += @($csvLine)
        $csvLine = New-Object PSObject
        }
}
    #Export the Table to a CSV file    
    $csvTable | Export-Csv -NoTypeInformation .\ReconMailboxes\SharedMailboxMembers.csv 
    

#Get Distribution Groups
Write-Host "Gathering Distribution Groups" -ForegroundColor Cyan
New-Item -Path .\ -Name ReconGroups -ItemType Directory > $null
New-Item -Path .\ReconGroups -Name ReconGroupMembers -ItemType Directory > $null
$distroGroups = Get-DistributionGroup -ResultSize unlimited
$distroGroups | Select-Object name,displayname,alias,primarysmtpaddress | Export-Csv -NoTypeInformation .\ReconGroups\DistributionGroups.csv
Write-Host "Processing Group Memberships" -ForegroundColor Yellow
foreach ($group in $distroGroups)
{
    $groupName = $group.Name
    #Write-Host "Processing $groupName" -ForegroundColor Cyan
    $groupMembers = Get-DistributionGroupMember -Identity "$group"
    $groupMembers | Export-Csv -NoTypeInformation ".\ReconGroups\ReconGroupMembers\$groupName.csv"
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
    Get-Recipient -RecipientPreviewFilter $group.RecipientFilter -OrganizationalUnit $group.RecipientContainer | Select-Object Name,DisplayName,Alias,Identity,Company,Office,PrimarySMTPAddress,UserPrincipalName,AcceptMessagesOnlyFromSendersOrMembers  | Export-Csv -NoTypeInformation .\ReconGroups\DynamicDistributionGroupMembers\"$groupAlias.csv"
    }

#Gather Public Folders
Write-Host "Gathering Public Folders" -ForegroundColor Magenta
$publicFolders = get-PublicFolder -Recurse
if ($null -eq $publicFolders)
{
    Write-Host "No Public Folders Were Found!" -ForegroundColor Red
}

else 
{
    mkdir .\PublicFolders
    $publicFolders | Export-Csv -NoTypeInformation.PublicFolders\PublicFolders.csv
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Contact"} | Export-Csv -NoTypeInformation .\PublicFolders\ContactFolders.csv
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Note"} | Export-Csv -NoTypeInformation .\PublicFolders\NoteFolders.csv
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Appointment"} | Export-Csv -NoTypeInformation .\PublicFolders\CalendarFolders.csv
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Journal"} | Export-Csv -NoTypeInformation .\PublicFolders\JournalFolders.csv
    $publicFolders | Where-Object {$_.folderType -eq "IPF.StickyNote"} | Export-Csv -NoTypeInformation .\PublicFolders\StikcyNotes.csv
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Task"} | Export-Csv -NoTypeInformation .\PublicFolders\TasksFolder.csv
}
Write-Host "End of Recon" -ForegroundColor Green -BackgroundColor Blue

