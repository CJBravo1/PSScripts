<# SendEmailToStopForwarding.ps1
Created by Regan Vecera
8.16.2017

This script is designed to run once a week and check for entries in the CSV where the forward end date is before the current date
if this is the case, an email will be sent to the manager asking whether or not to continue the forwarding. If the choose yes,
a prefilled email will be generated that will submit a KACE request
#>

cls

#Log in to O365
Do
{
	$error.clear()
	$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
	$adminUN = ([ADSI]$sidbind).mail.tostring()
	$UserCredential = Get-Credential -UserName $adminUN -Message "Enter your password"
	$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

	If ($error.count -gt 0) 
	{ 
		Clear-Host
		$failed = Read-Host "Login Failed! Retry? [y/n]"
			if ($failed  -eq 'n'){exit}
	}
} While ($error.count -gt 0)
Import-PSSession $Session -AllowClobber

# Set variables for Excel manipulation

$FilePath = "\\FS02\Departments\IT\Disabled_Exchange_Accounts.xlsx"
$SheetName = "Disabled"
$import = Import-excel -path $FilePath -WorkSheetName $SheetName

# Create an Object Excel.Application using Com interface
$objExcel = New-Object -ComObject Excel.Application

# Do not open the document in Excel
$objExcel.Visible = $false

# Open the Excel file
$Workbook = $objExcel.Workbooks.Open($FilePath)

# Load the worksheet
$Worksheet = $Workbook.sheets.item($SheetName)
####################################
$NewRow = $Worksheet.UsedRange.rows.count

foreach($User in $import)
{
	#Pull relevant data from CSV
	$termedUser = $User.FullName
	$forwardStart = get-date $User.ForwardStartDate -Format D
	$Destination = $user.Destination
	
	#Get the email address either via their name or username
	$recipient = Get-ADUser -Filter {name -eq $Destination} -Properties * | Select UserPrincipalName
	if($recipient -eq $null)
	{
		$recipient = $Destination + "@CompanyName.com"
	}
	#$recipient
	
	$Subject = "ACTION | Stop forwarding $termedUser's email?"
	$Body = "Our records indicate $termedUser was terminated and their emails began forwarding to you on $forwardStart. Would you like to disable this forwarding?
			<br>If NO, no further action is required
			<br>If YES, click 
			 <a href= `"mailto:helpdesk1@CompanyName.com?
			subject= ACTION | Stop email forwarding - $termedUser&
			body= 
			@priority= Low (15 Bus Days) 
			%0B@category= Email 
			%0B@location= ATX-DOMAIN`">
			here 
			</a>to generate a KACE request so an IT representative can fulfill your request."
	
	if(($User.Forwarding -eq "Y") -and ($User.ForwardEndDate -le $currentDate))
	{
		Send-MailMessage -To $recipient -From $UserCredential.UserName -Cc "regan.a.vecera@CompanyName.com" -Subject $Subject -Body $Body -BodyAsHtml -Credential $UserCredential -SmtpServer smtp.office365.com -UseSsl
	}
}