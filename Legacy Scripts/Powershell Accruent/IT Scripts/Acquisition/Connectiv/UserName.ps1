Import-Module ActiveDirectory


$Users = $null
$Users = Import-Csv ".\connectivusers.csv"

foreach($User in $Users)
{
	#Grab full name from CSV
    $DisplayName = $user.DisplayName
    $SAM = Get-ADUser -Filter "Name -eq '$DisplayName'"
    $SAM.userPrincipalName
    
    
} 