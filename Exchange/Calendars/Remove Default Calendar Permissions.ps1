$mailboxList = cat C:\Temp\mailboxlist.txt
foreach ($Calendar in $mailboxlist) 
    {Write-Host $Calendar -ForegroundColor Cyan
    Set-MailboxFolderPermission -Identity $Calendar":\Calendar" -AccessRights None -User Default}
    