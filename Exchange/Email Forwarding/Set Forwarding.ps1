#Import CSV File
$userlist = Import-Csv .\Users.csv

#Connect to Exchange Online
Try {Connect-ExchangeOnlineShell}
catch {Write-Host "Exchange Shell Module is not Installed or Loaded"}

#Start Loop
foreach ($user in $userlist)
    {
        $Mailbox = Get-Mailbox -Identity $user.PrimarySmtpAddress
        $Contact = Get-MailContact -Identity $user.NewPrimarySmtpAddress
        Set-Mailbox -Identity $Mailbox -ForwardingAddress $Contact -verbose -whatif
    }