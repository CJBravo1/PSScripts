Write-Host "I need Your Office 365 Credentials" -ForegroundColor Green
$ExchangeSession = Connect-ExchangeOnlineShell

if ($ExchangeSession -ne $null) {
    $SharedMailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {$_.RecipientTypeDetails -eq "RoomMailbox" -or $_.RecipientTypeDetails -eq "SharedMailbox"}
    $SharedMailboxes | ForEach-Object {
        $mailbox = Get-mailbox -Identity $_.Alias -ResultSize Unlimited
        $members = get-Mailboxpermission -Identity $mailbox.Alias | Where-Object {$_.User -like "*@*"}
        Write-Host "Gathering $mailbox Members" -ForegroundColor Cyan 
        Write-Host "Showing "$members.count "Users" -ForegroundColor Yellow
        $members | Select-Object Identity,User,AccessRights | export-csv  -NoTypeInformation .\Export.csv -Append
        }
}

else {
    Write-Error "No Session Was established. Please Run Connect-ExchangeOnlineShell"
}