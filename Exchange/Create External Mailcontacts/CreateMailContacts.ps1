#Get Credentials
Write-Host "I need your Office 365 Credentials" -ForegroundColor Yellow
$UserCredential = Get-Credential -Message "Enter your Office 365 Credentials"

#Initial Variables
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
$MailContactCSV = Import-Csv .\MailContactList.csv

#Connect to PsSession
Write-Host "Loading Office 365 PS Module" -ForegroundColor Yellow
Import-PSSession $Session -WarningAction SilentlyContinue
#Connect-MsolService -Credential $UserCredential

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