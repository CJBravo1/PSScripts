$Mailboxes = Get-Mailbox
$onMicrosoft = "company.mail.onmicrosoft.com"
foreach ($Mailbox in $Mailboxes)
{
    $ADUser = Get-ADUser -Identity $mailbox.DistinguishedName
    $mailboxSAM = $Mailbox.SamaccountName
    $Proxy = $mailboxSAM+"@"+$onMicrosoft
    Set-ADUser -Identity $ADUser.DistinguishedName -Add @{proxyaddresses="smtp:$Proxy"}
}