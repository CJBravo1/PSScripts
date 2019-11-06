$usercsv = Import-Csv c:\import\NewLyncUsers.csv
ForEach ($usr in $usercsv)
{
#Grant-CsConferencingPolicy -Identity $usr.Identity -PolicyName "Standard Conferencing User" 
Grant-CsExternalAccessPolicy -Identity $usr.Identity -PolicyName "Allow Federation+Public+Outside Access"
}
