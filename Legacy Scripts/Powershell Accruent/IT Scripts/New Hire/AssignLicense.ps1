# AssignLicense.ps1
# Created on 11.1.2017
# Created by Regan Vecera

<#
	This script is intended to be run after user-account-creation2.ps1 but before NewUserPasswordReset.ps1
	There needs to be a buffer between the time you ran user-account-creation2 and this script so the Active
	Directory accounts can sync to O365 and a license can be assigned. This will assign users an E3 license
	E3 + EMS, and put them into a few clouds DLs based on department and/or title and/or location
	This pulls from the same csv used to create the accounts user-account-creation.csv
#>

##################### FUNCTION DECLARATION #####################
Function Add-CloudSGMember([string]$email,$groupname,$UserCredential) {

	$msoluser = Get-MsolUser -UserPrincipalName $email
	Add-MsolGroupMember -GroupObjectId $groupname -GroupMemberType User -GroupMemberObjectId $msoluser.ObjectId
	Write-Host "Added $email to the group $groupname"
}
Function Add-O365GroupMember([string]$email,$groupname)
{
	Add-UnifiedGroupLinks -Identity $groupname -Links $email -LinkType Members
}
########################## END FUNCTION DECLARATION ############


#Clear screen and import the csv used to create the accounts
cls
$Users = $null
$Users = Import-Csv ".\user-account-creation.csv"

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
	$Product = $User.Product
	$fullname = $firstname + " " + $lastname
	$useremail = (Get-ADUser -Filter {name -eq $fullname}).UserPrincipalName
	$username = (Get-ADUser -Filter {name -eq $fullname}).SamAccountName
	
	$country = Get-ADUser -Filter {name -eq $fullname} -Properties * | select Country
	$title = Get-ADUser -Filter {name -eq $fullname} -Properties * | select Title
	$Department = Get-ADUser -Filter {name -eq $fullname} -Properties * | select Department
	
	Write-Host "Assigning E3 and EMS licenses to $useremail..." -ForegroundColor Green
	$objectID = (Get-ADUser $username -Properties *).ObjectGUID
	
	#Sets user's location
	Set-MsolUser -UserprincipalName $useremail -UsageLocation US
	#Sleep 3
	
	#Assign E3 and EMS
	try{
		Set-MsolUserLicense -UserPrincipalName $useremail -AddLicenses accruentatlas:ENTERPRISEPACK,accruentatlas:EMS #-ErrorAction Suspend
	}catch{
		Write-Host "There was an error assigning the licenses to $useremail`n" -ForegroundColor "yellow"
	}
	
	#ObjectID for '[ALL] Zoom Access SG'
	$ZoomGroup = "cbcbd9da-65aa-4efc-a331-19410235c35a" 
	
	
	Add-O365GroupMember($useremail,"Accruent")
	
	#Sets extra "Member Of" groups, per department/product
	Write-Host "Adding User to Department based AD Groups" -Foregroundcolor Green
	Switch -wildcard ($Department)
	{
		"Assessment Services*"
            {
			Add-CloudSGMember($useremail,$ZoomGroup,$UserCredential)
            }
		"Business Services*"
            {
			Add-CloudSGMember($useremail,$ZoomGroup,$UserCredential)
            }
		"Capital Planning*"
            {
			Add-CloudSGMember($useremail,$ZoomGroup,$UserCredential)
            }
		"Recruiting*"
			{
			Add-CloudSGMember($useremail,$ZoomGroup,$UserCredential)
			}
		"Customer Success*"
			{
			Add-CloudSGMember($useremail,$ZoomGroup,$UserCredential)
			}
		"Executive*"
			{
			Add-CloudSGMember($useremail,$ZoomGroup,$UserCredential)
			}
		"Learning & Development*"
			{
			Add-CloudSGMember($useremail,$ZoomGroup,$UserCredential)
			}
		"*Marketing*"
			{
			Add-CloudSGMember($useremail,$ZoomGroup,$UserCredential)
			}
		"Product Manager*"
			{
			Add-CloudSGMember($useremail,$ZoomGroup,$UserCredential)
			}
		"Professional Services*"
            {
			Add-CloudSGMember($useremail,$ZoomGroup,$UserCredential)
			if (($Product -eq "Lucernex") -or ($Product -eq "LX"))
			{
				
            }
			}
		"*PMO*"
			{
			Add-CloudSGMember($useremail,$ZoomGroup,$UserCredential)
			}
        "Support Telecom"
			{
	
			}
		"Support*"
			{
			Add-CloudSGMember($useremail,$ZoomGroup,$UserCredential)
			}
        "Business Development*"
			{
			Add-CloudSGMember($useremail,$ZoomGroup,$UserCredential)
			}
		{($_ -like "*Sales*") -and (($_ -like "*Director*") -or ($_ -like "*Vice President*") -or ($_ -like "*SVP*"))}
			{
			
			}
		"Sales Engineering*"	
			{
			
			}
	}
	
	Write-Host "Adding User to Product based AD Groups" -Foregroundcolor Green
	Switch -wildcard ($Product)
	{
        "FRSoft"
			{
			
			}
        "SiteFM"
			{
				
			}
        "Mainspring"
			{
				
			}
        "Siterra"
			{
				
			}
        "BIGCenter"
			{
				
			}
        "Verisae"
			{
				
			}
		{($_ -eq "Lucernex") -or ($_ -eq "LX")}
			{
				Add-O365GroupMember($useremail,"Lucernex")
			}
	}
		
	Write-Host "Adding User to Title based AD Groups" -Foregroundcolor Green
	Switch -wildcard ($title)
	{
		"*Account Executive*"{Add-CloudSGMember($useremail,$ZoomGroup,$UserCredential)}
		"*Strategic Account*"{Add-CloudSGMember($useremail,$ZoomGroup,$UserCredential)}
	}
}

Write-Host "Press any key to continue ..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Exit-PSSession