 #noPhoneNumber.ps1
 # Created by Regan Vecera
 # 8.29.2017
 
 # This script goes through all the licensed users on O365 online and finds who has
 # an empty phone number field, it then sends them an email requesting them to respond
 # with their phone number. This information should then be used in conjunction with
 # the other script in this folder to actually update their phone numbers
 
 cls
# Gather credentials
$Cred = Get-Credential -Message "Please enter Office365 Credentials (e.g. username@CompanyName.com)"

#Connect to Exchange Online
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $Cred -Authentication Basic -AllowRedirection

Import-PSSession $ExchangeSession -AllowClobber

#Establishes Online Services connection to Office 365 Management Layer.
Connect-MsolService -Credential $Cred

#Export all users with a license to a CSV 
#Get-MsolUser -All | Where-Object { $_.isLicensed -eq "TRUE" } | Select displayname,signinname | Export-Csv .\LicensedUsers.csv -NoTypeInformation


#$useremail = "regan.a.vecera@CompanyName.com"
#E3 = ENTERPRISEPACK
#E1 = STANDARDPACK
#Exchange Online (Plan 1) = EXCHANGESTANDARD
#Enterprise Mobility + Security E3 = EMS
#POWER_BI_STANDARD


#Sets user's location
#Set-MsolUser -UserPrincipalName $useremail -UsageLocation US

#Check for a particular license
$useremail = "regan.a.vecera@CompanyName.com"
# Get-MsolUser -UserPrincipalName $useremail| select usagelocation
#(Get-MsolUser -UserPrincipalName $useremail).Licenses.AccountSkuId
$count = 0
$noPhoneNumber = 0
Get-MsolUser -All | foreach {
	if ($_.Licenses.AccountSkuId -eq "CompanyNameatlas:ENTERPRISEPACK")
	{	
		#Write-Host "User has an E3 license - "
		$name = (Get-ADUser -Filter {UserPrincipalName -eq $_.UserPrincipalName}).name
		$_ | Select displayname,UserPrincipalName,PhoneNumber | Export-Csv ".\noPhoneNumbers.csv" -Append -Force
		$count++
		$Subject = "ACTION | Missing phone number"
		$Body = "Dear $name,<br>
		We are doing a little house cleaning, and noticed that you do not have a Telephone Number associated with your account. 
		If you could please just respond to this email and include your phone number, I&#39ll get that entered into your contact information. 
		We greatly appreciate your help while we try and tidy up. 
		<br><br>
		Thank you,<br>
		Regan Vecera "

		if ($_.PhoneNumber -eq $null)
		{
			$noPhoneNumber++
			Send-MailMessage -To $_.UserPrincipalName -From $useremail -Subject $Subject -Body $Body -BodyAsHtml -Credential $Cred -SmtpServer smtp.office365.com -UseSsl
		}
		#Set-MsolUserLicense -UserPrincipalName $_.UserPrincipalName -AddLicenses "CompanyNameatlas:EMS" 
	}
}
"$noPhoneNumber/$count  have no phone number"

#Add or Remove Licenses
#Set-MsolUserLicense -UserPrincipalName $useremail -AddLicenses "CompanyNameatlas:ENTERPRISEPACK" -RemoveLicenses "CompanyNameatlas:STANDARDPACK"
#Set-MsolUserLicense -UserPrincipalName $useremail -RemoveLicenses "CompanyNameatlas:ENTERPRISEPACK" -AddLicenses "CompanyNameatlas:EXCHANGESTANDARD"
"Script Execution Complete"
