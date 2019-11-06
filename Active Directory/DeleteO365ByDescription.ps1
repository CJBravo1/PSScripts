<# FillDLfromCSV.ps1
Created by Regan Vecera
9.5.2017

This script is designed to delete all the Office365 created 
by CloudFuze Application
360 third party lib
#>

cls
$directorypath = (Resolve-Path .\).Path

$Description = "Created By CloudFuze Application"
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

#Establishes Online Services connection to Office 365 Management Layer.
Connect-MsolService -Credential $UserCredential
#$allGroups = Get-MsolGroup -All 
Get-UnifiedGroup | foreach {
	if ($_.Notes -eq $Description)
	{
		$name = $_.Name
		Remove-UnifiedGroup -Identity $name -confirm:$false
		"$name will be deleted"
	}
}
<#
$i=0
while($groupname -eq $null)
{
	$allGroups[$i].Description
	if($allGroups[$i].Notes -eq $Description)
	{
		$group = $allGroups[$i]
		$groupname = $allGroups[$i].DisplayName
		Write-Host "Found the group = $groupname`n"
	}
	$i++
}
#>
"Starting for loop"

#Add each user to the DL
<#foreach($User in $import)
{
	
	
	$upn = $User."Supervisor Email Address"
	$upn
	$aduser = Get-ADUser -Filter {UserPrincipalName -eq $upn} -Properties *
	
	$groupType
	switch ($groupType)
	{
		"Office365Group"{Add-UnifiedGroupLinks -Identity $DLname -Links $upn -LinkType Members; break}
		"DistributionList" {Add-DistributionGroupMember -Identity $DLname -Member $upn; break}
		"Security" {
					$msoluser = Get-MsolUser -UserPrincipalName $upn 
					#Add-AzureADGroupMember -ObjectId $group.ObjectID -RefObjectID $msoluser.ObjectId
					Add-MsolGroupMember -GroupObjectId $group.ObjectID -GroupMemberType User -GroupMemberObjectId $msoluser.ObjectId 
					break
				   }
	}
}
#>