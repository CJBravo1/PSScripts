Import-Module ActiveDirectory
$Users = $null
$Users = Import-CSV -Path "c:\temp\users.csv"
foreach ($User in $Users)
{
Set-ADUser $User.name -StreetAddress "10900-B Stonelake Blvd, Suite 200" -City "Austin" -State "TX" -PostalCode "78759"
}