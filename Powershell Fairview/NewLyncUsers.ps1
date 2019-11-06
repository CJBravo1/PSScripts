#Create New Lync Accounts

#Who is running this script?
$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
$fromAddress = ([ADSI]$sidbind).mail.tostring()

#Gather Credentials
#Write-Host "Enter your Fairview Credentials" -ForegroundColor Yellow
#$creds = Get-Credentials $windowsIdentity.Name

#Connect to Modules
#$Exchange = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://EXCH-PRIMARY-1.Fairview.org/powershell
#$lync = New-PSSession -ConnectionUri https://lyncfe1.fairview.org/ocspowershell -Name Microsoft.Lync -Credential $creds -WarningAction SilentlyContinue

#Import PS Sessions
#Write-Host "Connecting to Exchange" -ForegroundColor Green
#Import-PSSession $Exchange -WarningAction SilentlyContinue | out-null
#Write-Host "Connecting to Lync" -ForegroundColor Green
#Import-PSSession $lync -WarningAction SilentlyContinue | out-null


# Get phone number extension from file
$Telephone = Import-Csv "Q:\IS-Shares\Sharedir\CommunicationServices\Messaging\Input Files\Lync\DoNotTouch\TelephoneExtension.csv"
$ext = $Telephone.extension
$ext = [int]$ext



# Get list of new users to setup for Lync
Write-Host "Gathering Users from CSV" -ForegroundColor Cyan
$usercsv = Import-Csv "Q:\IS-Shares\Sharedir\CommunicationServices\Messaging\Input Files\Lync\NewLyncUsers.csv"
ForEach ($usr in $usercsv)
{
# Enable user for Lync
Enable-CsUser -Identity $usr.Identity -RegistrarPool lyncpoola.fairview.org -SipAddressType SAMAccountName -SipDomain fairview.org 
Write-Host "	The user " $usr.Identity " enabled for LS2013 "
}

Echo ""
Write-Host "New accounts have been created. Pausing for AD replication." -ForegroundColor Cyan
Echo ""

Start-Sleep -Seconds 25

# Get list of users to setup for Lync
$usercsv = Import-Csv "Q:\IS-Shares\Sharedir\CommunicationServices\Messaging\Input Files\Lync\NewLyncUsers.csv"
ForEach ($usr in $usercsv)
{

# Assign Conferencing policy 
Grant-CsConferencingPolicy -Identity $usr.Identity -PolicyName "Allow A_V conferencing 1"

# Assign external access policy
Grant-CsExternalAccessPolicy -Identity $usr.Identity -PolicyName "Allow Federation+Public+Outside Access"

# Add sequential phone number received from file

$enabledUsers = Get-CsADUser -Identity $usr.Identity

 
foreach ($user in $enabledUsers)

	{ 
	
        $phonenumber = "TEL:+16123138777;ext=" + $ext

	echo "The phone number $phonenumber will be entered into Lync for " $user.identity 
		

        Set-CsUser -Identity $user.Identity -LineUri $phoneNumber -ErrorVariable Err
	if ($Err) {$ext = $ext - 1}
	$ext = $ext + 1

# create an array and save current telephone extension to it. Then save to file.
$OutArray = @()
$Phone = "" | select "Extension"
$Phone.extension = $ext
$OutArray += $Phone
$OutArray | export-csv "Q:\IS-Shares\Sharedir\CommunicationServices\Messaging\Input Files\Lync\DoNotTouch\TelephoneExtension.csv" -notype


#Send Email to End User via HTML
$EmailBody = '
<p>You are now setup for Lync and have the ability to instant message, share your desktop or multiple monitors, present applications or PowerPoint presentations and schedule a Lync meeting via Outlook with complete audio\video options including the option for people to dial in using a standard phone. All Lync accounts have the ability to set a PIN that can be used for audio conferencing.</p>
<p>&nbsp;</p>
<p><strong><u>Get Started with Lync 2013 (Windows 7)</u></strong></p>
<ol>
<li>First, open Lync 2013</li>
<ol>
<li>Click &ldquo;Start&rdquo; button in the lower left</li>
<li>Click &ldquo;All Programs&rdquo;</li>
<li>Click &ldquo;Office Tools&rdquo;</li>
<li>Click &ldquo;Lync 2013&rdquo; (If not found, see &ldquo;How to Install Lync 2013&rdquo; below)</li>
<li>If prompted for a Sign-In Address, then enter your Fairview email address</li>
</ol>
<li>Quick reference cards can be printed from here: Q:\IS-Shares\Programs\Lync2013</li>
<li>Link to online help (the calling features listed are not available to Fairview), <a href="https://support.office.com/en-us/article/Basic-tasks-in-Lync-2013-5f5e799c-88ea-4485-a890-b42abe7f0f35?ui=en-US&amp;rs=en-US&amp;ad=US">Lync 2013 Online help</a></li>
</ol>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p><strong><u>How to Install Lync 2013</u></strong></p>
<ol>
<li>Click &ldquo;Start&rdquo; button in the lower left</li>
<li>Click &ldquo;All Programs&rdquo;</li>
<li>Click &ldquo;Application Catalog&rdquo;</li>
<li>In the upper left type &ldquo;Lync&rdquo; in the search window and hit &lsquo;Enter&rsquo;</li>
<li>Highlight &ldquo;Lync 2013&rdquo;</li>
<li>Click &ldquo;Install&rdquo; button in the lower right</li>
<li>When prompted to install, click &ldquo;Yes&rdquo;</li>
<li>Once installation is complete, follow the steps above in the &ldquo;Get Started with Lync 2013&rdquo;&nbsp;</li>
</ol>
<p><strong><u>&nbsp;</u></strong></p>
<p><strong><u>Do I need a PIN to start a Lync Meeting?&nbsp; </u></strong></p>
<p>You only need a PIN if you are the leader (Organizer) of the meeting, and calling from a regular phone. The preferred method for joining a Lync meeting is to use the &ldquo;Join Lync Meeting&rdquo; link in the calendar item and then using the &ldquo;Call me At&rdquo; option for entering the conference or other phone number you will be using for audio. When using the &ldquo;Join Lync Meeting&rdquo; link, a PIN is never needed for a typical Lync call or conference.</p>
<p>If you need to set your PIN for the first time or cannot remember it, click &ldquo;Forgot your Dial-in PIN&rdquo; in the meeting request and follow the instructions on the page to reset.</p>
<p>If you have any further questions please call the TSC at 612-672-6805.</p>
<p>Thank you,</p>
<p>Fairview IT</p>
<p>&nbsp;</p>'
Write-Host "Emailing " $usr.Identity -foregroundColor Green
Send-MailMessage -To $usr.Identity -Bcc $fromAddress -From $fromAddress -Body $EmailBody -BodyAsHtml -SmtpServer smtp-relay1.fairview.org -Subject "New Lync Access"


	} 
}


Echo ""
Write-Host "New accounts are now setup." -ForegroundColor Yellow

Echo ""


