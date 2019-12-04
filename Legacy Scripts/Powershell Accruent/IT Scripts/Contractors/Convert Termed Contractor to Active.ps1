# Import CSV with list of users to term
$import = Import-Csv -LiteralPath "C:\Scripts\TermedToActive.csv"

# Gather credentials
$Cred1 = Get-Credential -Message "Please enter your Office365 credentials (e.g. username@accruent.com)"

# Self Explanatory
Import-Module ActiveDirectory

# Run term script for each user in the CSV
Foreach ($user in $import)
{
    # Get user's info
    $Fullname = $user.FullName
    $UID = $user.UserID
    $FirstName = $user.FirstName
    $LastName = $user.LastName
    $Description = $user.Description
    $OfficeName = $user.OfficeName
    $Department = $user.Department
    $Manager = $user.Manager
    $Product = $user.Product

    #Enables user's account
    Enable-ADAccount -Identity $UID

    #Set's user information   
    Set-ADUser -Identity $UID -DisplayName $FullName -EmailAddress "$UID@contractors.accruent.com" -userPrincipalName "$UID@contractors.accruent.com" -Description $Description -Title $Description -Department $Department -Manager $Manager -Company Accruent

    #Changes Proxy and Target Address' in Attibute Editor
    Set-ADUser -Identity $UID -Add @{ProxyAddresses="SMTP:$UID@contractors.accruent.com"}
    Set-ADUser -Identity $UID -Add @{TargetAddress="SMTP:$UID@accruentatlas.onmicrosoft.com"}

    # Renames User 
    $RenamedUser = $UID
    $RenamedUser | Foreach {Get-ADuser -Identity $_ | Rename-ADObject -NewName "$FullName"}

    #Adds user to Domain Users group, and sets as Primary, then removes Disable Users group
    Add-AdGroupMember "Domain Users" $UID 
    $group = get-adgroup "Domain Users"
    $groupSid = $group.sid
    $groupSid
    [int]$GroupID = $groupSid.Value.Substring($groupSid.Value.LastIndexOf("-")+1)
    Get-ADUser $UID | Set-ADObject -Replace @{primaryGroupID="$GroupID"}
    Remove-ADGroupMember -Identity Disabled -Members $UID

    # Moves User to _Contractors365 OU 
    Get-ADUser $UID | Move-ADObject -TargetPath "OU=_Contractors365 OU=acc_Domain_Users,DC=accruent,DC=com"

    #Adds user to FortiNet VPN group
    Add-ADGroupMember "VPN_General" $UID
 
  
    #Sets extra "Member Of" groups, per department/product
    If (($Department -eq "Engineering") -or ($Department -eq "R&D Engineering") -or ($Department -eq "Engineering Overhead") -or ($Department -eq "Engineering - Overhead") -or ($Department -eq "Engineering Tier 1") -or ($Department -eq "Engineering Tier 2") -or ($Department -eq "Engineering CRE") -or ($Department -eq "Engineering Healthcare") -or ($Department -eq "Engineering Higher Ed") -or ($Department -eq "Engineering Public Sector") -or ($Department -eq "Engineering Retail") -or ($Department -eq "Engineering Telecom"))
        {
        Add-ADGroupMember "LS-Visual Studio" $UID
        Add-ADGroupMember "All of Engineering" $UID
        If (($OfficeName -eq "BP") -or ($OfficeName -eq "Braker Point") -or ($OfficeName -eq "Braker Pointe") -or ($OfficeName -eq "QO") -or ($OfficeName -eq "Quarry Oaks"))
			{
				Add-ADGroupMember "Austin Engineering" $UID
		   	}
        If ($Product -eq "Expesite")
			{
				Add-ADGroupMember "Expesite Developers" $UID
			}
        }
    If (($Department -eq "QA") -or ($Department -eq "QA Overhead") -or ($Department -eq "QA - Overhead") -or ($Department -eq "QA Tier 1") -or ($Department -eq "QA Tier 2") -or ($Department -eq "QA CRE") -or ($Department -eq "QA Healthcare") -or ($Department -eq "QA Higher Ed") -or ($Department -eq "QA Public Sector") -or ($Department -eq "QA Retail") -or ($Department -eq "QA Telecom"))
        {
        Add-ADGroupMember "LS-Visual Studio" $UID
        Add-ADGroupMember "All of Engineering" $UID
        }
    If (($Department -eq "Professional Services") -or ($Department -eq "Professional Services Corporate") -or ($Department -eq "Professional Services - Corporate") -or ($Department -eq "Professional Services CRE") -or ($Department -eq "Professional Services Healthcare") -or ($Department -eq "Professional Services Higher Ed") -or ($Department -eq "Professional Services Public Sector") -or ($Department -eq "Professional Services Retail") -or ($Department -eq "Professional Services Telecom"))
        {
        Add-ADGroupMember "All of PS" $UID
        }
    If ($Department -eq "Support Telecom")
		{
		Add-ADGroupMember "Siterra Support Team" $UID
		}
    If (($Department -eq "Business Development") -or ($Department -eq "Business Development CRE") -or ($Department -eq "Business Development Healthcare") -or ($Department -eq "Business Development Higher Ed") -or ($Department -eq "Business Development Public Sector") -or ($Department -eq "Business Development Retail") -or ($Department -eq "Business Development Telecom"))
		{
		Add-ADGroupMember "Business Devel-1" $UID
        Add-ADGroupMember "SPS" $UID
		}
    If (($Department -eq "Sales") -or ($Department -eq "Sales Tier 1") -or ($Department -eq "Sales Tier 2") -or ($Department -eq "Sales Corporate") -or ($Department -eq "Sales - Corporate") -or ($Department -eq "Sales CRE") -or ($Department -eq "Sales Healthcare") -or ($Department -eq "Sales Higher Ed") -or ($Department -eq "Sales Public Sector") -or ($Department -eq "Sales Retail") -or ($Department -eq "Sales Telecom") -or ($Department -eq "Sales Engineering") -or ($Department -eq "Sales Engineering Tier 1") -or ($Department -eq "Sales Engineering Tier 2") -or ($Department -eq "Sales Engineering Corporate") -or ($Department -eq "Sales Engineering - Corporate") -or ($Department -eq "Sales Engineering CRE") -or ($Department -eq "Sales Engineering Healthcare") -or ($Department -eq "Sales Engineering Higher Ed") -or ($Department -eq "Sales Engineering Public Sector") -or ($Department -eq "Sales Engineering Retail") -or ($Department -eq "Sales Engineering Telecom"))
		{
		Add-ADGroupMember "All of Sales" $UID
		}
    If ($Department -eq "Hosting")
		{
		Add-ADGroupMember "hosting services" $UID
		}
    If ($Product -eq "FRSoft")
		{
			Add-ADGroupMember "All at Four Rivers" $UID
		}
    If ($Product -eq "SiteFM")
		{
			Add-ADGroupMember "All at SiteFM" $UID
		}
    If ($Product -eq "Mainspring")
		{
			Add-ADGroupMember "_ALL_ Mainspring FTE US" $UID
		}
    If ($Product -eq "Siterra")
		{
			Add-ADGroupMember "All Telecom" $UID
		}


    #Creates array to write out Full Name, Username, and Email Address for each user in CSV, to add to email notification body
        $emailbody += "<br><br><b>User:</b> $FullName <br><b>Username:</b> $UID<br><b>Email:</b> $UID@contractors.accruent.com"
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
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $Cred2 -Authentication Basic -AllowRedirection
Import-PSSession $ExchangeSession -AllowClobber

#Email "From", SMTP variables, New Hire variables
$AccSender = $Cred2.UserName

#New Hire Created Email
Send-MailMessage -To $AccSender -From $AccSender -Subject "INFO | Termed Account Reinstated" -Body $emailbody -BodyAsHtml -Credential $Cred2 -SmtpServer smtp.office365.com -UseSsl   

Remove-PSSession $ExchangeSession
       
   