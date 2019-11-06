$Computers = Get-Content 'C:\Users\U0155443\SkyDrive\Documents\Windows\Powershell\Ping_Hostlist.txt'
$Error_Msg = Write-Host "$Computer is Offline!"


foreach ($Computer in $Computers) 
{
Test-Connection $Computer -Count 1  | Select-Object Address,ProtocolAddress 
}

