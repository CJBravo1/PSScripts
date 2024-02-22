#Offboarding Script to disable user accounts, forward emails to manager, convert mailbox to shared, grant manager access to calendar, remove licenses, and grant manager access to OneDrive
#Search for "DOMAIN.com" to change to your domain
#Change Email address variables to your email addresses
#Change Sharepoint variables to your Sharepoint URL

#Script Variables
#License Variables
$enterprisepack = (Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq "ENTERPRISEPACK"}).SKuId
$INTUNE_A_D = (Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq "INTUNE_A_D"}).SKuId
$date = Get-Date
$ftrdate = $date.ToString("MM/dd/yyyy")
$emailFROM = 'emailFROM@DOMAIN.com'
$emailTO = 'emailTO@Domain.com'

#Sharepoint Variables
$SharePointAdminURL = "https://DOMAIN-admin.sharepoint.com/"
$SharepointURL = "https://DOMAIN-my.sharepoint.com/personal/"
$sharepointDomain = "_DOMAIN_com"

#Userproperties
$Userproperties = @(
    'AccountEnabled',
    'DisplayName',
    'id',
    'mail',
    'mailnickname',
    'UserPrincipalName')


#Connect to Graph
Write-Output "Connecting to Microsoft Graph"
Connect-MgGraph -Scopes "AccessReview.ReadWrite.Membership","AccessReview.ReadWrite.All","Mail.Send","AuditLog.Read.All"

#Connect to Exchange Online
Write-Output "Connecting to Exchange Online" 
Connect-ExchangeOnline 

#Audit Log Variables
$Today = Get-Date -DisplayHint Date
Write-Output "Gathering Audit Logs"
$MGAuditDisabledAccounts = Get-MgAuditLogDirectoryAudit | Where-Object {$_.ActivityDateTime.ToString("MM-dd-yyyy") -eq $Today.ToString("MM-dd-yyyy") -and $_.ActivityDisplayName -eq "Disable Account"}

#Confirm Disabled Users
Write-Output "The below users have been disabled today, confirm these are the correct users before proceeding"
$MGAuditDisabledAccounts.TargetResources.UserPrincipalName
Pause

#Start foreach loop
$ExportData = @()
Foreach ($log in $MGAuditDisabledAccounts)
{
    #Gather Logs for User
    $LogTargetUser = $log.TargetResources.Id
    
    #User Variables
    Write-Output "Gathering User Data for "$mgUsername
    $mgUser = Get-MgUser -UserId $LogTargetUser -Property $Userproperties
    $mguserID = $mgUser.id
    $userName = $mgUser.DisplayName
    $mgUsername = $mgUser.DisplayName
    $mgUserNickname = $mguser.MailNickname
    $userMailbox = Get-Mailbox -Identity $mgUser.UserPrincipalName
    $userMailboxPrimarySMTPAddress = $userMailbox.primarySMTPAddress
    $mguserlicense = Get-MgUserLicenseDetail -UserId $mgUser.Id
    $mgUserNickname = $mgUserNickname.Replace(".","_")
    $SPOneDriveURL = $SharepointURL + $mgUserNickname + $sharepointDomain
    

    #Manager Variables
    Write-Output "Gathering Manager Data for "$mgUsername
    $managerCall = Get-MgUserManager -UserId $MgUserId
    $managerCall = get-mguser -UserId $managerCall.id
    $managerName = $managerCall.DisplayName
    $managerMail = $managerCall.mail
   
    #Audit Log Check
    Write-Output "Gathering Audit Logs"
    $MGAuditDisabledAccountTarget = $MGAuditDisabledAccounts.TargetResources.Id
    $MGAuditDisableTimeStamp = $MGAuditDisabledAccounts | Where-Object {$_.TargetResources.Id -eq $mguserID} | Select-Object ActivityDateTime
    $MGAuditCheck = $MGAuditDisabledAccountTarget | Where-Object {$_ -eq $mguserID}
    $MGAuditTimeStamp = $MGAuditDisableTimeStamp.ActivityDateTime.ToString("MM-dd-yyyy")

    #Start of Functions
    function Offboard-Mailbox {
        #Forward to Manager
        Write-Output "Forwarding to $MgUserId's mailbox to "$managerName "(Manager)"
        Set-Mailbox -Identity $userMailbox -DeliverToMailboxAndForward $true -ForwardingSMTPAddress $managerMail

        #Convert to Shared Mailbox
        if ($userMailbox.RecipientTypeDetails -ne "SharedMailbox") 
        {
            Set-Mailbox -Identity $MgUserId -Type Shared
            Get-Mailbox -Identity $MgUserId  | Format-List DisplayName,RecipientTypeDetails
        }
        else {Write-Output "$mgUsername's mailbox is already a shared mailbox" }

        #Grant Manager Access to Calendar
        Write-Output "`nGranting $MgUserId's Calendar access to $managerName"
        $MgUserIdalendar = $MgUserId + ":\Calendar"
        Add-MailboxFolderPermission -Identity $MgUserIdalendar -User $managerMail -AccessRights Editor
        start-sleep -Seconds 10

        #Output Changes
        Write-Output "`nChanges made to $MgUserId's mailbox"
        Get-Mailbox -Identity $userMailbox | Format-Table DisplayName,RecipientTypeDetails,ForwardingSmtpAddress,DeliverToMailboxAndForward
        Get-MailboxFolderPermission -Identity $MgUserIdalendar | Format-Table User,AccessRights       
    }

    function Grant-OneDriveOwnership 
    {
        #Connect to SharePoint Online
        Write-Output "Connecting to SharePoint Online"
        Connect-PnPOnline -ManagedIdentity -Url $SharePointAdminURL
        #Give Site Collection Admin
        Write-Output "`nGranting $MgUserId's OneDrive access to $managerName"
        Set-PnPTenantSite -Identity $SPOneDriveURL -Owners $managerMail
        Write-Output "Disconnecting from Sharepoint"
        Disconnect-PnpOnline
    }

    function Offboard-License 
    {
        param (
            [Parameter(Mandatory=$true)]
            [string]$mguserID
        )
        
        #Remove Microsoft Licenses
        #Remove E3 License
        if ($null -ne ($mguserlicense | Where-Object {$_.SkuId -eq $enterprisepack}))
        {
            Write-Output "Removing E3 License from $mgUsername"
            Set-MgUserLicense -UserId $mgUser.id -AddLicenses @() -RemoveLicenses $enterprisepack    
        }
        else 
        {
            Write-Output "E3 License already removed from $mgUsername"
        }

        #Remove Intune License
        if ($null -ne $($mguserlicense | Where-Object {$_.SkuId -eq $INTUNE_A_D}))
        {
            Write-Output "Removing Intune License from $mgUsername"
            Set-MgUserLicense -UserId $mgUser.id -AddLicenses @() -RemoveLicenses $INTUNE_A_D
        }
        else    
        {
            Write-Output "Intune License already removed from $mgUsername"
        }
                
    }
    
        function Email-Manager 
        {
        param (
            [Parameter(Mandatory=$true)]
            [string]$userMailbox
        )
        #Email specifications that's going to be sent out.
        $params = @{
            Message = @{
                Subject = "Offboarding Employee Email & Calendar: $mgUsername"
                Body = @{
                    ContentType = "HTML"
                    Content = "<p>Hello,</p>
                    <p>We&#39;re in the process of offboarding $userName and want to provide the Email and Calendar access associated to their account.</p>
                    <p>This includes:</p>
                    <ul>
                    <li><strong>Forwarding emails to your inbox ($userMailboxPrimarySMTPAddress -> $managerMail)</strong></li>
                    <li><strong>Granted editor access to $userName&#39;s calendar (Instructions can be found here</strong></li>
                    <li><strong>Access to OneDrive: <a href=$SPOneDriveURL> HERE</a></li>
                    </ul>
                    <p>The user&#39;s account will be active for 30 days <em><strong>($ftrdate)</strong></em> and then their account will be purged.</p>
                    <p>&nbsp;</p>
                    <p>&nbsp;</p>
                    <p>-IT Team</p>"
                }
                ToRecipients = @(
                    @{
                        EmailAddress = @{
                            Address = $managerMail
                        }
                    }
                )
                
            }
            
        }
    
        Write-Output "Sending Email to $managerMail"
        Send-MgUserMail -UserId $emailFROM -BodyParameter $params
        }
    
    #Start of Script
    Write-Output "Starting Offboarding Process for $mgUsername"
    #Run Functions
    Offboard-Mailbox
    Grant-OneDriveOwnership
    Offboard-License -mgUserid $mguserID
    Email-Manager -userMailbox $userMailbox
    
    #Final Checks
    #Mailbox Check
    $FinaluserMailbox = Get-Mailbox -Identity $userMailboxPrimarySMTPAddress
    #Enterprise Pack License Check
    if ($($null -eq (Get-MgUserLicenseDetail -UserId $mgUser.Id | Where-Object {$_.SkuId -eq $enterprisepack})))
    {
        $E3Status = "Removed"
    }
    else 
    {
        $E3Status = "Not Removed"
    }
    #Intune License Check
    if ($($null -eq (Get-MgUserLicenseDetail -UserId $mgUser.Id | Where-Object {$_.SkuId -eq $INTUNE_A_D})))
    {
        $IntuneStatus = "Removed"
    }
    else 
    {
        $IntuneStatus = "Not Removed"
    }

    #Email Receipt to IT
    $ReceiptTable = [PSCustomObject]@{
        Name = $userName
        Email = $FinaluserMailbox.primarySMTPAddress
        MailboxType = $FinaluserMailbox.RecipientTypeDetails
        Manager = $managerName
        ManagerEmail = $managerMail
        ForwardingAddress = $FinaluserMailbox.ForwardingSmtpAddress
        OneDrive = $SPOneDriveURL
        AccountDisabled = $MGAuditTimeStamp
        E3LicenseRemoved =  $E3Status
        IntuneLicenseRemoved = $IntuneStatus
    }
    $ExportData += $ReceiptTable    

}

#END OF FOREACH LOOP

#Email Receipt to IT
$ExportData = $ExportData | Sort-Object Name
$ExportData
Write-Output "Sending Receipt to IT"
$ExportDataHTML = $ExportData | ConvertTo-Html -Property Name, Email, MailboxType, Manager, ManagerEmail, ForwardingAddress, OneDrive, E3LicenseRemoved, IntuneLicenseRemoved -As Table 
 $params = @{
    Message = @{
        Subject = "Offboarding Employees Receipt"
        Body = @{
            ContentType = "HTML"
            Content = "
        <html>
        <head>
        <style>
            table {
                border-collapse: collapse;
                width: 80%;
            }
            th, td {
                border: 1px solid black;
                padding: 8px;
                text-align: left;
            }
        </style>
        </head>
        <body>
        <p>The Below Users Have had the following changes done as part of their offboarding process</p>
        $ExportDataHTML
        </table>
        </body>
        </html>
        "}
    
ToRecipients = @(
    @{
        EmailAddress = @{
            Address = $emailTO
        }
    }
)
    }
}

#Send Email
Send-MgUserMail -UserId $emailFROM -BodyParameter $params