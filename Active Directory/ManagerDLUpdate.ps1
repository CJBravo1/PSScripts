<# ManagerDLUpdate.ps1
Created by Regan Vecera
3.20.2018

This script is designed to populate the distro list "Managers" by reading from an excel file
The program will require the distribution list name, the xlsx file name, and the sheet name
The commands have been modified to work with lists/groups stored in the cloud 
#>

cls
$directorypath = (Resolve-Path .\).Path

$DLname = "Managers"
$FilePath = "$directorypath\ManagersDL.xlsx"
$SheetName = "Page1"
$groupname = $null

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

#Check if the Azure AD module is installed ( not necessary actually)
<#
if (Get-Module -ListAvailable -Name AzureAD) {
    Write-Host "Azure AD is installed, continuing execution"
} else {
    $installAzure = Read-Host "Azure AD module is not installed, it will be required if trying to add a user to a security group`nWould you like to install it now? [y/n]"
	if($installAzure -eq 'y'){install-module AzureAD}
}
#>
#Find out if this is on prem or in the cloud
#Distro Lists and O365 both have the grouptype of 'DistributionList.' However there are different commands
#for DL and O365 groups. This is a distribution list
$groupSelection = 1

#Establishes Online Services connection to Office 365 Management Layer.
#Find the list by name
Connect-MsolService -Credential $UserCredential
$allGroups = Get-MsolGroup -All
$i=0
while($groupname -eq $null)
{
	#$allGroups[$i].DisplayName
	if($allGroups[$i].DisplayName -eq $DLname)
	{
		$group = $allGroups[$i]
		$groupname = $allGroups[$i].DisplayName
		Write-Host "Found the group = $groupname`n"
		switch($groupSelection)
		{
			1 {$groupType = "DistributionList"; break}
			2 {$groupType = "Office365Group"; break}
			3 {$groupType = "Security"; break}
			default {Write-Host "Invalid selection for group type"}
		}
	}
	$i++
}

"Starting for loop"

#Clear out old list
Get-DistributionGroupMember -Identity $DLname | foreach{ Remove-DistributionGroupMember -Identity $DLname -Member $_.Name -confirm:$false} 

#Add each user to the DL
foreach($User in $import)
{
	#$fullname = $User.Name
	#$aduser = Get-ADUser -Filter {name -eq $fullname} -Properties *
	
	$upn = $User."Supervisor Email Address"
	$upn
	#$aduser = Get-ADUser -Filter {UserPrincipalName -eq $upn} -Properties *

	#Add to Cloud DL
	#try
	#{
		Add-DistributionGroupMember -Identity $DLname -Member $upn #-ErrorAction Stop
	#}
	#catch [Microsoft.Exchange.Management.RecipientTasks.AddDistributionGroupMember]{"Caught it"}
}
$Workbook.Close()
$objExcel.Quit()