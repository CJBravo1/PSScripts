Write-Host "Re-Create New Hire Email" -ForegroundColor Green

#Office 365 Sign in
$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
$adminUN = ([ADSI]$sidbind).mail.tostring()
$UserCredential = Get-Credential -UserName $adminUN -Message "Enter your password"
#$UserCredential = Get-Credential -Message "Enter your Office 365 Credentials"

#Email Server Session
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session

#Needed Variables
$FirstName = Read-Host -Prompt "First Name"
$LastName = Read-Host -Prompt "Last Name"
$OfficeName = Read-Host -Prompt "Office"
$Description = Read-Host -Prompt "Title / Description"
$Department = Read-Host -Prompt "Department"
$Manager = Read-Host -Prompt "Manager's Username"
$Product = Read-Host -Prompt "Product"
$FullName = "$FirstName $Lastname"
$Sender = $UserCredential.UserName

#Email Server
$mxserver = "accruent-com.mail.protection.outlook.com"
$smtpserver = "smtp.office365.com" 

#Username
$Username = "$FirstName"+"."+"$LastName"
$UID = $Username.ToLower()
$Email = $UID+"@accruent.com"


#Write Email
Write-Host "Writing Email" -Foregroundcolor Green
	$EmailBody += "<br><br><b>User:</b> $FullName <br><b>Username:</b> $UID<br><b>Email:</b> $UID@accruent.com"

        #Creates variables for email to get Member Of groups from user's manager
        $ManagerFirst = (Get-ADUser $Manager -Properties givenName).givenName
        $ManagerEmail = (Get-ADUser $Manager -Properties userPrincipalName).userPrincipalName
		$office = Get-ADUser $UID -Properties * | Select Office 
		$GroupsBody =
        "$ManagerFirst,
        <br>
        <br>
        In preparation for $FullName's first day of work, please
	        
        <a href= `"mailto:helpdesk1@accruent.com?
		subject= REQUEST | Security/Distro Groups - $Fullname&
		body=@priority = Medium (7 bus days)%0B@category = User Access/Account Mgmt%0B@location = TX-AUSTIN%0B%0B

		$Fullname should be placed in the following groups:`">click here to create a KACE ticket</a><br> that can be filled out with security groups and distribution lists that the employee needs to be a part of.
		<br><br>	
	    <b>Please be specific -</b> We will not mirror another user's access, as they don't always line up 100%. We can provide you a list of groups that a user is part of, and you can select from there, but we will not be able to just mirror a user's access.
        <br><br>
        Thank you,
        <br><br>
        IT Service Desk "

        #New Hire Created Email
        #Send-MailMessage -To $ManagerEmail -From $Sender -Subject "REQUEST | New Hire Security/Distro Groups - $FullName" -Body $GroupsBody -BodyAsHtml -Credential $UserCredential -SmtpServer $mxserver -UseSsl   

        #New Hire Created Email
        Write-Host "Sending Email" -ForegroundColor Green
        Send-MailMessage -To "servicedesk@accruent.com" -From $Sender -Subject "INFO | New Hire Created" -Body $EmailBody -BodyAsHtml -Credential $UserCredential -SmtpServer $mxserver -UseSsl

        Write-Host "A copy of the email has been exported to C:\Temp\NewHireEmail.html" -ForegroundColor Yellow
        $EmailBody > C:\Temp\NewHireEmail.html