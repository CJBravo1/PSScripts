Import-Module ActiveDirectory
Write-Host "Gathering Users" -ForegroundColor Green

Get-ADUser -Filter * -Properties * | select mail,mailnickname,proxyAddresses,msExchMailboxGuid,msExchArchiveGuid,legacyExchangeDN,msExchRecipientDisplayType,msExchRecipientTypeDetails | Export-Clixml C:\Temp\adusers.xml
Get-ADUser -Filter * -Properties * | select mail,mailnickname,proxyAddresses,msExchMailboxGuid,msExchArchiveGuid,legacyExchangeDN,msExchRecipientDisplayType,msExchRecipientTypeDetails | Export-Csv -NoTypeInformation C:\Temp\adusers.csv

Write-Host "Exports located in C:\temp" -ForegroundColor Green