$usercsv = Import-Csv C:\import\NewLyncUsers.csv
ForEach ($usr in $usercsv)
{
Enable-CsUser -Identity $usr.Identity -RegistrarPool lyncpool1.fairview.org -SipAddressType SAMAccountName -SipDomain fairview.org 
#Write-Host "	The user " $usr.Identity " enabled for LS2010 "
}

