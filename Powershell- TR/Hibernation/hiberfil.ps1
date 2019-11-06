

#Get Credentials
$MAccount = Get-Credential



#Get Hostlist 
$Hostlist = Get-Content 'c:\Users\U0155443\SkyDrive\Documents\Windows\Powershell\Hibernation\Hibernation hostlist.txt'
#echo $Hostlist


ForEach ( $ObjHostlist in $Hostlist ) {


#Enter PowerShell-Session
Invoke-Command -ComputerName $ObjHostlist -Credential $MAccount{

#Use to get Hibernation file
Get-ChildItem -Force c:\ | Where-Object {$_.Name -eq 'hiberfil.sys'} | Select-Object name, length

#sleep -seconds 10
} | Export-Csv -Path 'c:\Users\U0155443\SkyDrive\Documents\Windows\Powershell\Hibernation\hiberfil.csv' -Append
}
#
Invoke-Item c:\Users\U0155443\SkyDrive\Documents\Windows\Powershell\Hibernation\hiberfil.csv



