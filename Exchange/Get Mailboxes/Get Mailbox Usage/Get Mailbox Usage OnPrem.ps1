Write-Host "Use this script to get email messages sent to shared mailboxes over the past 30 Days." -ForegroundColor Green

#Make new session
$Session = Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange"}

if ($null -eq $session)
{
    Write-Host "No Exchange Session Established..." -foregroundcolor Red
}


#Check and Remove Output files
$outputCSV = Test-Path .\output.csv
$uniqueAddressesCSV = Test-Path .\UniqueAddresses.csv

if ($outputCSV -eq $true) {rm .\output.csv}
if ($uniqueAddressesCSV -eq $true) {rm .\UniqueAddresses.csv}

#Get End Date and Start Date
$dateEnd = get-date
$dateStart = $dateEnd.AddDays(-30)

#Get Groups and Message trace
$Mailboxes = Get-Mailbox | Where-Object {$_.RecipientTypeDetails -eq "SharedMailbox"}
$Mailboxes | ForEach-Object {
    Write-Host $_.DisplayName -ForegroundColor Cyan
    Get-MessageTrackingLog -Recipients $_.primarysmtpaddress -start $dateStart -End $dateEnd | Export-Csv -NoTypeInformation .\output.csv -append}


#Show Unique addresses
$data = Import-Csv .\output.csv
$data = $data | Select-Object recipientaddress -Unique 
$data | Export-Csv .\UniqueAddresses.csv

#Launch Excel
Invoke-Command .\output.csv
Invoke-Command .\UniqueAddresses.csv