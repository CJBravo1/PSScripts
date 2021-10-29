$PSSession = Get-PSSession | Where-Object {$_.configurationName -like "*exchange"}

if ($null -eq $PSSession)
{
    Connect-ExchangeOnlineShell
    $SharedMailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {$_.RecipientTypeDetails -eq "SharedMailbox"}
    $SharedMailboxes | ForEach-Object {
        $mailbox = Get-mailbox -Identity $_.Alias -ResultSize Unlimited
        $members = get-Mailboxpermission -Identity $mailbox.Alias | Where-Object {$_.User -like "*@*.com" -or $_.User -like "*\*" -and $_.User -notlike "NT AUTHORITY\*"}
        Write-Host "Gathering $mailbox Members" -ForegroundColor Cyan 
        Write-Host "Showing "$members.count "Users" -ForegroundColor Yellow
        $members | Select-Object Identity,User,AccessRights | export-csv  -NoTypeInformation .\SharedMailboxMemberExport.csv -Append
        }
}

else {
   Write-Error "No Session Was established. Please Run Connect-ExchangeOnlineShell"
    }