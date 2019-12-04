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

#Variable Declarations
#$PrinterName = "\\ausitprntsrv01\AUS_EST_1_Color"
$NewHireDoc = "$pwd\New Hire Welcome.docx"
$outputfile = "$pwd\NewHireWelcomeTest.docx"


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

#Clear screen and import the csv used to create the accounts
cls
$Users = $null
$Users = Import-Csv ".\KykloudCensus.csv"

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
    $Doc.close()
	#Get the infos of all printer
	#$Printers = Get-WmiObject -Class Win32_Printer

	#Set the default printer and print the word doc
	#Printer name specified at top of code
	#$Printer = $Printers | Where{$_.Name -eq "$PrinterName"}
	#$Printer.SetDefaultPrinter() | Out-Null
	#Write-Host "Printing new hire sheet to $PrinterName..." -ForegroundColor Green
	#Start-Process -FilePath $outputfile -Verb print
	$mxserver = "accruent-com.mail.protection.outlook.com"
	$subject = "INFO | Accruent Account Credentials"
	#$body = "Please see the attached word document containing your Accruent username, password, and more detailed information."
    $body = "Hello from the Accruent Corporate IT department! Attached to this email is information to access your Accruent account as well as a few other helpful bits of information. 

One very important note, please do not access Teams, Outlook, or the Calendar directly on this account just yet. This account was setup so you can start accessing our systems and  services, but the email account is set to forward to your KyKloud email address until we are able to fully migrate your email to our system. If you try to use the Accruent account for sending or receiving emails, meetings, or to access teams, it will cause issues later. Instructions and steps for the full migration will arrive in the next few weeks

You will start to see invitations to Confluence and other systems via your Accruent email account. When you have those invitations, you will be able to access those systems using your Accruent account. Note that much of this will be single sign on. If you are logged into a browser with your KyKloud account, you will need to either log out, open a private browser window to start a new session, or use an alternate browser. If you see anything denying you access, it's likely because you are logged in to your KyKloud account in that browser.

If you have any questions/concerns/issues/problems, please reach out to Mike, Jonny, or Josh for assistance.

Mike Metcalf - mike.metcalf@accruent.com

Jonny Marshall - jjmarshall@accruent.com

Josh Batson - jbatson@accruent.com

"
$bcc = "jjmarshall@accruent.com","jbatson@accruent.com","regan.a.vecera@accruent.com"


	$Me = "regan.a.vecera@accruent.com"
	
	Send-MailMessage -To $UID -bcc $bcc -Subject $subject -Body $body -SmtpServer $mxserver -From $Me -Attachments $outputfile -Credential $UserCredential -UseSsl
	
	
	

	#Wait for 10 seconds then delete the file created for each individual user
	Sleep 2

	Remove-Item $outputfile
	Write-Host "************************************************"
}
$Word.Quit
Write-Host "Press any key to continue ..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")