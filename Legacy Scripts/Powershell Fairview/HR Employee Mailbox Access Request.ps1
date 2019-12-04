#Who is running this script?
$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
$fromAddress = ([ADSI]$sidbind).mail.tostring()

#Get Name of Users
$RequestedMailboxInput = Read-Host -Prompt "Requested Mailbox"
$Requestor = Read-Host -Prompt "Who should gain Access to this mailbox?"
$HRUser = Read-Host -Prompt "HR Member listed in Ticket"

#Assign Mailbox Permissions
$RequestedMailbox = Get-Mailbox -Identity $RequestedMailboxInput
$RequestedMailboxDisplayName = $RequestedMailbox.DisplayName
Add-MailboxPermission -AccessRights FullAccess -User $Requestor -AutoMapping $true

#Send Email to end user
$EmailBody = "<p>Hello, $Requestor<br /><br /></p>
<p>You have been given full rights to the $RequestedMailboxDisplayName</p>
<p>It Should appear automatically in the left pane of Outlook.&nbsp;<br />if If it does not appear within a few minutes, Please close outlook and re-open it again.</p>
<p>If you wish to change how new email messages are read, you can do so by following the steps below. This is helpful if this mailbox will be shared by others.&nbsp;</p>
<ol type='1>
<li>
<p>Select&nbsp;<strong class='ocpUI'>File</strong>&nbsp;&gt;&nbsp;<strong class='ocpUI'>Options</strong>&nbsp;&gt;&nbsp;<strong class='ocpUI'>Advanced</strong>.</p>
<p><img style='box-sizing: border-box; border: none; max-width: 100%;' src='https://support.content.office.net/en-us/media/aa79231c-d288-45af-8820-fda200da367e.jpg' alt='File &gt; Options &gt; Advanced' /></p>
</li>
<li>
<p>Under&nbsp;<strong class='ocpUI'>Outlook panes</strong>, select&nbsp;<strong class='ocpUI'>Reading Pane</strong>.<br /><br /><img src='https://support.content.office.net/en-us/media/87e84e17-f47f-4793-a601-f6b38d59c279.png' alt='You can change the Reading Pane options.' /></p>
</li>
</ol>
<p>&nbsp;</p>
<p>If you have any questions, please call the TSC at 612-672-6805.</p>
<p>Thank you,</p>
<p>Fairview IT</p>"

#Send Email
Send-MailMessage -To $usr.Identity -Bcc $fromAddress -From $fromAddress -Body $EmailBody -BodyAsHtml -SmtpServer smtp-relay1.fairview.org -Subject "New Lync Access"