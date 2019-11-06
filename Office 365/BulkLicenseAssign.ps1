# BulkLicenseAssign.ps1
# Created by Regan Vecera
# 8.15.2017

# This script is to assign licenses in bulk. Usually used after an acquistition.
# The names will be read from a csv file with the columns titled FirstName, LastName, and NickName
# Naming standard: firstname.lastname@accruent.com unless they have a nickname in which case they are nickname.lastname@accruent.com
# These accounts must already exist in active directory
# The only variables that will need to be changed are $csv and $oldSuffix

#Name of CSV file with all the email addresses
$csv = '.\lovejoyusers.csv'
$import = Import-Csv -LiteralPath $csv
$oldSuffix = "lucernex.com"
$newSuffix = "accruent.com"
$count = 0

#Connect to O365
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

#Establishes Online Services connection to Office 365 Management Layer.
Connect-MsolService -Credential $UserCredential

#Loop through csv and assign licenses
foreach ($user in $import)
{
	$first = $user.FirstName
	$last = $user.LastName
	$nick = $user.NickName
	$oldEmail = $user.EmailAddress
	
	if($nick -eq "")
	{
		$email = $first + "." + $last + "@accruent.com"
	}
	else
	{
		$email = $nick + "." + $last + "@accruent.com"
	}
	$email
	
	#Sets user's location
	Set-MsolUser -UserPrincipalName $email -UsageLocation US
	try
	{
		Set-MsolUserLicense -UserPrincipalName $email -AddLicenses "accruentatlas:EMS","accruentatlas:ENTERPRISEPACK"
		#Set-Mailbox -Identity $email -DeliverToMailboxAndForward $false -ForwardingAddress $oldEmail
	}
	catch
	{
		$count--
	}
	$count++
}

"$count users were assigned licenses"

Write-Host "Press any key to continue ..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Remove-PSSession $Session

<# 
List of license codes
E3 = ENTERPRISEPACK
E1 = STANDARDPACK
Exchange Online (Plan 1) = EXCHANGESTANDARD
Enterprise Mobility + Security E3 = EMS
POWER_BI_STANDARD
#>


