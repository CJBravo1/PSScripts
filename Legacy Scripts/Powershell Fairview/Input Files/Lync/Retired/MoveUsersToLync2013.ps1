$usercsv = Import-Csv C:\import\MoveLyncUsersTo2013.csv
ForEach ($usr in $usercsv)
{
Move-CsUser -Identity $usr.Identity -Target "lyncpoola.fairview.org" -confirm:$false
Write-Host "	The user " $usr.Identity " has been moved to Lync 2013"
}


exit
Start-Sleep -Seconds 20

$usercsv = Import-Csv C:\import\MoveLyncUsersTo2013.csv
ForEach ($usr in $usercsv)
{
# Grant-CsConferencingPolicy -Identity $usr.Identity -PolicyName "Allow A_V conferencing 1"
# Grant-CsConferencingPolicy -Identity $usr.Identity -PolicyName "Standard Conferencing User"
 
# Grant-CsExternalAccessPolicy -Identity $usr.Identity -PolicyName "Allow Federation+Public Access"
# Grant-CsExternalAccessPolicy -Identity $usr.Identity -PolicyName "Allow No Access"
}

Echo ""
Echo "New accounts have been modified with conferencing and external access policies"
Echo ""