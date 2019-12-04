# ContractorAccountCreation.ps1
# Last modified 9.21.17 by Regan Vecera
Start-Transcript -OutputDirectory "$pwd\Transcripts"

cls
$Users = $null
$Users = Import-Csv -Delimiter "," -Path ".\Contractors.csv"

#Helper function used to generate a random password of arbitrary length
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

# Load the AD modules
$UserCredential = Get-Credential -UserName $adminUN -Message "Enter your password"
Import-Module ActiveDirectory

Do
{
	#$error.clear()
	#$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	#$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
	#$adminUN = ([ADSI]$sidbind).mail.tostring()
	
	#$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

	#If ($error.count -gt 0) { 
	#Clear-Host
	#$failed = Read-Host "Login Failed! Retry? [y/n]"
		#if ($failed  -eq 'n'){exit}
	#}
} 
While ($error.count -gt 0)
#Import-PSSession $Session -AllowClobber

$emailbody = "" # clear out variable

#Email "From", SMTP variables, New Hire variables
$AccSender = $UserCredential.UserName

foreach ($User in $Users)  
    {
        # set each field into a variable for building command
		$FirstName = ($User.FirstName).replace(' ','')
		$LastName = $User.LastName
        $LastName1 = $LastName.replace(' ','')
        $FirstInitial = ($FirstName.Substring(0,1))
        $Username = ("$FirstName"+"."+"$LastName1")
        $UID = $Username.ToLower()
		$FullName = "$FirstName $Lastname"
        $Company = $User.Company
		$Department = $User.Department
		$Title = $User.Title
		$Manager = $User.Manager
		$expiration = $User.EndDate
		$expirationDate = [datetime]"$expiration"
        # create ADUser

		Write-Host "Data read in from CSV************************"
		Write-Host "First Name: "$FirstName
        Write-Host "Last Name: "$LastName
        Write-Host "Full Name: "$FullName
        Write-Host "Username: "$Username
        Write-Host "UserID: "$UID
        #Write-Host "Email Address: "$UID
        Write-Host "Manager: "$Manager


        "`n"
		
        
		# build command to update AD information, checking to see if variable has value, if it does, add it to the command
		# Every contractor should have a manager and end date at the very least
		if($Manager -eq "")
		{
			$Manager = Read-Host "No manager set in CSV. Fill out CSV and rerun code or enter the manager now:"
		}
		if($expirationDate -eq "")
		{
			$expirationDate = Read-Host "No end date set in CSV. Fill out CSV and rerun code or enter the end date now:"
		}
		if(($Manager -eq $null) -or ($expirationDate -eq $null))
		{
			Write-Host "Manager or End Date equal to null. New contractor account NOT created. Exiting..."
		}
		else
		{	
			#Reset their password to the randomly generated one and force change at next logon
			$password = Get-Temppassword 6 $alphabet
			Write-Host "Creating AD User $FullName and setting manager to $Manager"
			New-ADUser -Name $FullName -DisplayName $FullName -Path "OU=_Contractors365,OU=acc_Domain_Users,DC=accruent,DC=com" -SamAccountName $UID -GivenName $FirstName -Surname $LastName -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -ChangePasswordAtLogon $false -Enabled $true -AccountExpirationDate $expirationDate
			Set-ADUser -identity $UID -EmailAddress "$UID@contractors.accruent.com" -userPrincipalName "$UID@contractors.accruent.com"  
			Set-ADUser -identity $UID -Manager $Manager
			
			#Add these properties to AD object if they were in CSV
			if($Department -ne ""){Set-ADUser -identity $UID -Department $Department}
			if($Company -ne "") {Set-ADUser -identity $UID -Company $Company}
			if($Title -ne "") {Set-ADUser -identity $UID -Title $Title}
			
	        #Changes Proxy and Target Address' in Attibute Editor
	        Set-ADUser -Identity $UID -Add @{ProxyAddresses="SMTP:$UID@contractors.accruent.com"}
	        Set-ADUser -Identity $UID -Add @{TargetAddress="SMTP:$UID@accruentatlas.onmicrosoft.com"}

	        #Add ExtensionAttribute5
	        Set-ADUser -Identity $UID -Clear ExtensionAttribute3
	        Set-ADUser -Identity $UID -Add @{'ExtensionAttribute3' = 'Contractor'}

	       	#Attempting to assing E1 license for Contractor
	       	Set-MsolUser -UserPrincipalName $UID@contractors.accruent.com -UsageLocation US
	       	Set-MsolUserLicense -UserPrincipalName $UID@contractors.accruent.com -AddLicenses "accruentatlas:STANDARDPACK"

	        #Adds user to FortiNet VPN group
	        Add-ADGroupMember "VPN_General" $UID
	        
	        #Creates array to write out Full Name, Username, and Email Address for each user in CSV, to add to email notification body
	        $emailbody += "<br><br><b>User:</b> $FullName <br><b>Username:</b> $UID<br><b>Email:</b> $UID@contractors.accruent.com"

	        #Contractor email variables
	        $AccountBody =
	        "
	        <b><u>Accruent Credentials</u></b><br>
	        Name: $FirstName $LastName<br>
	        Username: $UID<br>
	        Password: $password<br>
	        Email Address: $UID@contractors.accruent.com<br>
	        <br>
	        <b><u>Accessing your email</u></b><br>
	        WebMail URL: <a href=http://portal.office365.com>portal.office365.com</a><br>
	        WebMail Username: $UID@contractors.accruent.com<br>
	        WebMail Password: $password<br>
	        <a href=http://it.accruent.com/index.php/2016/05/02/info-how-to-use-outlook-webmail-and-tips-and-tricks/>Instructions on using WebMail</a><br>
	        <br>
	        <b><u>Accessing the VPN</u></b><br>
	        VPN URL: <a href=https://secureaccess.accruent.com>https://secureaccess.accruent.com</a><br>
	        VPN Username/Password: same as your Accruent credentials<br>
	        <br>
	        <b><u>Submitting a IT Trouble Ticket</u></b><br>
	        URL: <a href=http://kace.accruent.com>kace.accruent.com</a><br>
	        Username/Password: same as your Accruent Credentials<br>
	        <a href=http://it.accruent.com/index.php/2016/03/10/network-self-service-portal/>Instructions on how to enter a KACE ticket for any issues you may have.</a><br>
	        <br>
	        Please let me know if there are any issues.<br>
	        <br>
	        Thank you,<br>
	        <br>
	        Service Desk Team<br>
	        "
			
			$servicedesk = "servicedesk@accruent.com"
			$mxserver = "accruent-com.mail.protection.outlook.com"
			
	        #Contractor Account Info email
	        #Send-MailMessage -To 'dat.vu@accruent.com' -From $AccSender -Subject "INFO | Contractor Account Info" -Body $AccountBody -BodyAsHtml -Credential $UserCredential -SmtpServer smtp.office365.com -UseSsl
			Write-Host "Sending email to Service Desk"
			Send-MailMessage -To $servicedesk -From $AccSender -Subject "INFO | Contractor Account Info" -Body $AccountBody -BodyAsHtml -Credential $UserCredential -SmtpServer $mxserver -UseSsl
    	}
	}

#Force Domain Controller Replication, and then sysc BosCorpAADC to Office365
#Creates variable to grab the server name of the closest Domain Controller to run the DC replication from.
$DC = $env:LOGONSERVER -replace ‘\\’,""

#Replication Command
#repadmin /syncall $DC /APed

#Creates variable with command to run Domain to O365 sync
$script =
{
    & "C:\Program Files\Microsoft Azure AD Sync\Bin\DirectorySyncClientCmd.exe" delta
}

#Command to kick off Sync command
#Invoke-Command -ComputerName BOSCORPAADC.accruent.com -ScriptBlock $script


#Remove-PSSession $Session