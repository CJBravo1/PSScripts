#Import Active Directory
try {Import-Module ActiveDirectory}
Catch {"Active Directory Module is not available"}

#Import CSV File
$Userlist = Import-Csv C:\temp\EdmentumUsers.csv

#Start Loop
foreach ($user in $Userlist)
{
    #$ADUser = Get-ADUser -Identity $user.UserPrincipalName
    $proxyAddress = $user.NewPrimarySmtpAddress
    $proxyAddress = "smtp:$proxyAddress"
    Write-Host "@{proxyaddresses=$ProxyAddress}" -ForegroundColor Green
    #Set-ADUser -Identity $ADUser.distinguishedname -Add @{proxyaddresses=$([string]$ProxyAddress)}

}