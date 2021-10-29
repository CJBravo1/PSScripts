$SharedMailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {$_.RecipientTypeDetails -eq "RoomMailbox" -or $_.RecipientTypeDetails -eq "SharedMailbox"}

$SharedMailboxes | ForEach-Object {
    $mailbox = Get-mailbox -Identity $_.Alias -ResultSize Unlimited
    $members = get-Mailboxpermission -Identity $mailbox.Alias | Where-Object {$_.User -like "*@*"}
    Write-Host "Gathering $mailbox Members" -ForegroundColor Cyan 
    Write-Host "Showing "$members.count "Users" -ForegroundColor Yellow
    $members | Select-Object Identity,User,AccessRights | export-csv  -NoTypeInformation .\Export.csv -Append
}