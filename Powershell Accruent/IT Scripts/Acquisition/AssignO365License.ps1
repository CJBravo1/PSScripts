# AssignE3andEMS.ps1
# Created on 11.1.2017
# Created by Regan Vecera

<#
	This script is intended to be run after AccountCreation.ps1 but before NewUserPasswordReset.ps1
	There needs to be a buffer between the time you run AccountCreation and this script so the Active
	Directory accounts can sync to O365 and a license can be assigned.
	This pulls from the same csv used to create the accounts UserData.csv
	
	Parameters: Use the switches at the top to assign the Usage Location (must be set before giving a license) 
				and the various licenses you wish the user to have
#>

#Clear screen and import the csv used to create the accounts
cls
$Users = $null
$Users = Import-Csv ".\UserData.csv"

$UsageLocation = "NL" #2 character country code
$AssignExchOnline = $false
$AssignE1 = $false
$AssignE3 = $true
$AssignEMS = $true


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
	$firstname = $User.'First Name'
	$lastname = $User.'Last Name'
	$fullname = $firstname + " " + $lastname
	$useremail = (Get-ADUser -Filter {name -eq $fullname}).UserPrincipalName
	$username = (Get-ADUser -Filter {name -eq $fullname}).SamAccountName
	
	$country = Get-ADUser -Filter {name -eq $fullname} -Properties * | select Country
	#$objectID = (Get-ADUser $username -Properties *).ObjectGUID
	
	#Sets user's location
	Set-MsolUser -UserprincipalName $useremail -UsageLocation $UsageLocation
	#Sleep 3
	
	#Assign E1
	
	if($AssignExchOnline)
	{
		Write-Host "Assiging Exchange Online (Plan 1) to $fullname"
		Set-MsolUserLicense -UserPrincipalName $useremail -AddLicenses accruentatlas:EXCHANGESTANDARD 
	}
	if($AssignE1)
	{
		Write-Host "Assiging E1 to $fullname"
		Set-MsolUserLicense -UserPrincipalName $useremail -AddLicenses accruentatlas:STANDARDPACK
	}
	if($AssignE3)
	{
		Write-Host "Assiging E3 to $fullname"
		Set-MsolUserLicense -UserPrincipalName $useremail -AddLicenses accruentatlas:ENTERPRISEPACK
	}
	if($AssignEMS)
	{
		Write-Host "Assiging EMS to $fullname"
		Set-MsolUserLicense -UserPrincipalName $useremail -AddLicenses accruentatlas:EMS 
	}
}

Write-Host "Press any key to continue ..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Exit-PSSession