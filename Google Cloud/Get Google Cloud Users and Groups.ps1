#Get Google Users
$users = gam print users allfields | ConvertFrom-Csv
$users | Export-Csv -NoTypeInformation .\users.csv

#Get Google Groups
$Groups = gam print groups allfields | ConvertFrom-Csv
$Groups | Export-Csv -NoTypeInformation .\Groups.csv

#Get Google Group Memberships
$Groupname = $group.Name
foreach ($Group in $Groups)
{
    gam print group-members group $group.email  | ConvertFrom-Csv | Export-Csv -NoTypeInformation ".\Group Memberships\$groupname.csv"
}