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

#Get New Mailbox Info
Write-Host "Gathering Info From CSV" -ForegroundColor Cyan
Import-CSV "Q:\IS-Shares\Sharedir\CommunicationServices\Messaging\Input Files\NewEmailAccount.csv" | ForEach{
$Name = $_.Display
$Owner = $_.OwnerID
$SAM = $_.Sam
$Database = $_.DB
$Office = $_.Office
$type = $_.Type

Write-Host "Creating Mailbox" -ForegroundColor Green
New-Mailbox -NAME $_.DISPLAY -LastName $_.display -Alias $_.Sam -OrganizationalUnit Fairview.org/Exchange/Resources -Database $_.DB -Shared


Echo " "
Write-Host "Pausing for AD replication" -ForegroundColor Cyan
Start-Sleep -Seconds 20

#Import-CSV .\NewEmailAccount.csv | ForEach{
Write-Host "Assigning Retention Policy to Mailbox" -ForegroundColor Cyan
Set-Mailbox -identity $Name -RequireSenderAuthenticationEnabled:$true -RetentionPolicy "FV Standard 180 Day Retention" -SingleItemRecoveryEnabled $true

Set-User -identity $Name -Office $Office
Write-Host "Assigning Ownership to Mailbox" -ForegroundColor Cyan
Add-MailboxPermission -Identity $Name -User $Owner -AccessRights FullAccess -InheritanceType All

switch ($type) {
    Calendar
    {
#Write Email
$EmailBody = "<p>The following account or accounts have been created and you are the Owner:</p>
<p>&nbsp;</p>
<p>$Name</p>
<p>&nbsp;</p>
<ul>
<li>As the Owner, you should see the mailbox in your Outlook folder list the next time you restart Outlook.</li>
</ul>
<p>&nbsp;</p>
<ul>
<li>You can grant permissions to the<strong> Calendar</strong> to others by following these steps:</li>
</ul>
<ul>
<li>Click on the Folder List Icon at the bottom of your folder list.</li>
<li>Right click on the folder you need to grant permissions to</li>
<li>Go to Properties</li>
<li>Go to&nbsp;Permissions</li>
<li>Click on Add</li>
<li>Put in the person you are granting access to</li>
<li>Click on the permission level you want that person to have.</li>
<li>Click on apply</li>
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
<p>Create, read, modify, and delete all Items, and create subfolders. As the folder owner, you can change the permission levels others have for the folder. (Does not apply to delegates.)</p>
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
<ul>
<li>After you have granted their permissions, they can add this to their calendar list by going to Calendar, Open Calendar, Open a Shared calendar and enter the name.</li>
</ul>
<p>&nbsp;</p>
<ul>
<li>If others have a need to manage the Inbox for the calendar or other folders you would also need to add their permissions to the top level Mailbox folder and Inbox folder, then they can add the mailbox to the Outlook folder list by following the steps below.</li>
</ul>
<p>&nbsp;</p>
<p><strong>In Outlook 2010</strong></p>
<p>To add this folder to your mail list, follow these steps:</p>
<ul>
<li>Go to <strong>File</strong>, <strong>Info</strong>, <strong>Account Settings</strong>, <strong>Account Settings</strong></li>
<li>Make sure Microsoft Exchange is highlighted and click on <strong>Change</strong>.</li>
<li>Click on <strong>More Settings</strong> in the bottom right of the window</li>
<li>Go to the <strong>Advanced </strong>tab</li>
<li>Click on the,&nbsp;<strong>Add </strong>button</li>
<li>Type the name of the account you would like to added to your mail folders.&nbsp; The name should be in the text box and be underlined if it is correct.</li>
<li>Click on OK</li>
<li>Click on OK</li>
<li>Click on Next</li>
<li>Click on Finish</li>
</ul>
<p>It should now show up in your Mail Folder lists as another Mailbox for that account</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>If you have any questions, please call the TSC at 612-672-6805.</p>
<p>&nbsp;</p>"



    }
    
    Shared
    {
    $EmailBody = "<p>You are now the owner of the accounts called <strong>$Name.</strong></p>
<p>Since you now have full access to the account, it should show up in the left pane of your Outlook within a few minutes. If not, simply close Outlook and open back up.</p>
<p><strong>You can grant permissions to the Mailbox folder and the Inbox as needed by following these steps: </strong></p>
<p></p>
<p><strong>(Rights will need to be given to the topmost Mailbox folder for others to see the inbox, calendar and other folders in the account. Rights also need to be assigned to each folder that you want them to have access to (i.e. Inbox, Calendar, etc.))</strong></p>
<ul>
<li>Click on the Folder List Icon at the bottom of your folder list.</li>
<li>Right click on the folder you need to grant permissions to</li>
<li>Go to Properties</li>
<li>Go to&nbsp;Permissions</li>
<li>Click on Add</li>
<li>Put in the person you are granting access to</li>
<li>Click on the permission level you want that person to have.</li>
</ul>
<table>
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
<p>Create, read, modify, and delete all items&nbsp;(item: An item is the basic element that holds information in Outlook (similar to a file in other programs). Items include e-mail messages, appointments, contacts, tasks, journal entries, notes, posted items, and documents.) and files, and create subfolders. As the folder owner, you can change the permission levels others have for the folder. (Does not apply to delegates.)</p>
</td>
</tr>
<tr>
<td>
<p>Publishing Editor</p>
</td>
<td>
<p>Create, read, modify, and delete all items and files, and create subfolders. (Does not apply to delegates.)</p>
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
<p>Publishing Author</p>
</td>
<td>
<p>Create and read items and files, create subfolders, and modify and delete items and files you create. (Does not apply to delegates.)</p>
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
<p>Contributor</p>
</td>
<td>
<p>Create items and files only. The contents of the folder do not appear. (Does not apply to delegates.)</p>
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
<p>Custom</p>
</td>
<td>
<p>Perform activities defined by the folder owner. (Does not apply to delegates.)</p>
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
<p></p>
<p>If other people would like to add this account to the left pane of their Outlook after you give them the proper rights, then send them the steps listed below:</p>
<p></p>
<p></p>
<p><strong>Windows 7 (Outlook 2010) - To add this folder to your mail list follow these steps:</strong></p>
<ul>
<li>File/Account Settings/Account Settings</li>
<li>Double-click on your email address in the &ldquo;name&rdquo; column</li>
<li>Click on &ldquo;More Settings&rdquo; in the bottom right of the window</li>
<li>Go to &ldquo;Advanced&rdquo; tab</li>
<li>Click on &ldquo;Add&rdquo;</li>
<li>Type in the name of the account you want to have added to your&nbsp;mail folders (XXX) and click &ldquo;OK&rdquo;. The name should in the text box and be underlined if it is correct.</li>
<li>Click on &ldquo;OK&rdquo;</li>
<li>Click on &ldquo;Next&rdquo;</li>
<li>Click on &ldquo;Finish&rdquo;</li>
<li>Click on &ldquo;Close&rdquo;</li>
</ul>
<p>It should now show up in the left pane of Outlook.</p>
<p>If you have any questions, please call the TSC at 612-672-6805.</p>
<p>Thank you,</p>
<p>Fairview IT</p>"


    }
}
Write-Host "Sending Email to $owner" -ForegroundColor Cyan
Send-MailMessage -To $owner"@fairview.org" -Bcc $fromAddress -From $fromAddress -Body $EmailBody -BodyAsHtml -SmtpServer smtp-relay1.fairview.org -Subject "New $type Mailbox"
}
