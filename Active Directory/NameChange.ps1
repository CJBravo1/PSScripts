# NameChange.ps1
# Created by Regan Vecera with assisstance from Jonny Marshall
# 7.31.2017

# Purpose: This script is intended to change a person's user name and make
#		  sure it is changed in all the appropriate places in AD, Exchange, and O365
#		  so there are no residual issues

# Input: The script will interactively prompt for the user you wish to change. Give their
#		 full user name. Old, then new.

# Output: No output will be given. 2 emails will be sent to L&D and Business Systems to ensure accounts get updated across the board
#Test- Regan added some more to this line to show DJ how the changes work
cls


#Mail settings to allow send-mailmessage cmdlet to work with MFA
$mxserver = "accruent-com.mail.protection.outlook.com"

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
####################################
## Set up connections and objects ##
####################################
# Connect to Exchange Online
Import-PSSession $Session -AllowClobber

#Outer loop that will keep prompting for a user one at a time
:anotherUserLoop While($true)
{
	#Searches for user in Active Directory, and prompts for confirmation
    :searchLoop While($true)
    {
		#Search for user using Name field
        $userIn = Read-Host "Enter the user's SAM Account Name (first part of email) you wish to change (ex. regan.a.vecera , jbatson) " 
		"`n"
        $userFound = get-aduser -f {SAMAccountName -eq $userIn} -properties *
		
		#Display the user found
        $userFound.CN
        $oldUPN = $userFound.UserprincipalName
        $oldUPN
		
		#Boolean value to confirm the correct user is selected
        $correctUserBool = Read-Host "`nIs this the user you wish to change? [y/n]"
		"`n"
		if($correctUserBool -eq "y")
		{
			break searchLoop
		}
		else
		{
			#If user was incorrect, either restart search or quit program
			$searchNew = Read-Host "Search for a different user? [y\n]"
			if($searchNew -eq "n")
			{
				break anotherUserLoop
			}	
		}
    }
	
	#Check if they are contractor or not so the appropriate suffix can be applied later with the new name
	if ($userFound.UserPrincipalName -like "*contractor*")
	{
		$suffix = "@contractors.accruent.com"
	}
	else
	{
		$suffix = "@accruent.com"
	}
	#Get the new values
	$newUserName = Read-Host "Enter their new USER NAME "
	$firstName = Read-Host "`nEnter their FIRST name"
	$lastName = Read-Host "`nEnter their LAST name"
	$newFullName = $firstName + " " + $lastName
	
	#The primary proxy address for a user is the one used to send e-mail to the foreign system. 
	#The secondary proxy addresses are used when e-mail is received from the foreign system
	#Set AD properties
	$userFound.proxyAddresses.Add("SMTP:$newUserName$suffix")
	$userFound.proxyAddresses.Add("SIP:$newUserName$suffix")
	#$userFound.proxyAddresses.Remove("SMTP:$oldUPN") #maybe....
	
	#This will change CN, name, and distinguished name
	Rename-ADObject $userFound -NewName $newFullName
	
	
	Set-ADUser $userFound.SamAccountName -DisplayName "$newFullName" -Replace @{'msRTCSIP-PrimaryUserAddress' = "SIP:$newUserName$suffix";`
	'SamAccountName' = "$newUserName";`
	'mail' = "$newUserName$suffix";`
	'UserPrincipalName' = "$newUserName$suffix";`
	'targetAddress' = "SMTP:$newUserName$suffix";}
	
	$mailTo = "accruenttraining@accruent.com","businesssystems@accruent.com"
	$messageSubject = "ACTION | Name Change - $oldUPN -> $newUserName$suffix"
	$messageBody = "The user $oldUPN login name has been changed to $newUserName$suffix. This was done as a security precaution because the username appears to have been compromised. Please update your systems accordingly to prevent the user from getting locked out.
	This email has been created automatically by the Help Desk team as part of the name change process."
	
	Send-MailMessage -To $mailTo -Subject $messageSubject -Body $messageBody -SmtpServer $mxserver -From $adminUN -Credential $UserCredential -UseSsl
		 
	<#
	$psSession = New-PSSession -ConfigurationName microsoft.exchange -ConnectionUri http://exs41.accruent.com/powershell
	Import-PSSession $psSession -AllowClobber
	
	$exchangeProperties = @{ 'FirstName' = $firstName;
							 'LastName' = $lastName;
							 'WindowsEmailAddress' = "$newUserName$suffix";
	
	}
	set-user -Identity $userIn -Add $exchangeProperties
	#>
	
	$again = Read-Host "Search for another user? [Y/N]"
	if($again -eq 'n')
	{
		break anotherUserLoop
	}
}

#Creates variable to grab the server name of the closest Domain Controller to run the DC replication from.
$DC = $env:LOGONSERVER -replace ‘\\’,""

#Replication Command
repadmin /syncall $DC /APed
