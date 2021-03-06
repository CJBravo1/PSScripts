#UPNchange.ps1
#Created by Regan Vecera
#Date: 7/1/2017

#Code for changing the UPN suffix for users acquired during acquistion
#WARNING : only running this code will probably give users sign in/account issues
#if other AD fields are not also updated. 

cls
$oldSuffix = "OldCompanyName.com"
$newSuffix = "CompanyName.com"
Get-ADUser -filter {UserPrincipalName -like "*$oldSuffix*"} | ForEach-Object {
$newUpn = $_.UserPrincipalName.Replace($oldSuffix,$newSuffix)
$_ | Set-ADUser -UserPrincipalName $newUpn}