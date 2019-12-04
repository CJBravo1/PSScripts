# NewUserPasswordReset.ps1
# Created on 04.13.2018
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
$attachedfile = '.\Accruent Credentials.docx'


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

$alphabet = @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',1,2,3,4,5,6,7,8,9,0)

#Clear screen and import the csv used to create the accounts
cls
$Users = $null
$Users = Import-Csv ".\bcusers2.csv"

Do
{
$error.clear()
$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
$adminUN = ([ADSI]$sidbind).mail.tostring()
$UserCredential = Get-Credential -UserName $adminUN -Message "Enter your password"
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

If ($error.count -gt 0) { 
#Clear-Host
$failed = Read-Host "Login Failed! Retry? [y/n]"
	if ($failed  -eq 'n'){exit}
}
} While ($error.count -gt 0)
Import-PSSession $Session -AllowClobber

#Establishes Connection with Azure AD
#Connect-AzureAD -credential $UserCredential

#Loop through all users in the user account creation csv
foreach($User in $Users)
{
	#Grab full name from CSV
	$username = $User.UserName
	$BCemail = $User.EmailAddress
	
	#Search for their AD account
	$ADUser = get-aduser $username
	$email = (Get-ADUser $username).userPrincipalName
	
	#Reset their password to the randomly generated one and force change at next logon
	$password = Get-Temppassword 6 $alphabet
	Write-Host "Setting password for $username to $password..." -ForegroundColor Green
	
	#Set password via AzureAD
	#$objectID = (Get-AzureADUser -ObjectId $username).ObjectID
	#$objectID
	#Set-AzureADUserPassword -ObjectID $objectID -Password (ConvertTo-SecureString $password -AsPlainText -Force)
	
	#Set on-prem password
	Set-ADAccountPassword -Identity $username -Reset -NewPassword (ConvertTo-SecureString $password -AsPlainText -Force)
	Set-ADUser -identity $username -ChangePasswordAtLogon $false
	
	
	$mxserver = "accruent-com.mail.protection.outlook.com"
	$subject = "DELIVERY | Accruent User Credentials for BlueCielo Employees"
    $body = 
	
"All,<br>
<br>
<b><u>INFO</u></b> <br>
<br>
It is finally time to get you all set up with some Accruent user credentials!<br>
<br>
This email will give you some of the login information for the various tools that Accruent uses. These accounts are for the main tools that the Accruent IT group manages. Please see below for the steps you need to take to start accessing these tools. <br>
<br>
<b><span style=`"color:red;`">IMPORTANT!!!</span></b> &#8212 Please make sure you complete the login and password change process (Step 2, below) within the first week, or 4/23/18. This will make sure your credentials are all configured by the start of the email migrations. <br>
<br>
<b><u>ACTION</u></b><br>
<ol>
	<li>First, open the attached Word document that explains how to log into your Accruent Office 365 account, set up your Multi-Factor Authentication, and then log into your Confluence account.You will need to open up a different web browser than normal so that you can have a separate Office 365 session open for your Accruent login than you do for your BlueCielo login. This will keep you from confusing your logins and getting Access Denied errors.</li>
	<li>Once you have logged into your Office 365 account, and then log into your Confluence account, go <a href=https://accruent.atlassian.net/wiki/spaces/IT/pages/375161165/O365+Changing+your+password>here</a> to find out how to reset your password on your Office 365 account.</li>
	<li>That&#39s it! See below for login credentials for some of the other common tools and how to use them. </li>
</ol>
<b><u>USER CREDENTIALS</u></b><br>
<br>
<b>Accruent User Account</b><br>
UserName: $username<br>
Office 365 UserName: $email<br>
Password for Both: $password<br>
Email Address: $email<br>
<i>Tech Tips:</i><ul>
	<li>Go <a href=https://accruent.atlassian.net/wiki/spaces/IT/pages/375062798/Office+365>here</a> for some of the write-ups we have for using your Office 365 account. </li>
	<li><i><b>Best Practices:</b></i> Go <a href=https://accruent.atlassian.net/wiki/spaces/IT/pages/431392164/O365+Setting+up+the+Microsoft+Authenticator+App>here</a> for information on using the Microsoft Authenticator app on your mobile device for the Multi-Factor Authentication piece. This is one of the better ways of getting the verification codes that you will need from signing into your Office 365 account. </li>
	<li><i><b>Best Practices:</b></i> <a href=https://accruent.atlassian.net/wiki/spaces/IT/pages/570130436/Browsers+Creating+Bookmarks>Create a bookmark</a> for the Office 365 home page for easy login. The URL is https://portal.office.com</li>
</ul>
<b>Confluence User Account (Single&#45Sign On &#47 SSO)</b><br>
UserName: same as your Accruent Office 365 UserName<br>
Password: same as your Accruent Office 365 Password<br>
<i>Tech Tips:</i> <ul>
	<li><a href=https://accruent.atlassian.net/wiki/spaces/IT/pages/584778005/CONFLUENCE+Confluence+Quick+Start+FAQ>Confluence Quick Start and FAQ</a></li>
	<li>Go <a href=https://accruent.atlassian.net/wiki/spaces/IT/pages/252183665/Accruent+Tech+Tips>here</a> for the Accruent Tech Tips site for information on the products and tools we support.</li>
	<li><i><b>Best Practices:</b></i> Bookmark <a href=https://accruent.atlassian.net/wiki/spaces/AHP/overview?mode=global>Confluence Homepage</a></li>
	<li><i><b>Best Practices:</b></i> Bookmark <a href=https://accruent.atlassian.net/wiki/spaces/CAI/pages/562694217/Welcome+BlueCielo+Team>BlueCielo Integration page.</a></li>
	<li><i><b>Best Practices:</b></i> For all of you Sales and Account Management people out there, go here to get to Accruent&#39s <a href=https://accruent.atlassian.net/wiki/spaces/TSA/overview>Sales Front Door!</a></li>
</ul>
<b>Microsoft Teams (SSO)</b><br>
UserName: same as your Accruent Office 365 UserName<br>
Password: same as your Accruent Office 365 Password<br>
<i>Tech Tips:</i> <ul>
	<li>How to <a href=https://accruent.atlassian.net/wiki/spaces/IT/pages/364871750/TEAMS+How+to+download+the+Microsoft+Teams+desktop+client>download and install Microsoft Teams</a>.</li>
	<li>How to <a href=https://accruent.atlassian.net/wiki/spaces/IT/pages/374898948/TEAMS+Scheduling+a+meeting+from+the+Teams+app>set up a Teams meeting</a>.</li>
	<li>Various write-ups on <a href=https://accruent.atlassian.net/wiki/spaces/IT/pages/365527082/Teams>how to use Teams.</a></li>
	<li><i><b>Best Practices:</b></i> Teams is the preferred Instant Messenger choice over Skype for Business. </li>
	<li><i><b>Best Practices:</b></i> Name your department team starting with &#34DEPT &#8212 &#34; Name cross-functional team starting with &#34TEAM &#8212&#34 <a href=https://accruent.atlassian.net/wiki/spaces/IT/pages/575244225/TEAMS+Naming+Standards>here are the current standards</a></li>
	<li><i><b>Best Practices:</b></i> Download Teams mobile app to stay connected on the go!</li>
	<li><i><b>Best Practices:</b></i> Use Teams to store and share files in lieu of Email or local storage folders. Teams files can be accessed in OneDrive or SharePoint 365 through the &#34<a href=https://accruent.atlassian.net/wiki/spaces/IT/pages/575178275/TEAMS+Syncing+Teams+Files+to+Your+Local+File+Explorer>SharePoint Site sync.</a>&#34</li>
</ul>
<b>One Drive (SSO)</b><br>
UserName: same as your Accruent Office 365 UserName<br>
Password: same as your Accruent Office 365 Password<br>
<i>Tech Tips: </i><ul>
<li>Please <b>continue using your BlueCielo Onedrive</b> until it is migrated with your emails</li>
<li>Various write-ups on <a href=https://accruent.atlassian.net/wiki/spaces/IT/pages/375062802/OneDrive>how to use OneDrive.</a></li>
</ul>
<b>KACE User Account - IT Ticketing System (SSO)</b><br>
UserName: $username (without the @accruent.com).<br>
Password: Same as your Accruent password. <br>
Go <a href=https://kace.accruent.com>here</a> to submit a KACE ticket<br>
<i>Tech Tips:</i><ul>
	<li>How to<a href=https://accruent.atlassian.net/wiki/spaces/IT/pages/375259309/KACE+Submitting+a+KACE+Ticket> submit a ticket via web browser.</a></li>
	<li>How to<a href=https://accruent.atlassian.net/wiki/spaces/IT/pages/375259324/KACE+Submitting+a+KACE+ticket+via+email> submit a ticket via email.</a></li>
</ul>
Please go <a href=https://accruent.atlassian.net/wiki/spaces/CAI/pages/408355972/Accruent+User+Account+BC>here</a> to find all the information contained within this email for future reference.<br>
<br>
Thank you,<br>
<br>
Josh Batson <br>
IT Service Desk Manager<br>
O 512-643-8686<br>
C 512-771-3087<br>
"
	$bcc = "jbatson@accruent.com","regan.a.vecera@accruent.com"
	Write-Host "Sending mail message to $email" -ForegroundColor DarkBlue
	Send-MailMessage -To $email -bcc $bcc -Subject $subject -Body $body -SmtpServer $mxserver -From "jbatson@accruent.com" -UseSsl -BodyAsHtml -Attachments $attachedfile -Credential $UserCredential
	
	
	

	#Wait for 10 seconds then delete the file created for each individual user
	#Sleep 2

	#Remove-Item $outputfile
	Write-Host "************************************************"
}
#$Word.Quit
Write-Host "Press any key to continue ..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")