#Get-DistroListUsageReport.ps1
#Created by Regan Vecera
#Date: 7.1.2018

<#
INPUT: Distribution list(s) that you want to check activity on. Number of days to go back when checking activity
OUTPUT: A CSV with the name, email, and number of messages in the time range specified by the user for each list
DESCRIPTION: This script is intended to help find and reduce the number of unused distribution lists in AD
#>

Import-Module ActiveDirectory

$DistroListCSV = ".\DistroList.csv"
$DistroListsString = ""
$activityWindow = 30

#Check if the file exists
if (!(Test-Path $DistroListCSV)){
	Write-Host "File 'DistroList.csv' NOT found." 
	$selection1 = 0
	while($selection1 -lt 1 -or $selection1 -gt 2)
	{
		$selection1 = Read-Host " 1) Continue and run the report for all distribution lists`n 2) Exit program and I will create DistroList.csv`n"`
	}
	if($selection1 -eq 1)
	{
		Get-ADGroup -filter {Name -like "*"} -ResultSetSize $null | foreach {$DistroListsString += $_.Name + ","}
	}
	if($selection1 -eq 2)
	{
		exit
	}
	#Send-MailMessage -to $to -from $from -subject "Unable to update Active Directory from HR File" -body "Could not find file to import. Script did not update user information. Put file in $pwd\NewList" -SMTPServer $smtp
}
else
{
	Write-Host "File found"
	$DistroListsImport  = Import-Csv $DistroListCSV
	foreach ($entry in $DistroListsImport)
	{
		$DistroListsString += $entry.Name + ","
	}
}

$DistroLists = $DistroListsString.split(',')


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
Import-PSSession $Session -AllowClobber

$today = Get-Date
$startTrace = $today.AddDays(-1*$activityWindow)


Foreach ($dl in $DistroLists) {

$dl = $dl -replace '\s',''
Get-MessageTrace -RecipientAddress "$dl@accruent.com" -Status expanded -StartDate $startTrace -EndDate $today |Sort-Object RecipientAddress | Group-Object RecipientAddress |Sort-Object Count |Select-Object Name, Count | Export-CSV ".\UsageReportLast$activityWindowDays.csv" -Append -NotypeInformation

}
