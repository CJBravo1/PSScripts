# Import Active Directroy module. Duh.
IMPORT-MODULE ActiveDirectory

# Import CSV file with user's display names. Column A, First Name. Column B, Last Name.
$names = import-csv -path .\managerdlupdate2.csv

# Loop to pull in each user and get username info.
foreach ($name in $names ) {

# Creates a filter to find the User's Display name off of First and Last name.
$Filter = "givenName -like ""*$($name.FirstName)*"" -and sn -like ""$($name.lastname)"""

#Gets User information. Select-Object only selects the properties listed behind it. 
$user = Get-AdUser -Filter $filter -Properties * | Select-Object sAMAccountName | Export-Csv .\output.csv -Append -NoTypeInformation



}


# This block of code will pause the PowerShell window and keep it up. This way you can go over what the script actually did, and not auto-close the window. 
Write-Host "Press any key to continue ..."

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")