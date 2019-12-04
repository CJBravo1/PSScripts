get-wmiobject win32_logicaldisk -credential tlr\m0155443 -ComputerName(Get-Content "C:\Users\U0155443\SkyDrive\Documents\Windows\Powershell\Ping_Hostlist.txt") | 
	Select-Object SystemName,DeviceId,@{Label='Free Space'; Expression={[math]::truncate($_.freespace / 1MB)}},`
	@{Label='Total Drive Space'; Expression={[math]::truncate($_.size / 1MB)}} | 
	Export-Csv "C:\Users\U0134203\Desktop\PowerShell Repository\Get_C_D _FREE\totals.csv"