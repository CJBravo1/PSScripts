#Get Credentials
Write-Host "I need your Office 365 Credentials" -ForegroundColor Yellow
$UserCredential = Get-Credential -Message "Enter your Office 365 Credentials"

#Initial Variables
Connect-ExchangeOnline -Credential $userCredential
$MailContactCSV = Import-Csv .\MailContactList.csv

#Connect to PsSession
Write-Host "Loading Office 365 PS Module" -ForegroundColor Yellow

Write-Host "Creating Office 365 Mail Contacts" -ForegroundColor Yellow
foreach ($contact in $MailContactCSV)
    {
    Write-Host $contact.DisplayName -ForegroundColor Cyan
    $firstname = $contact.FirstName
    $lastName = $contact.LastName
    $company = $contact.Company
    $displayName = $contact.Displayname
    $displayName = "$displayName ($company)"
    $externalEmailAddress = $contact.ExternalEmailAddress
    $displayName

    New-MailContact -FirstName $firstname -LastName $lastName -DisplayName $displayName -ExternalEmailAddress $externalEmailAddress -WhatIf
    }