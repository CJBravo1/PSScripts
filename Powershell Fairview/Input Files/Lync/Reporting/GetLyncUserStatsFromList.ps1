$temp = $null
$usercsv = Import-Csv C:\import\LyncUsersToReport.csv
ForEach ($usr in $usercsv)
{
If (get-csuser -Identity $usr.Identity)
 
{
$temp += ,(get-csuser -Identity $usr.Identity | where {$_.RegistrarPool -like "lyncpool*"} | select samaccountname,registrarpool,conferencingpolicy )
}
}

$path = $temp | export-csv c:\export\LyncUserDetails.csv -noType 