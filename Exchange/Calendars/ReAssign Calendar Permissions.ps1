$calendarMailboxCSV = Import-Csv R:\Temp\calendars.csv
foreach ($MailboxName in $calendarMailboxCSV)
    {
    $mailbox = Get-Mailbox -Identity $mailboxName.NewMailbox
    $calendar = $MailboxName.Calendar
    $permissions = Get-MailboxFolderPermission $mailbox":\$Calendar"
    
    
    $permissions | foreach {
        Add-MailboxFolderPermission -Identity $mailbox":\Calendar" -AccessRights $_.AccessRights -User $_.User
        }
    }