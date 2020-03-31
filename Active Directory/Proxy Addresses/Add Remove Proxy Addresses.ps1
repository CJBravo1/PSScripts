#Add / Remove Proxy Address in Active Directory. 

#Import ActiveDirectory Module
Import-Module ActiveDirectory

#Set Variables
$Testusers = Get-ADUser -Filter * -Properties * -SearchBase "OU=Users,OU=Just1nWatts,DC=company,DC=Local"

foreach ($user in $testUsers) 
    {
    $userSAM = $User.SamAccountName.tostring()
    $newEmail = "$UserSAM@example.com"
    Set-ADUser -Identity $User.DistinguishedName -add @{ProxyAddresses="smtp:$newemail"}
    }
#Remove Proxy Address
$ProxyDomainAddress = "example.com"
foreach ($user in $testUsers) 
    {
    $testuserSAM = $testuser.SamAccountName.tostring()
    $testUserProxy = "smtp:$testuserSAM@$proxyDomainAddress"
    Set-ADUser -Identity $testuser.DistinguishedName -Remove @{ProxyAddresses="$testuserProxy"}
    }