Write-Host "Use this script to get email messages sent to shared mailboxes over the past 30 Days." -ForegroundColor Green

#Make new session
$Session = Get-PSSession | where {$_.ConfigurationName -eq "Microsoft.Exchange"}

if ($session -eq $null)
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
$Mailboxes | ForEach-Object {Get-MessageTrackingLog -Recipients $_.primarysmtpaddress -start $dateStart -End $dateEnd | Export-Csv -NoTypeInformation .\output.csv -append}


#Show Unique addresses
$data = Import-Csv .\output.csv
$data = $data | select recipientaddress -Unique 
$data | Export-Csv .\UniqueAddresses.csv

#Launch Excel
Invoke-Command .\output.csv
Invoke-Command .\UniqueAddresses.csv