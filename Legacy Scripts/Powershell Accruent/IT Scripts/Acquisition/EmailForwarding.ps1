#EmailForwarding.ps1
#Created by Regan Vecera
#4.23.2018

# Sets the forwarding address based on email addresses in CSV file


#Clear screen and import the csv used to create the accounts
cls
$Users = $null
$Users = Import-Csv ".\UserData.csv"

Do
{
$error.clear()
$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
$adminUN = ([ADSI]$sidbind).mail.tostring()
$UserCredential = Get-Credential -UserName $adminUN -Message "Enter your password"
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

If ($error.count -gt 0) { 
#Clear-Host
$failed = Read-Host "Login Failed! Retry? [y/n]"
	if ($failed  -eq 'n'){exit}
}
} While ($error.count -gt 0)
Import-PSSession $Session -AllowClobber

#Establishes Online Services connection to Office 365 Management Layer.
Connect-MsolService -Credential $UserCredential

#Loop through all users in the user account creation csv
foreach($User in $Users)
{
	#Grab full name from CSV
	$username = $User.UserName
	$AcquiredEmail = $User.CurrentEmail
	
	#Search for their AD account
	$ADUser = get-aduser $username
	$AccruentEmail = (Get-ADUser $username).userPrincipalName
	
	Write-Host "Setting forwarding address for $username to $AcquiredEmail" -ForegroundColor Green
	Set-Mailbox -Identity $AccruentEmail -DeliverToMailboxAndForward $false -ForwardingSmtpAddress $AcquiredEmail
}