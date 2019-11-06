# NewUserPasswordReset.ps1
# Created on 11.1.2017
# Created by Regan Vecera

<#
	This script is intended to be run after the new users computers have been setup. This script
	will generate a random password, set that as the user's password, force a change on next logon,
	and fill in the New Hire Welcome word document template with their username, temporary password,
	and email address
#>

# Load the AD modules
Import-Module ActiveDirectory
Import-Module AzureAD

#Helper function used to generate a random password of arbitrary length
#See usage immediately after function declarations
Function Get-Temppassword([int]$length,$sourcedata) {

	#Cast TempPassword as a string to prevent the possibility of picking a number
	#first and it becoming an integer, then erroring out when trying to add
	#a character to a number, also start with a A1a so the complexity
	#requirements of the domain are met
	$TempPassword = "A1a"
	For ($loop=1; $loop –le $length; $loop++) 
	{
		$TempPassword+=($sourcedata | GET-RANDOM)
	}
return $TempPassword
}

Function SearchAWord($Document,$findtext,$replacewithtext)
{ 
  $FindReplace=$Document.ActiveWindow.Selection.Find
  $matchCase = $false;
  $matchWholeWord = $true;
  $matchWildCards = $false;
  $matchSoundsLike = $false;
  $matchAllWordForms = $false;
  $forward = $true;
  $format = $true;
  $matchKashida = $false;
  $matchDiacritics = $false;
  $matchAlefHamza = $false;
  $matchControl = $false;
  $read_only = $false;
  $visible = $true;
  $replace = 2;
  $wrap = 1;
  $FindReplace.Execute($findText, $matchCase, $matchWholeWord, $matchWildCards, $matchSoundsLike, $matchAllWordForms, $forward, $wrap, $format, $replaceWithText, $replace, $matchKashida ,$matchDiacritics, $matchAlefHamza, $matchControl)
}

$alphabet = @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',1,2,3,4,5,6,7,8,9,0)
#************************ END FUNCTION DECLARATION*****************************#

#************************ BEGIN SCRIPT*****************************************#

#Clear screen and import the csv used to create the accounts
cls
$Users = $null
$Users = Import-Csv ".\user-account-creation.csv"

#Variable Declarations
$BostonPrinter = "\\bositprntsrv.accruent.com\BOS_Lower_Level_IT"
$AustinPrinter = "\\ausitprntsrv01\AUS_EST_1_Color"
$NewHireDoc = "$pwd\New Hire Welcome.docx"
$outputfile = "$pwd\NewHireWelcomeTest.docx"

#Gather credentials
Do
{
	$error.clear()
	$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
	$adminUN = ([ADSI]$sidbind).mail.tostring()
	$UserCredential = Get-Credential -UserName $adminUN -Message "Enter your password"

	If ($error.count -gt 0) { 
	Clear-Host
	$failed = Read-Host "Login Failed! Retry? [y/n]"
		if ($failed  -eq 'n'){exit}
	}
} While ($error.count -gt 0)

#Establishes Online Services connection to Office 365 Management Layer.
#Connect-MsolService -Credential $UserCredential

#Determine printer to use based on user running the script
#Also, account for the possibilty of running from a da account by trimming off the leading da_
$nonDA = ($adminUN).Replace("da_","")
switch ($nonDA)
{
	{$_ -eq "tsaygnarath@accruent.com" -or $_ -eq "dwinterson@accruent.com"}
	{
		$PrinterName = $BostonPrinter
	}
	{$_ -eq "regan.a.vecera@accruent.com" -or $_ -eq "tavian.floyd@accruent.com" -or $_ -eq "jbatson@accruent.com" -or $_ -eq "jjmarshall@accruent.com" -or $_ -eq "dat.vu@accruent.com" -or $_ -eq "lin.zhang@accruent.com"}
	{
		$PrinterName = $AustinPrinter
	}
	
}

#Establishes Connection with Azure AD
Connect-AzureAD -credential $UserCredential

#Loop through all users in the user account creation csv
foreach($User in $Users)
{
	#Grab full name from CSV
	$firstname = $User.FirstName
	$lastname = $User.LastName
	$fullname = $firstname + " " + $lastname
	
	#Search for their AD account
	$UID = (Get-ADUser -Filter {name -eq $fullname}).UserPrincipalName
	$username = ((Get-ADUser -Filter {name -eq $fullname}).SAMAccountName).toLower()
	
	#Reset their password to the randomly generated one and force change at next logon
	$password = Get-Temppassword 6 $alphabet
	Write-Host "Setting password for $fullname to $password..." -ForegroundColor Green
	
	#Set password on O365 server and force change on next login
	#Set AD password to the same, but don't force a change on login
	#MSOLUserPassword is no longer useful with federated users
	#Set-MsolUserPassword -UserPrincipalName $UID -NewPassword $password -ForceChangePassword $True
	
	#Set password via AzureAD
	$objectID = (Get-AzureADUser -ObjectId $UID).ObjectID
	Set-AzureADUserPassword -ObjectID $objectID -Password (ConvertTo-SecureString $password -AsPlainText -Force)
	$username
	
	#Set on-prem password
	Set-ADAccountPassword -Identity $username -Reset -NewPassword (ConvertTo-SecureString $password -AsPlainText -Force)
	#Set-ADUser -identity $username -ChangePasswordAtLogon $true
	
	#NewHireDoc and outputfile are delcared at top of code
	$Word = New-Object -ComObject Word.Application
	$Doc = $Word.documents.open($NewHireDoc)

	#Use the SearchAWord function to replace the specially crafted fields with user data
	#Supress output by piping to out-null
	SearchAWord -Document $Doc -findtext "xxxxxx" -replacewithtext "$username" | Out-Null
	SearchAWord -Document $Doc -findtext "yyyyyy" -replacewithtext "$password" | Out-Null

	$Doc.Saveas([REF]$outputfile)
	#Get the infos of all printer
	$Printers = Get-WmiObject -Class Win32_Printer

	#Set the default printer and print the word doc
	#Printer name specified at top of code
	$Printer = $Printers | Where{$_.Name -eq "$PrinterName"}
	$Printer.SetDefaultPrinter() | Out-Null
	Write-Host "Printing new hire sheet to $PrinterName..." -ForegroundColor Green
	
	Start-Process -FilePath $outputfile -Verb print
	$Doc.close()

	#Wait for 10 seconds then delete the file created for each individual user
	Sleep 10

	Remove-Item $outputfile
	Write-Host "************************************************"
}
$Word.Quit
Write-Host "Press any key to continue ..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")