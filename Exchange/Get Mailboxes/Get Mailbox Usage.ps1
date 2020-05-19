Write-Host "Use this script to get email messages sent to distribution groups over the past 30 Days." -ForegroundColor Green

#Make new session
Write-Host "Connecting to Office 365" -ForegroundColor Yellow
$Session = Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange"}

if ($null -eq $session)
{
    Connect-ExchangeOnline
}


#Check and Remove Output files
$outputCSV = Test-Path .\output.csv
$uniqueAddressesCSV = Test-Path .\UniqueAddresses.csv

if ($outputCSV -eq $true) {Remove-Item .\output.csv}
if ($uniqueAddressesCSV -eq $true) {Remove-Item .\UniqueAddresses.csv}

#Get End Date and Start Date
$dateEnd = get-date
$dateStart = $dateEnd.AddDays(-30)

#Get Groups and Message trace
$Mailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox
$Mailboxes | ForEach-Object {
    Write-Host $_.DisplayName -ForegroundColor Cyan 
    Get-MessageTrace -RecipientAddress $_.primarysmtpaddress -startDate $dateStart -EndDate $dateEnd | Export-Csv -NoTypeInformation .\output.csv}


#Show Unique addresses
$data = Import-Csv .\output.csv
$data = $data | Select-Object recipientaddress -Unique 
$data | Export-Csv .\UniqueAddresses.csv

#Launch Excel
Invoke-Command .\output.csv
Invoke-Command .\UniqueAddresses.csv