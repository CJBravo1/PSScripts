Write-Host "Creating Directory C:\Temp" -ForegroundColor Red
mkdir C:\temp

Write-Host "Getting Active Directory User Accounts" -ForegroundColor Magenta
$ADUsers = Get-Aduser -Filter * -Properties *

Write-Host "Exporting CSV to C:\Temp\ADUsers.csv" -ForegroundColor Cyan
$Adusers = $Adusers | select Name,Displayname,SamAccountName,EmailAddress,Enabled
$Adusers | Export-Csv -NoTypeInformation C:\temp\ADusers.csv

Write-Host "Active Directory User List Exported to C:\temp\ADusers.csv" -ForegroundColor Green