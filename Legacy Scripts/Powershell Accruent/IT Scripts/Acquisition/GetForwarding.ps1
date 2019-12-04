#GetForwarding.ps1
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

$date = Get-Date -Format d

# Set variables for Excel manipulation
$List = Import-Csv '.\UserData.csv'
$exportpath = '.\Forwardinglist.csv'
####################################


#Establishes Online Services connection to Office 365 Management Layer.
Connect-MsolService -Credential $UserCredential
$choice = Read-Host "Export to CSV press 1, Export to Powershell window press 2"

foreach ($user in $List)
{
	#$username = $user.Name
	$useremail = $user.EmailAddress
	#Turn off the forwarding
	
	if ($choice -eq 1)
	{
		Get-Mailbox -identity $useremail | Select Name,ForwardingAddress,ForwardingsmtpAddress | Export-Csv $exportpath -NoTypeInformation -Append
	}
	else
	{
		
		Get-Mailbox -identity $useremail | Select Name,ForwardingAddress,ForwardingsmtpAddress
	}
	Write-Host "`n"
	#Set-Mailbox -Identity $useremail -DeliverToMailboxAndForward $false -ForwardingAddress $null
}

