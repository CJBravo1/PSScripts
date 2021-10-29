Import-Module ActiveDirectory

$ADGroups = Get-ADGroup -filter *
foreach ($group in $adgroups) 
{
    mkdir "ADGroup Export"
    cd ".\ADGroup Export"
    $adgroup = $group.SamAccountName
    Get-ADGroupMember -Identity $adgroup | Export-Csv -NoTypeInformation ".\$adgroup.csv"
}
