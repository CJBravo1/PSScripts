# ReadOnlyEveryone.ps1
# Created by Regan Vecera
# 6.28.17

#The purpose of this script is to change the default access to all the 
#conference room calendars to Read Only (Reviewer) so all users will
#be able to see who the organizer of a meeting is and work with
#them to reschedule the meeting

#Clear screen and set variables
cls
$mailboxes = Import-Csv "RoomListLX.csv"
$accessLevel = "Reviewer"

#Connect to O365
Do
{
	$error.clear()
	$UserCredential = Get-Credential
	$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
	If ($error.count -gt 0) 
	{ 
		Clear-Host
		$failed = Read-Host "Login Failed! Retry? [y/n]"
		if ($failed  -eq 'n'){exit}
	}
} While ($error.count -gt 0)
Import-PSSession $Session -AllowClobber

#Run through CSV of all conference rooms
foreach ($row in $mailboxes)
{
	$targetMailbox = $row.room
	Write-Host "Updating calendar permission for $targetMailbox..." -ForegroundColor Magenta
	Set-MailboxFolderPermission -Identity $targetMailbox":\calendar" -user "Default" -AccessRights $accessLevel
}
