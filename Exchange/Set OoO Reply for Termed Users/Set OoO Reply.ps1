# Import CSV with list of users to term
$Users = $null
$Users = Import-Csv -Path TermedUsers.csv

# Gather credentials
$Cred = Get-Credential -Message "Please enter Office365 Credentials (e.g. username@accruent.com)"

#Email "From" variable
$Sender = $Cred.UserName

#Connect to Exchange Online
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $Cred -Authentication Basic -AllowRedirection

Import-PSSession $ExchangeSession -AllowClobber

#Clear out variable
$EmailBody = "" 

#Email "From" variable
$Sender = $Cred.UserName

#####################################################################################################
################################# New Test Code #####################################################


foreach ($User in $Users)
   {
   $UID = $user.username
   $Message = $user.message
   $AccName = (Get-ADUser -Identity $UID -Properties Name).name
        
   Set-MailboxAutoReplyConfiguration -Identity $UID -AutoReplyState Enabled -DeclineAllEventsForScheduledOOF $true -ExternalAudience All -ExternalMessage $Message -InternalMessage $Message
   
   #Creates array to write out Full Name, Username, and Email Address for each user in CSV, to add to email notification body
   $EmailBody += "<br><b>User:</b> $AccName <br><b>Message:</b><br> $Message <br>"
   
   }



#####################################################################################################



#New Hire Created Email
Send-MailMessage -To $Sender -From $Sender -Subject "INFO | User Auto-Reply Set" -Body "The specified script has been configured for the Auto-Reply on the following users:<br> $EmailBody <br>Please double check to ensure it was configured properly." -BodyAsHtml -Credential $Cred -SmtpServer smtp.office365.com -UseSsl   

Remove-PSSession $ExchangeSession

Write-Host "Press any key to continue ..."

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")