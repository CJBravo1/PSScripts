#Connect to Office 365
#Get Credentials
$CurrentUser = $env:USERNAME
if ($null -eq $adminCreds)
{
    $adminCreds = Get-Credential "SURESCRIPTS\a$CurrentUser"
}
$Session = Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange"}

if ($null -eq $session)
{
    Write-Host "Connecting to Office 365" -ForegroundColor Yellow
    Connect-ExchangeOnline -Credential $adminCreds
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
$groups=Import-Csv .\DistroGroups.csv
$groups | ForEach-Object{Get-MessageTrace -RecipientAddress $_.primarysmtpaddress -startDate $dateStart -EndDate $dateEnd ; write-host (“Processed Group:  ” + $_.primarySMTPAddress)} | export-csv -Path .\output.csv –Append


#Show Unique addresses
$data = Import-Csv .\output.csv
$data = $data | Select-Object recipientaddress -Unique 
$data | Export-Csv .\UniqueAddresses.csv

#Launch Excel
Invoke-Command .\output.csv
Invoke-Command .\UniqueAddresses.csv