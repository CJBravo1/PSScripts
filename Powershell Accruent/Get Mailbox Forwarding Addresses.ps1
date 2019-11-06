#Connect to Exchange and Active Directory
$msolcred = Get-Credential -Message "Enter Office 365 Admin Password"
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $msolcred -Authentication Basic -AllowRedirection
#Connect-MsolService -Credential $msolcred -WarningAction SilentlyContinue
Import-PSSession $ExchangeSession -DisableNameChecking -WarningAction SilentlyContinue | out-null
Import-Module ActiveDirectory


#Gather Mailboxes
#Write-host "Gathering Mailboxes" -ForegroundColor Green
#$mailboxes = Get-Mailbox  | select name,primarysmtpaddress,forwardingaddress 

#Gather Forwarding Addresses
#Write-Host "Gathering Forwarding Addresses" -ForegroundColor Green
#$forwardingAddresses = $mailboxes | foreach {Get-MailContact -Identity $_.ForwardingAddress}
#$forwardingAddresses = $forwardingAddresses | select Alias,ExternalEmailAddress

#Gather Active Directory Users and Properties
Write-Host "Gathering Email Addresses, Proxy Addresses, and Forwarding Addresses" -ForegroundColor Green
Write-Host "This will take some time. Please be patient" -ForegroundColor Green
$adUserAccts = Get-ADUser -Filter * -Properties * -SearchBase "OU=People,dc=verisae,dc=int" | where {$_.EmailAddress -ne $null} | select name,EmailAddress,samaccountname,@{"name"="proxyaddresses";"expression"={$_.Proxyaddresses}} | sort name
$counter = 1

$adUserAccts | foreach {
    Write-Host $_.Name -ForegroundColor Cyan
    $Mailbox = Get-Mailbox $_.EmailAddress -ErrorAction SilentlyContinue
    $MailboxForwardingAddress = Get-MailContact -Identity $Mailbox.ForwardingAddresses -ErrorAction SilentlyContinue
    #$MailboxForwardingAddress = $MailboxForwardingAddress.Emailaddresses | Out-String
    #Create CSV File and Add Entries
    #Each Line Represents a row in the CSV Sheet
    $csvline = New-Object PSObject
    $csvline | Add-Member NoteProperty "Name" ($_.Name)
    $csvline | Add-Member NoteProperty "User Name" ($_.SamaccountName)
    $csvline | Add-Member NoteProperty "Verisae Email" ($_.EmailAddress)
    $csvline | Add-Member NoteProperty "Exchange Forwarding Address" ($MailboxForwardingAddress.EmailAddress | Out-String)
    $csvline | Add-Member NoteProperty "Proxy Addresses" ($_.ProxyAddresses)
    
    
    
    #Add Entries to CSV Variable
    $csvSheet += @($csvline)
    }

$csvSheet | ft
$csvSheet | Export-Csv -NoTypeInformation C:\Temp\ProxyAddresses.csv
Invoke-Item C:\Temp\ProxyAddresses.csv