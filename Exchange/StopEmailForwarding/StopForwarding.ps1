#StopForwarding.ps1
#Created by Regan Vecera
#8.29.2017

#This script reads usernames from the file 'stopForwardingList' which should be located in the same directory as this script
#The script then updates the excel spreadsheet housed in the IT Y drive and stops email forwarding on O365

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
$disabledAccounts = Import-excel -path $FilePath -WorkSheetName $SheetName
$stopList = Import-Csv '.\stopForwardingList.csv'

# Create an Object Excel.Application using Com interface
$objExcel = New-Object -ComObject Excel.Application

# Do not open the document in Excel
$objExcel.Visible = $false

# Open the Excel file
$Workbook = $objExcel.Workbooks.Open($FilePath)

# Load the worksheet
$Worksheet = $Workbook.sheets.item($SheetName)
####################################
$date = Get-Date -Format d

#Establishes Online Services connection to Office 365 Management Layer.
Connect-MsolService -Credential $UserCredential

foreach ($user in $stopList)
{
	$username = $user.Name
	$useremail = $username + "@accruent.com"
	
	#Turn off the forwarding
	Set-Mailbox -Identity $useremail -DeliverToMailboxAndForward $false -ForwardingAddress $null
	
	#Take away any licenses they may still have
	try{
		Set-MsolUserLicense -UserPrincipalName $useremail -RemoveLicenses "accruentatlas:ENTERPRISEPACK","accruentatlas:EMS","accruentatlas:STANDARDPACK"
	}
	catch
	{
	
	}
	
	#Update the Disabled_Exchange_Accounts spreadsheet
	If($SearchResult = $Worksheet.Range("A:A").Find($username))
	{
	    $Worksheet.Cells.Item($SearchResult.Row,3) = "N"
		$Worksheet.Cells.Item($SearchResult.Row,7) = "Email forwarding stopped $date"
	}
}
$Workbook.Close()
$objExcel.Quit()
