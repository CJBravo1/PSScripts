#Change Window Title
$host.ui.RawUI.WindowTitle = "Get Mailboxes"
Write-Host "This Script will gather all mailboxes and separate them into different csv files" -ForegroundColor Yellow
Write-Host "I need your Office 365 Credentials" -ForegroundColor Yellow

#Get Login Credentials
$UserCredential = Get-Credential -Message "Enter your Office 365 Credentials"

#Make new session
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

#Connect to PsSession
Import-PSSession $Session -WarningAction SilentlyContinue
Connect-MsolService -Credential $UserCredential

#Get Mailboxes
Write-Host "Gathering Mailboxes" -ForegroundColor Green
$mailboxes = get-Mailbox -ResultSize Unlimited

#Separate Mailboxes
Write-Host "Separating Mailboxes" -ForegroundColor Green
$UserMailboxes = $mailboxes | where {$_.RecipientTypeDetails -eq "UserMailbox"}
$SharedMailboxes = $mailboxes | where {$_.RecipientTypeDetails -eq "SharedMailbox"}
$RoomMailboxes = $mailboxes | where {$_.RecipientTypeDetails -eq "RoomMailbox"}

$UserMailboxes | select name,alias,primarysmtpaddress,RecipientTypeDetails,ForwardingAddress,ForwardingSMTPAddress | Export-Csv .\UserMailboxes.csv -NoTypeInformation
$SharedMailboxes | select name,alias,primarysmtpaddress,RecipientTypeDetails,ForwardingAddress,ForwardingSMTPAddress | Export-Csv .\SharedMailboxes.csv -NoTypeInformation
$RoomMailboxes | select name,alias,primarysmtpaddress,RecipientTypeDetails,ForwardingAddress,ForwardingSMTPAddress | Export-Csv .\RoomMailboxes.csv -NoTypeInformation