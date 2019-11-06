$Users = $null
$Users = Import-Csv -Delimiter "," -Path C:\Scripts\FTEtoContractor.csv

# Load the AD modules
Import-Module ActiveDirectory

# Gather credentials
$Cred = Get-Credential -Message "Please enter Office365 Credentials (e.g. username@accruent.com)"

$emailbody = "" # clear out variable

foreach ($User in $Users)  
    {
        # set each field into a variable for building command
		$UID = $User.UserID
        $Title = $User.Title		
        $Department = $User.Department
    	$Manager = $User.Manager
        $Company = $User.Company

        # Build command to update AD information, checking to see if variable has value, if it does, add it to the command
		Set-ADUser -identity $UID -EmailAddress "$UID@contractors.accruent.com" -userPrincipalName "$UID@contractors.accruent.com" -Description "MGR: $Manager" -Office " " -Title "$Company $Title" -Department $Department -Company $Company -Clear Manager
		
        # Clear out extra properties no longer needed - Manager, City, Street, State, Zip Code
        Set-ADUser -Identity $UID -Clear Manager,physicalDeliveryOfficeName,streetAddress,l,st,postalCode

        # Changes Proxy and Target Address' in Attibute Editor
        Set-ADUser -Identity $UID -Remove @{ProxyAddresses="SMTP:$UID@accruent.com"}
        Set-ADUser -Identity $UID -Add @{ProxyAddresses="SMTP:$UID@contractors.accruent.com"}
        Set-ADUser -Identity $UID -Add @{TargetAddress="SMTP:$UID@accruentatlas.onmicrosoft.com"}

        # Removes User from all but primary AD Group 
        $RemovedUser = Get-ADUser "$UID" -Properties memberOf
        $RemovedGroups = $RemovedUser.memberOf |ForEach-Object { Get-ADGroup $_ } 
        $RemovedGroups |ForEach-Object { Remove-ADGroupMember -Identity $_ -Members $RemovedUser -Confirm:$false }

        # Move user to Contractors OU
        Get-ADUser $UID | Move-ADObject -TargetPath "OU=_Contractors365,OU=acc_Domain_Users,DC=accruent,DC=com"

        $Principal = (Get-ADUser $UID -Properties userPrincipalName).userPrincipalName
        $FullName = (Get-ADUser $UID -Properties DisplayName).displayname

        #Creates array to write out Full Name, Username, and Email Address for each user in CSV, to add to email notification body
        $emailbody += "<br><br><b>User:</b> $FullName <br><b>Username:</b> $UID<br><b>Email:</b> $Principal"

    }

#Force Domain Controller Replication, and then sysc BosCorpAADC to Office365
#Creates variable to grab the server name of the closest Domain Controller to run the DC replication from.
$DC = $env:LOGONSERVER -replace ‘\\’,""

#Replication Command
repadmin /syncall $DC /APed

#Creates variable with command to run Domain to O365 sync
$script =
{
    & "C:\Program Files\Microsoft Azure AD Sync\Bin\DirectorySyncClientCmd.exe" delta
}

#Command to kick off Sync command
Invoke-Command -ComputerName BOSCORPAADC.accruent.com -ScriptBlock $script

#Connect to Exchange Online
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $Cred -Authentication Basic -AllowRedirection
Import-PSSession $ExchangeSession -AllowClobber

#Email "From", SMTP variables, New Hire variables
$Sender = $Cred.UserName

#New Hire Created Email
Send-MailMessage -To $Sender -From $Sender -Subject "INFO | FTE Converted to Contractor" -Body $emailbody -BodyAsHtml -Credential $Cred2 -SmtpServer smtp.office365.com -UseSsl   

Remove-PSSession $ExchangeSession