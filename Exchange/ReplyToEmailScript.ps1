#ReplyToEmailScript.ps1
#Created by: Regan Vecera
#Date: 7/1/2017

#This script shows the code necessary to embed a link that will create a mail message to a specified sender, with subject and body text already filled in
#This was made in an effort to further refine the termination process by sending a message to the termed user's manager requesting the name of 
#other environments they had access to so they could be appropriately removed.

Do
{
$error.clear()
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
If ($error.count -gt 0) { 
Clear-Host
$failed = Read-Host "Login Failed! Retry? [y/n]"
	if ($failed  -eq 'n'){exit}
}
} While ($error.count -gt 0)
Import-PSSession $Session -AllowClobber

			#Contractor email variables
	        $AccountBody =
	        "

	        <a href= `"mailto:supportmgmt@accruent.com?
			subject=ACTION | Remove Termed User Product Access&
			body=
			Please reply with the names of the Application production environments that this employee may have had access to. To clarify, we need to understand which customer facing applications your employee may have had a username and password for. As an example, employee X in Support had access to Accruent Suite to reproduce and capture production issues. You would list Accruent Suite in the application list and (if available) the username that the employee used.
			%0B%0B%0BApplications users had access to:`">Click here to email Regan</a><br>
	        "
			$AccSender = "regan.a.vecera@accruent.com"
			
	        #Contractor Account Info email
	        Send-MailMessage -To $AccSender -From $AccSender -Subject "INFO | Contractor Account Info" -Body $AccountBody -BodyAsHtml -Credential $UserCredential -SmtpServer smtp.office365.com -UseSsl   
		