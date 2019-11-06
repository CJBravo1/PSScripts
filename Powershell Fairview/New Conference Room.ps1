#Import Exchange Modules
#add-pssnapin Microsoft.Exchange.Management.PowerShell.E2010 -WarningAction SilentlyContinue

#Who is running this script? Get Local User's Email Address
$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
$fromAddress = ([ADSI]$sidbind).mail.tostring()

#Connect to Modules
#$Exchange = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://EXCH-PRIMARY-1.Fairview.org/powershell

#Import PS Sessions
#Write-Host "Connecting to Exchange" -ForegroundColor Green
#Import-PSSession $Exchange -WarningAction SilentlyContinue

Write-Host "Creating Mailboxes" -ForegroundColor Cyan
Import-CSV "Q:\IS-Shares\Sharedir\CommunicationServices\Messaging\Input Files\NewCRAccount.csv" | ForEach{
#Create Variables
$Display = $_.Display
$Alias = $_.SAM
$Database = $_.DB
$Owner = $_.OwnerID
$Acceptance = $_.Acceptance

New-Mailbox -NAME $Display -LastName $Display -Alias $Alias -OrganizationalUnit Fairview.org/Exchange/Resources -Database $Database -Room}

Echo " "
Write-Host "Pausing for AD replication"
Start-Sleep -Seconds 20

import-csv "Q:\IS-Shares\Sharedir\CommunicationServices\Messaging\Input Files\NewCRAccount.csv" | foreach{

    Write-Host "Assigning Mailbox Permissions" -ForegroundColor Cyan
    Set-Mailbox -identity $_.DISPLAY -RequireSenderAuthenticationEnabled:$true -RetentionPolicy "FV Standard 180 Day Retention" -SingleItemRecoveryEnabled $true

    Set-User -identity $_.DISPLAY -Office $_.Office

    Add-MailboxPermission -Identity $_.DISPLAY -User $_.OwnerID -AccessRights FullAccess -InheritanceType All

    #Set Calendar Processing
    Switch ($Acceptance) {
        Auto{
        Set-CalendarProcessing -Identity $Display -AutomateProcessing:AutoAccept -AllBookInPolicy:$True -AllRequestOutOfPolicy:$False -AllRequestInPolicy:$False -AllowConflicts:$False -BookingWindowInDays:730  -ConflictPercentageAllowed:5 -MaximumConflictInstances:25 -DeleteSubject:$False -AddAdditionalResponse:$True -AdditionalResponse:"Please contact the owner of the room to report any problems.”
        $EmailBody = "
<p>You are now the Owner of the following conference rooms:&nbsp; My coworker has the task for the other conference room.</p>
<p>&nbsp;</p>
<p>$Display</p>
<p>&nbsp;</p>
<ul>
<li>As the Owner, the account\accounts should appear in your Outlook folder list in the next 15-20 minutes.</li>
<li>People can see free\busy information and schedule the room by adding it as a Room on a New Meeting Request.&nbsp;</li>
<li>Appointments will automatically be accepted or declined based on availability.</li>
<li>If people need to view or edit the calendar you can grant them permissions by following these steps:
<ol>
<li>Right click on the calendar you need to grant permissions to.</li>
<li>Go to Properties</li>
<li>Go to&nbsp;Permissions</li>
<li>Click on Add</li>
<li>Put in the person you are granting access to</li>
<li>Click on the permission level you want that person to have (See the permission level chart below).</li>
<li>Click on apply</li>
</ol>
</li>
<li>After you have granted their permissions, they can add this to their calendar list by going to Calendar, Open Calendar, Open a Shared calendar and enter the name.</li>
</ul>
<p>&nbsp;</p>
<p>&nbsp;</p>
<table width='630'>
<tbody>
<tr>
<td>
<p><strong>With this permission level (or role)</strong></p>
</td>
<td>
<p><strong>You can</strong></p>
</td>
</tr>
<tr>
<td>
<p>Owner</p>
</td>
<td>
<p>Create, read, modify, and delete all <a href='https://mail.fairview.org/owa/UrlBlockedError.aspx'>items&nbsp;(item: An item is the basic element that holds information in Outlook (similar to a file in other programs). Items include e-mail messages, appointments, contacts, tasks, journal entries, notes, posted items, and documents.)</a> and files, and create subfolders. As the folder owner, you can change the permission levels others have for the folder. (Does not apply to delegates.)</p>
</td>
</tr>
<tr>
<td>
<p>Editor</p>
</td>
<td>
<p>Create, read, modify, and delete all items and files.</p>
</td>
</tr>
<tr>
<td>
<p>Author</p>
</td>
<td>
<p>Create and read items and files, and modify and delete items and files you create.</p>
</td>
</tr>
<tr>
<td>
<p>Reviewer</p>
</td>
<td>
<p>Read items and files only.</p>
</td>
</tr>
<tr>
<td>
<p>None</p>
</td>
<td>
<p>You have no permission. You can't open the folder.</p>
</td>
</tr>
</tbody>
</table>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>If you have any questions, please call the TSC at 612-672-6805.</p>
<p>&nbsp;</p>
<p>Thank you,</p>
<p>Fairview IT</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>








.rTable { display: table; width: 100%;}
.rTableRow { display: table-row; }
.rTableHeading { background-color: #ddd; display: table-header-group; }
.rTableCell, .rTableHead { display: table-cell; padding: 3px 10px; border: 1px solid #999999; }
.rTableHeading { display: table-header-group; background-color: #ddd; font-weight: bold; }
.rTableFoot { display: table-footer-group; font-weight: bold; background-color: #ddd; }
.rTableBody { display: table-row-group; }"

#Send Email
Write-Host "Sending Email to $owner" -ForegroundColor Cyan
Send-MailMessage -To $owner"@fairview.org" -Bcc $fromAddress -From $fromAddress -Body $EmailBody -BodyAsHtml -SmtpServer smtp-relay1.fairview.org -Subject "New Conference Room Mailbox"
        }

        Manual{
        Set-CalendarProcessing -Identity $Display -AutomateProcessing:AutoUpdate -AllBookInPolicy:$True -AllRequestOutOfPolicy:$False -AllRequestInPolicy:$False -AllowConflicts:$False -BookingWindowInDays:730  -ConflictPercentageAllowed:5 -MaximumConflictInstances:25 -DeleteSubject:$False -AddAdditionalResponse:$True -AdditionalResponse:"Please contact the owner of the room to report any problems.”
        $EmailBody = "
        <p>You are now the Owner of the following new account\accounts or Ownership of an existing account\accounts has been transferred to you:</p>
<p>&nbsp;</p>
<p>$Display</p>
<p>&nbsp;</p>
<ul>
<li>As the Owner, the account\accounts should appear in your Outlook folder list in the next 15-20 minutes.</li>
<li>Everyone can see the free\busy information and schedule the room by adding it as a Room on a New Meeting Request.&nbsp;</li>
<li>As the Owner, you will need to manually accept or decline these appointment requests from the conference room Inbox.</li>
<li>If people need to view or edit the calendar you can grant them permissions by following these steps:
<ol>
<li>Right click on the calendar you need to grant permissions to.</li>
<li>Go to Properties</li>
<li>Go to&nbsp;Permissions</li>
<li>Click on Add</li>
<li>Put in the person you are granting access to</li>
<li>Click on the permission level you want that person to have (See the permission level chart below)</li>
<li>Click on apply</li>
</ol>
</li>
<li>After you have granted their permissions, they can add this to their calendar list by going to Calendar, Open Calendar, Open a Shared calendar and enter the name.</li>
</ul>
<p>&nbsp;</p>
<p>&nbsp;</p>
<table width='630'>
<tbody>
<tr>
<td>
<p><strong>With this permission level (or role)</strong></p>
</td>
<td>
<p><strong>You can</strong></p>
</td>
</tr>
<tr>
<td>
<p>Owner</p>
</td>
<td>
<p>Create, read, modify, and delete all <a href='https://mail.fairview.org/owa/UrlBlockedError.aspx'>items&nbsp;(item: An item is the basic element that holds information in Outlook (similar to a file in other programs). Items include e-mail messages, appointments, contacts, tasks, journal entries, notes, posted items, and documents.)</a> and files, and create subfolders. As the folder owner, you can change the permission levels others have for the folder. (Does not apply to delegates.)</p>
</td>
</tr>
<tr>
<td>
<p>Editor</p>
</td>
<td>
<p>Create, read, modify, and delete all items and files.</p>
</td>
</tr>
<tr>
<td>
<p>Author</p>
</td>
<td>
<p>Create and read items and files, and modify and delete items and files you create.</p>
</td>
</tr>
<tr>
<td>
<p>Reviewer</p>
</td>
<td>
<p>Read items and files only.</p>
</td>
</tr>
<tr>
<td>
<p>None</p>
</td>
<td>
<p>You have no permission. You can't open the folder.</p>
</td>
</tr>
</tbody>
</table>
<p>&nbsp;</p>
<ul>
<li>If others have a need to manage the Inbox folder for a calendar you would also need to add their permissions to the top level Mailbox folder and Inbox folder, then they can add the mailbox to the Outlook folder list by following the steps below.</li>
</ul>
<p>&nbsp;</p>
<p><strong>In Outlook 2010</strong></p>
<p>To add this folder to your mail list, follow these steps:</p>
<ol>
<li>Go to <strong>File</strong>, <strong>Info</strong>, <strong>Account Settings</strong>, <strong>Account Settings</strong></li>
<li>Make sure Microsoft Exchange is highlighted and click on <strong>Change</strong>.</li>
<li>Click on <strong>More Settings</strong> in the bottom right of the window</li>
<li>Go to the <strong>Advanced </strong>tab</li>
<li>Click on the&nbsp;Add button</li>
<li>Type the name of the account you would like to added to your mail folders.&nbsp; The name should be in the text box and be underlined if it is correct.</li>
<li>Click on OK</li>
<li>Click on OK</li>
<li>Click on Next</li>
<li>Click on Finish</li>
</ol>
<p>It should now show up in your Mail Folder lists as another Mailbox for that account</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>If you have any questions, please call the TSC at 612-672-6805.</p>
<p>&nbsp;</p>
<p>Thank you,</p>
<p>Fairview IT</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>"

#Send Email
Write-Host "Sending Email to $owner" -ForegroundColor Cyan
Send-MailMessage -To $owner"@fairview.org" -Bcc $fromAddress -From $fromAddress -Body $EmailBody -BodyAsHtml -SmtpServer smtp-relay1.fairview.org -Subject "New Conference Room Mailbox"
    }
}
}

Echo - "New accounts have been created.  Ok to close window"
