# AssignE3andEMS.ps1
# Created on 11.1.2017
# Created by Regan Vecera

<#
	This script is intended to be run after user-account-creation2.ps1 but before NewUserPasswordReset.ps1
	There needs to be a buffer between the time you ran user-account-creation2 and this script so the Active
	Directory accounts can sync to O365 and a license can be assigned.
	This pulls from the same csv used to create the accounts user-account-creation.csv
#>

#Clear screen and import the csv used to create the accounts
cls
$Users = $null
$Users = Import-Csv ".\KykloudCensus.csv"

# Load the AD modules
Import-Module ActiveDirectory

#Launch O365 Session, pull username from person currently logged in
Do
{
	$error.clear()
	$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
	$adminUN = ([ADSI]$sidbind).mail.tostring()
	$UserCredential = Get-Credential -UserName $adminUN -Message "Enter your password"
	$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

	If ($error.count -gt 0) { 
	Clear-Host
	$failed = Read-Host "Login Failed! Retry? [y/n]"
		if ($failed  -eq 'n'){exit}
	}
} While ($error.count -gt 0)
Import-PSSession $Session -AllowClobber

#Establishes Online Services connection to Office 365 Management Layer.
Connect-MsolService -Credential $UserCredential
foreach($User in $Users)
{
	$firstname = $User.FirstName
	$lastname = $User.LastName
	$fullname = $firstname + " " + $lastname
	$useremail = (Get-ADUser -Filter {name -eq $fullname}).UserPrincipalName
	$username = (Get-ADUser -Filter {name -eq $fullname}).SamAccountName
	$forward = $User.ForwardingAddress
	
	$country = Get-ADUser -Filter {name -eq $fullname} -Properties * | select Country
	Write-Host "Assigning E3 and EMS licenses to $useremail..." -ForegroundColor Green
	$objectID = (Get-ADUser $username -Properties *).ObjectGUID
	
	#Sets user's location
	Set-MsolUser -UserprincipalName $useremail -UsageLocation GB
	#Sleep 3
	
	#Assign E1
	try{
		Set-MsolUserLicense -UserPrincipalName $useremail -AddLicenses accruentatlas:EXCHANGESTANDARD #-ErrorAction Suspend
	}catch{
		Write-Host "There was an error assigning the licenses to $useremail`n" -ForegroundColor "yellow"
	}
	Write-Host "Setting forwarding address for $fullname to $forward" -ForegroundColor Yellow
	Set-Mailbox -Identity $useremail -DeliverToMailboxAndForward $false -ForwardingAddress $forward
}

Write-Host "Press any key to continue ..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Exit-PSSession