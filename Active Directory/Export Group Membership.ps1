$User = Read-Host "Who's Group Membership do you want to export?"

Get-ADPrincipalGroupMembership $User | select name 

Get-ADPrincipalGroupMembership $User | select name | Export-CSV "\\accruent.com\fs\Departments\IT\Group Membership Exports\$User.csv"

Write-Host "Press any key to continue ..."

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")