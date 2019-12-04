$mailboxes = Get-Mailbox
$mailboxes | foreach {
$mail = $_
$mailstat = Get-Mailbox -Identity $_.PrimarySmtpAddress | Get-MailboxStatistics

$name = $mail.Name
$email = $mail.PrimarySmtpAddress
$type = $mail.RecipientTypeDetails
$size = $mailstat.TotalItemSize

Write-Host $size
Write-Host $email


$csvline | Add-Member NoteProperty 'Display Name' ('$Name')
$csvline | Add-Member NoteProperty 'Email Address' ('$Email')
$csvline | Add-Member NoteProperty 'Type' ('$type')
$csvline | Add-Member NoteProperty 'Size' ('$Size')
}
$csvline