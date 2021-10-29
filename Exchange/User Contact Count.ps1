$ExchangeSession = Get-PSSession | where {$_.ComputerName -eq "outlook.office365.com"}
$csvTable = @()

if ($ExchangeSession) {
$mailboxes = Get-Mailbox -RecipientTypeDetails UserMailbox
foreach ($mailbox in $mailboxes){
    Write-Host $mailbox.DisplayName -ForegroundColor Cyan
    $DisplayName = $mailbox.DisplayName
    $UPN = $mailbox.UserPrincipalName
    $ContactFolderCount = Get-MailboxFolderStatistics $mailbox.UserPrincipalName | where {$_.Identity -like "*\Contacts"}
    
    $csvline = New-Object PSObject
    $csvline | Add-Member -NotePropertyName 'MailboxDisplayName' -NotePropertyValue ($DisplayName)
    $csvline | Add-Member -NotePropertyName 'MailboxUserPrincipalName' -NotePropertyValue ($UPN)
    $csvline | Add-Member -NotePropertyName 'MailboxContacts' -NotePropertyValue ($ContactFolderCount.ItemsInFolder)
    $csvtable += @($csvline)
    $csvline = New-Object PSObject 
    }
$csvTable
$csvTable | Export-Csv -NoTypeInformation ~\Desktop\MailContactCount.csv
}