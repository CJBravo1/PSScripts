<#
	AccountCreation.ps1
	Modified from existing new hire script by Regan Vecera
	Date: 4.23.18
	
	Input: Input will be read from the UserData.csv file in the same directory
	
	Output: Text will be output to the screen during runtime, AD accounts will be created,
			properties set, and emails sent
			
	Parameters: The only parameters that need to be set are the variables $ContractorToggle 1 for IS a contractor, 0 if not
				$HideFromGAL either $true which will hide them from the GAL, or $false which will not
#>

Start-Transcript -OutputDirectory ("$pwd\Transcripts") -IncludeInvocationHeader

$Users = $null
$Users = Import-Csv ".\UserData.csv"

#This will determine the suffix to use when creating email addresses as well as whether or not to hide the user from the GAL
#0 for non contractor
#1 for contractor
$ContractorToggle = 0
$HideFromGAL = $false

#Set variables for mail servers
$mxserver = "accruent-com.mail.protection.outlook.com"
$smtpserver = "smtp.office365.com" 

# Load the AD modules
Import-Module ActiveDirectory

#Launch O365 Session, pull username from person currently logged in
Do
{
	$error.clear()
	$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
	$adminUN = ([ADSI]$sidbind).mail.tostring()
	$UserCredential = Get-Credential -UserName $adminUN -Message "Enter your password"
	$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

	If ($error.count -gt 0) { 
	Clear-Host
	$failed = Read-Host "Login Failed! Retry? [y/n]"
		if ($failed  -eq 'n'){exit}
	}
} While ($error.count -gt 0)
Import-PSSession $Session 

#Clear out variable
$EmailBody = "" 
$Sender = $UserCredential.UserName
if($ContractorToggle -eq 1)
{
	$suffix = "@contractors.accruent.com"
}
else
{
	$suffix = "@accruent.com"
}

foreach ($User in $Users)  
    {
        # set each field into a variable for building command
		$FirstName = $User.'First Name'
		$LastName = $User.'Last Name'
		$FullName = "$FirstName $LastName"
		$CurrentUserName = $User.UserName
        $CurrentEmail = $User.CurrentEmail
		$Company = $User.Company
		$Department = $User.Department
		$Description = $User.Description
		$Title = $User.'Job Title'
		$ManagerFullName = $User.Manager
		$OfficeName = $User.Office

        if (($FirstName + $LastName).length -lt 19)
            {
            $Username = "$FirstName"+"."+"$LastName"
            $UID = $Username.ToLower()
            $Email = $UID+$suffix
            }
        else
            {
			$FirstInitial = $FirstName.substring(0,1)
            $Username = ("$FirstInitial"+"$LastName")
            $UID = $Username.ToLower()
            $Email = $UID+$suffix
            }


        Write-Host "First Name: "$FirstName
        Write-Host "Last Name: "$LastName
        Write-Host "Full Name: "$FullName
        Write-Host "Username: "$Username
        Write-Host "UserID: "$UID
        Write-Host "Email Address: "$Email
        Write-Host "Office Location: "$OfficeName
        Write-Host "Job Title: "$Description
        Write-Host "Department: "$Department
        Write-Host "Manager: "$Manager
        "`n"
            
    # create ADUser
	Write-Host "Creating AD User Account" -Foregroundcolor Green
	New-ADUser -Name $FullName -DisplayName $FullName -Path "OU=acc_Domain_Users,DC=accruent,DC=com" -SamAccountName $UID -GivenName $FirstName -Surname $LastName -Company $Company -AccountPassword (ConvertTo-SecureString "V@lh8lla69" -AsPlainText -Force) -ChangePasswordAtLogon $false -ScriptPath "LOGIN.CMD" -Enabled $true
	
	Set-ADUser -identity $UID -replace @{'msExchHideFromAddressLists' = $HideFromGAL}
	Set-ADUser -identity $UID -EmailAddress $Email -userPrincipalName $Email  
	Set-ADUser -identity $UID -Description $Description
	Set-ADUser -identity $UID -Title $Title
	Set-ADUser -identity $UID -Department $Department
	#Set-ADUser -identity $UID -Manager (Get-ADUser $Manager)
	
    #Changes Proxy and Target Address' in Attibute Editor
	Write-Host "Adding Proxy Addresses" -Foregroundcolor Green
    Set-ADUser -Identity $UID -Add @{ProxyAddresses="SMTP:$UID$suffix"}
    Set-ADUser -Identity $UID -Add @{TargetAddress="SMTP:$UID@accruentatlas.onmicrosoft.com"}

    #Sets defualt "Member Of" groups
	Write-Host "Adding User to Default AD Groups" -Foregroundcolor Green
    
	if($ContractorToggle -eq 1)
	{
		Add-ADGroupMember "VPN_CONTRACTOR" $UID
	}
	else
	{
		Add-ADGroupMember "VPN_General" $UID
	}
		
    #Sets office location and address for user, and adds to distro groups for those locations
	#Set the office name and street address in different commands just in case the office ojbect hasn't been created
	#and that line errors out
	Write-Host "Setting Office Locations" -Foregroundcolor Green
	Switch ($OfficeName)
	{
		{$_ -eq "Domain" -or $_ -eq "Austin"}
			{
			Set-ADUser -Identity $UID -Office "TX-AUSTIN"
			Set-ADUser -Identity $UID -StreetAddress "11500 Alterra Parkway, Suite 110" -City "Austin" -State "TX" -PostalCode "78758" -Country "US"
        	Add-ADGroupMember "_ALL_ Austin FTE - No Execs" $UID
			}
		"Boston" 
			{
			Set-ADUser -Identity $UID -Office "MA-BOSTON"
			Set-ADUser -Identity $UID -StreetAddress "99 Bedford Street, Floor 3" -City "Boston" -State "MA" -PostalCode "02111-2636" -Country "US"
        	Add-ADGroupMember "_ALL_ Boston FTE" $UID
			}
		{$_ -eq "Remote" -or $_ -eq "W@Home" -or $_ -eq "Home Based"} 
			{
			Set-ADUser -Identity $UID -Office "RE-REMOTE"
        	Add-ADGroupMember "_ALL_ Remote FTE" $UID
			}
		"Vancouver"
			{
			Set-ADUser -Identity $UID -Office "BC-VANCOUVER"
			Set-ADUser -Identity $UID -StreetAddress "1066 West Hastings Street, Oceanic Plaza, Suite 1210" -City "Vancouver" -State "BC" -PostalCode "V6E 3X1" -Country "Canada"
			Add-ADGroupMember "_ALL_ Vancouver FTE" $UID
			}
        "Calgary"
            {
			Set-ADUser -Identity $UID -Office "AB-CALGARY"
            Set-ADUser -Identity $UID -StreetAddress "909 17 Avenue SW, Suite 4090" -City "Calgary" -State "AB" -PostalCode "T2T 0A4" -Country "Canada"
            Add-ADGroupMember "_ALL_ Calgary FTE" $UID
			}
         "Vaughan"
            {
			Set-ADUser -Identity $UID -Office "ON-VAUGHAN"
            Set-ADUser -Identity $UID -StreetAddress "3700 Steeles Avenue West, Suite 400" -City "Vaughan" -State "ON" -PostalCode "L4L 8K8" -Country "Canada"
            Add-ADGroupMember "_ALL_ Vaughan FTE" $UID
            }
        "India"
            {
			Set-ADUser -Identity $UID -Office "IN-HYDERABAD"
            Set-ADUser -Identity $UID -StreetAddress "#501, Trendset Towers, Road No. 2, Banjara Hills" -City "Hyderabad" -State "Teleangana" -PostalCode "500034" -Country "India"
            Add-ADGroupMember "_ALL_ Mainspring FTE India" $UID
			Add-ADGroupMember "_ALL_ India FTE" $UID
            }
        "Phoenix"
            {
			Set-ADUser -Identity $UID -Office "AZ-PHOENIX"
            Set-ADUser -Identity $UID -StreetAddress "15210 South 50th Street, Suite 190" -City "Phoenix" -State "AZ" -PostalCode "85044" -Country "US"
            Add-ADGroupMember "_ALL_ Phoenix FTE" $UID
            }
        "Atlanta"
            {
			Set-ADUser -Identity $UID -Office "GA-ATLANTA"
            Set-ADUser -Identity $UID -StreetAddress "2727 Paces Ferry Road, Building One, Suite 750" -City "Atlanta" -State "GA" -PostalCode "30339" -Country "US"
            }
        {($_ -eq "Minneapolis") -or ($_ -eq "MN") -or ($_ -eq "MSP")}
            {
			Set-ADUser -Identity $UID -Office "MN-MINNEAPOLIS"
            Set-ADUser -Identity $UID -StreetAddress "730 Second Avenue South, Suite 600" -City "Minneapolis" -State "MN" -PostalCode "55402" -Country "US"
			Add-ADGroupMember "_ALL_ Minneapolis FTE" $UID
            }
		"London"
            {
			Set-ADUser -Identity $UID -Office "UK-LONDON"
            Set-ADUser -Identity $UID -StreetAddress "Golden Cross House, 8 Duncannon Street" -City "Strand, London" -PostalCode "WC2N 4JF" -Country "United Kingdom"
            Add-ADGroupMember "_ALL_ UK FTE" $UID
            }
        "Reading"
            {
			Set-ADUser -Identity $UID -Office "UK-LONDON"
            Set-ADUser -Identity $UID -StreetAddress "Davidson House, Forbury Square" -City "Reading" -PostalCode "RG1 3 EU" -Country "United Kingdom"
            Add-ADGroupMember "_ALL_ UK FTE" $UID
            }
		"North Shields" #Kykloud
            {
			Set-ADUser -Identity $UID -Office "UK-NORTH SHIELDS"
            Set-ADUser -Identity $UID -StreetAddress "Nautilus House, Earl Grey Way " -City "North Shields, Tyne and Wear" -PostalCode "NE29 6AR" -Country "United Kingdom"
            Add-ADGroupMember "_ALL_ UK FTE" $UID
            }
        {($_ -eq "Israel") -or ($_ -eq "Jerusalem")}
            {
			Set-ADUser -Identity $UID -Office "IL-ISRAEL"
            Set-ADUser -Identity $UID -StreetAddress "8 HaMarpe Street, Har Hotzvim, PO Box 45041" -City "Jerusalem" -PostalCode "91450" -Country "Israel"
            Add-ADGroupMember "_ALL_ Israel FTE" $UID
            }	
		"Plano"
			{
			Set-ADUser -Identity $UID -Office "TX-PLANO"
			Set-ADUser -Identity $UID -StreetAddress "6509 Windcrest Drive, Suite 100" -City "Plano" -State "TX" -PostalCode "75024" -Country "US"
			Add-ADGroupMember "_ALL_ Plano FTE" $UID
			}
		{($_ -eq "NL") -or ($_ -eq "Hoofddorp")}
			{
			Set-ADUser -Identity $UID -Office "NL-HOOFDDORP"
			Set-ADUser -Identity $UID -StreetAddress "Polarisavenue 1" -City "Hoofddorp" -PostalCode "2132 JH" -Country "The Netherlands"
			}
		"Sao Leopoldo"
			{
			Set-ADUser -Identity $UID -Office "BR-SAO LEOPOLDO"
			Set-ADUser -Identity $UID -StreetAddress "Av. Theodomiro Porto, da Fonseca, 3045 – Conjunto 302, Centro – 93020-080" -City "São Leopoldo" -State "RS" -Country "Brazil"
			}
		"Sao Paulo"
			{
			Set-ADUser -Identity $UID -Office "BR-SAO PAULO"
			Set-ADUser -Identity $UID -StreetAddress "Alameda Santos, 200, Bela Vista – 01418-000" -City "São Paulo" -State "SP" -Country "Brazil"
			}
		"Dusseldorf"
			{
			Set-ADUser -Identity $UID -Office "DE-DUSSELDORF"
			Set-ADUser -Identity $UID -StreetAddress "Design Offices Düsseldorf Kaiserteich, Elisabethstraße 11" -City "Düsseldorf" -PostalCode "40217" -Country "Germany"
			}
		"Essen"
			{
			Set-ADUser -Identity $UID -Office "DE-ESSEN"
			Set-ADUser -Identity $UID -StreetAddress "Weidkamp 180" -City "Essen" -PostalCode "45356" -Country "Germany"
			}
		{($_ -eq "FI") -or ($_ -eq "Finland") -or ($_ -eq "Espoo")}
			{
			Set-ADUser -Identity $UID -Office "FI-ESPOO"
			Set-ADUser -Identity $UID -StreetAddress "Upseerinkatu 1" -City "Espoo" -PostalCode "02600" -Country "Finland"
			}	
		{($_ -eq "LA") -or ($_ -eq "New Orleans") -or ($_ -eq "NOLA")}
			{
			Set-ADUser -Identity $UID -Office "LA-NEW ORLEANS"
			Set-ADUser -Identity $UID -StreetAddress "" -City "New Orleans" -State "LA" -PostalCode "" -Country "US"
			Add-ADGroupMember "_ALL_ New Orleans FTE" $UID
			}	
		{($_ -eq "PA") -or ($_ -eq "Pennsylvania") -or ($_ -eq "Exton")}
			{
			Set-ADUser -Identity $UID -Office "PA-EXTON"
			Set-ADUser -Identity $UID -StreetAddress "411 Eagleview Blvd, Suite 109" -City "Exton" -State "PA" -PostalCode "19341" -Country "US"
			}	
		{($_ -eq "RU") -or ($_ -eq "Russia") -or ($_ -eq "Obninsk")}
			{
			Set-ADUser -Identity $UID -Office "RU-OBNINSK"
			Set-ADUser -Identity $UID -StreetAddress "Korolev Street 6" -City "Obninsk" -State "Kaluga" -PostalCode "249030" -Country "Russia"
			}
		{($_ -eq "SG") -or ($_ -eq "Singapore")}
			{
			Set-ADUser -Identity $UID -Office "SG-SINGAPORE"
			Set-ADUser -Identity $UID -StreetAddress "Marina Bay Financial Centre Tower 1, Level 11, 8 Marina Boulevard" -City "Singapore"  -PostalCode "018981" -Country "Singapore"
			}
	}	
		
		
		
    #Sets extra "Member Of" groups, per department/product
	Switch -wildcard ($Department)
	{
	
        {($_ -eq "*Engineering*") -or ($_ -eq "^QA*")} 
            {
				if( $_ -contains "sales") { }#do nothing - don't want to put Sales Engineers on this list
				else
				{
	            Add-ADGroupMember "LS-Visual Studio" $UID
	            Add-ADGroupMember "All of Engineering" $UID
	            If ($OfficeName -eq "Domain")
					{
						Add-ADGroupMember "Austin Engineering" $UID
			   		}
	            If ($Product -eq "Expesite")
					{
						Add-ADGroupMember "Expesite Developers" $UID
					}
	            }
			}
        "^Professional Services*"
            {
            Add-ADGroupMember "All of PS" $UID
            }
        "Support Telecom"
			{
			Add-ADGroupMember "Siterra Support Team" $UID
			}
		"Support*"
			{
			Add-ADGroupMember "Support Dept. Folder Access" $UID
			}
        "Business Development*"
			{
			Add-ADGroupMember "_SAL_Business Devel-1" $UID
			}
		{($_ -like "*Sales*") -and (($_ -like "*Director*") -or ($_ -like "*Vice President*") -or ($_ -like "*SVP*"))}
			{
			Add-ADGroupMember "Sales Leadership" $UID
			}
		"Sales Engineering*"	
			{
			Add-ADGroupMember "Sales Engineers" $UID
			}
	}
	Switch -wildcard ($Product)
	{
        "FRSoft"
			{
			Add-ADGroupMember "All at Four Rivers" $UID
			}
        "SiteFM"
			{
				Add-ADGroupMember "All at SiteFM" $UID
			}
        "Mainspring"
			{
				Add-ADGroupMember "_ALL_ Mainspring FTE US" $UID
			}
        "Siterra"
			{
				Add-ADGroupMember "All Telecom" $UID
			}
        "BIGCenter"
			{
				Add-ADGroupMember "_ALL_ BIGCenter FTE" $UID
			}
        "Verisae"
			{
				Add-ADGroupMember "_ALL_ Verisae FTE" $UID
			}
		{($_ -eq "Lucernex") -or ($_ -eq "LX")}
			{
				Add-ADGroupMember "_ALL_ Lucernex FTE" $UID
			}
	}
	
    Get-ADUser $UID -Properties * | Select Name,sAMAccountName,userPrincipalName,mail,Description,title,manager

        ## X Folder Creation
        <#
        $folder = "\\accruent.com\fs\users\$UID"
        New-Item "$folder" -Type Directory
        ICACLS $folder /inheritance:d
        ICACLS $folder /remove "CREATOR OWNER" /T /C
        ICACLS $folder /remove "SYSTEM" /T /C
        ICACLS $folder /remove "DOMAIN USERS" /T /C
        ICACLS $folder /remove "Users" /T /C
        ICACLS $folder /grant Accruent\$UID":(OI)(CI)M"
        #>

        #Creates array to write out Full Name, Username, and Email Address for each user in CSV, to add to email notification body
    Write-Host "Writing Email" -Foregroundcolor Green
	$EmailBody += "<br><br><b>User:</b> $FullName <br><b>Username:</b> $UID<br><b>Email:</b> $UID$suffix"
	
	<#
	if($AcquisitionFlag -eq 1)
	{
		#Ignore manager email
	}
	else
	{
        #Creates variables for email to get Member Of groups from user's manager
        $ManagerFirst = (Get-ADUser $Manager -Properties givenName).givenName
        $ManagerEmail = (Get-ADUser $Manager -Properties userPrincipalName).userPrincipalName
		$office = Get-ADUser $UID -Properties * | Select Office 
		$GroupsBody =
        "$ManagerFirst,
        <br>
        <br>
        In preparation for $FullName's first day of work, please
	        
        <a href= `"mailto:helpdesk1@accruent.com?
		subject= REQUEST | Security/Distro Groups - $Fullname&
		body=@priority = Medium (7 bus days)%0B@category = User Access/Account Mgmt%0B@location = TX-AUSTIN%0B%0B

		$Fullname should be placed in the following groups:`">click here to create a KACE ticket</a><br> that can be filled out with security groups and distribution lists that the employee needs to be a part of.
		<br><br>	
	    <b>Please be specific -</b> We will not mirror another user's access, as they don't always line up 100%. We can provide you a list of groups that a user is part of, and you can select from there, but we will not be able to just mirror a user's access.
        <br><br>
        Thank you,
        <br><br>
        IT Service Desk "

        #New Hire Created Email
        Send-MailMessage -To $ManagerEmail -From $Sender -Subject "REQUEST | New Hire Security/Distro Groups - $FullName" -Body $GroupsBody -BodyAsHtml -Credential $UserCredential -SmtpServer $mxserver -UseSsl   
	}
	#>
	}
	
	
	
#Force Domain Controller Replication, and then sysc BosCorpAADC to Office365
#Creates variable to grab the server name of the closest Domain Controller to run the DC replication from.
Write-Host "Syncing Changes" -Foregroundcolor Green
$DC = $env:LOGONSERVER -replace ‘\\’,""



#New Hire Created Email
Send-MailMessage -To "servicedesk@accruent.com" -From $Sender -Subject "INFO | New Hire Created" -Body $EmailBody -BodyAsHtml -Credential $UserCredential -SmtpServer $mxserver -UseSsl

#Replication Command
repadmin /syncall $DC /APed

#Creates variable with command to run Domain to O365 sync
$Script =
{
    & "C:\Program Files\Microsoft Azure AD Sync\Bin\DirectorySyncClientCmd.exe" delta
}


Remove-PSSession $Session

#Command to kick off Sync command
Invoke-Command -ComputerName BOSCORPAADC.accruent.com -ScriptBlock $Script

Stop-Transcript