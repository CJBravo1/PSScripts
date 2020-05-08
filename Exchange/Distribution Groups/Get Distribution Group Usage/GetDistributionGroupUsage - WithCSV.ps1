Write-Host "Use this script to get email messages sent to distribution groups over the past 30 Days." -ForegroundColor Green

#Connect to Office 365
$UserCredential = Get-Credential -Message "Enter your Office 365 Credentials"

#Make new session
Write-Host "Connecting to Office 365" -ForegroundColor Yellow
$Session = Get-PSSession | where {$_.ConfigurationName -eq "Microsoft.Exchange"}

if ($session -eq $null)
{
    Connect-ExchangeOnline
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
$groups=Import-Csv .\DistroGroups.csv
$groups | %{Get-MessageTrace -RecipientAddress $_.primarysmtpaddress -startDate $dateStart -EndDate $dateEnd ; write-host (“Processed Group:  ” + $_.primarySMTPAddress)} | export-csv -Path .\output.csv –Append


#Show Unique addresses
$data = Import-Csv .\output.csv
$data = $data | select recipientaddress -Unique 
$data | Export-Csv .\UniqueAddresses.csv

#Launch Excel
Invoke-Command .\output.csv
Invoke-Command .\UniqueAddresses.csv