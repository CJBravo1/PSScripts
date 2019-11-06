#GetADProperties.ps1
#Created by Regan Vecera
#Date: 11/27/2017

# This code will gather information for the selected users in the csv
# Use the variable $format as a template if you wish to add more properties

cls

$export = ".\TermedUserInfo.csv"

#Search based on OU
Get-ADUser -filter * -SearchBase "ou=acc_Domain_Users, dc=accruent, dc=com"| ForEach-Object {
	$user = get-aduser $_ -Properties *
	#if($user.Enabled -eq "True")
	#{
		$format = @{Expression={$user.DisplayName};Label="Display Name"},
 		   		  @{Expression={$user.SAMAccountName};Label="User name"},
				  @{Expression={$user.Enabled};Label="Enabled"}
				  
	#}
	 #Must use Select-Object instead of Format-Table as Format-Table would output a useless table object to the csv
 	 $_ | Select-Object -Property $format | Export-Csv -Path $export -Force -Append -NoTypeInformation
}


#Search based on CSV
<#
$csv = Import-csv ".\names.csv"
foreach($name in $csv)
{

	$UID = $name.Username
	$user = Get-ADUser -Identity $UID -Properties *
	
	#Grab only specific properties from ADUser and format them for export
	$format = @{Expression={$user.DisplayName};Label="Display Name"},
 		   @{Expression={$user.SAMAccountName};Label="User name"},
 		   @{Expression={$user.Enabled};Label="Enabled"}
		   
 #Must use Select-Object instead of Format-Table as Format-Table would output a useless table object to the csv
 $user | Select-Object -Property $format | Export-Csv -Path $export -Force -Append -NoTypeInformation
 
}
#>