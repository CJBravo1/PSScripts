Clear-Host
#$ErrorActionPreference= 'silentlycontinue'

write-host "##################################################
#                   !New ADUser!                 #
##################################################" -ForegroundColor Green 


#Import the Active Directory Powershell Module
Import-Module activedirectory
$pass = Read-Host -AsSecureString -Prompt "Enter Password to be set on all user accounts"

#Standard Active Directory Groups
$ADGroups = "Verisae Employee"

#Gather New User Information
$newUsers = Import-Csv 'C:\Temp\New Users.csv'

#Sort User Account Information
foreach ($name in $newUsers)
	{
	$fname = $name.First
	$lname = $name.Last
	$fullName = "$fname $lname"
	$uname = $name.Email
	$email = "$uname@verisae.com"
	$dept = $name.Department
	$title = $name.Title
	$country = $name.Country
	$company = $name.Location
	$Location = $name.Location
	$startDate = $name.Start
	$endDate = $name.End
	
	$name
	New-ADUser -Name $fullName -DisplayName $fullName -GivenName $fname -Surname $lname -SamAccountName $uname -EmailAddress $email -Department $dept -Title $title -Company $company -Office $Location -Path "OU=People,DC=Verisae,DC=int" -PasswordNeverExpires $true -UserPrincipalName $email -AccountExpirationDate $endDate -Confirm
	Set-ADAccountPassword -Identity $uname -NewPassword $pass
	#Set-ADAccountExpiration -Identity $uname -DateTime $endDate
	
	$aduser = Get-ADUser -Identity $uname
	
	$aduser
	}
	
	#Write-Host "Confirm?" -ForegroundColor Green
	#Pause
	