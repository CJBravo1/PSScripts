#Import CSV
Write-Host "Importing Contacts Import" -ForegroundColor Green
$ImportCSV = Import-Csv '.\Contacts Import.csv'

#Create New Contacts
Write-Host "Creating mail Contacts"
Write-Host $_.Name -ForegroundColor Magenta
$ImportCSV | foreach {New-MailContact -FirstName $_.First -LastName $_.Last -ExternalEmailAddress $_.Email -Name $_.Name -WhatIf}