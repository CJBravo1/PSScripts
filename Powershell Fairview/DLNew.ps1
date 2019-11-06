#Silence Warning Messages
#$WarningPreference = Continue

#Import Exchange Modules
#add-pssnapin Microsoft.Exchange.Management.PowerShell.E2010 -WarningAction SilentlyContinue
#$Exchange = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://EXCH-PRIMARY-1.Fairview.org/powershell
#Import-PSSession $Exchange

#Get New Distribution Group Info
import-csv "Q:\IS-Shares\Sharedir\CommunicationServices\Messaging\Input Files\DLNew.csv" | foreach{
$DisplayName = $_.Display
$Owner = $_.User

#Does the Distribution Group already exist?
$Testing = Get-DistributionGroup $DisplayName -ErrorAction SilentlyContinue

if ($Testing -ne $null) {Write-Host "$DisplayName already exist as a distribution Group." -ForegroundColor Yellow -BackgroundColor Red}
else {
New-DistributionGroup -NAME $_.DISPLAY -DISPLAYNAME $_.DISPLAY -SAM $_.DISPLAY -OrganizationalUnit Fairview.org/Exchange/Groups -Type Distribution -ManagedBy $_.user 

#Who is running this script? Get Local User's Email Address
$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
$fromAddress = ([ADSI]$sidbind).mail.tostring()

#Write Email
Write-Host "Sending Email to $Owner" -ForegroundColor Green
$EmailBody = "
<p>The Distribution Group $DisplayName has been created and you are now the owner of it.&nbsp;</p>
<p>&nbsp;</p>
<p>To add people to this group, follow these steps in Outlook:</p>
<ul>
<li>Open up the Outlook Address book and find the group name</li>
<li>Right click on the name and select properties</li>
<li>Click on the modify members button at the bottom right of the screen under the white box</li>
<li>Click on the Add button on the right of the window</li>
<li>The address book will open and you can select people who need to be members of this group.</li>
<li>Click on the Add button and all the names should show up in the display line.</li>
<li>Click on OK</li>
<li>Click on OK</li>
<li>Click on Apply</li>
</ul>
<p>All people that you have added to should now appear in the white box displaying group members.</p>
<p>&nbsp;</p>
<p>To delete people, follow these steps:</p>
<ul>
<li>Open up the Outlook Address book and find the group name</li>
<li>Right click on the name and select properties</li>
<li>Click on the modify members button at the bottom right of the screen under the white box</li>
<li>Click on the name of the person that you want to remove so they get highlighted</li>
<li>Click on Remove</li>
<li>Click on OK</li>
<li>Click on OK</li>
<li>Click on Apply</li>
</ul>
<p>&nbsp;</p>
<p>If you have any questions, please call the TSC at 612-672-6805.</p>
<p>&nbsp;</p>
<p>Thank you,</p>
<p>&nbsp;</p>
<p>Fairview IT</p>"

#Send Email
Send-MailMessage -To $owner"@fairview.org" -Bcc $fromAddress -From $fromAddress -Body $EmailBody -BodyAsHtml -SmtpServer smtp-relay1.fairview.org -Subject "New Distribution Group"}
}