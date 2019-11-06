$Computers = Get-Content 'C:\Users\U0155443\SkyDrive\Documents\Windows\Powershell\Ping_Hostlist.txt'
$Still_ON = "Select-String -Pattern 'Received = 1"



foreach ($Computer in $Computers) 
{ #echo $Computer 
$ping_result = ping -n 1 $Computer | Select-String -Pattern 'Received = 1' -Quiet 
#Write-Host "$ping_result"

if ($ping_result -eq $Still_ON)
{ write-host "$Computer is still online" -ForegroundColor Green 
} 
else 
{ write-host "$Computer is Offline" -ForegroundColor Red }
}
Pause