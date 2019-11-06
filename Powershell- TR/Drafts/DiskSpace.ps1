$computer_list = Get-Content  'C:\Users\U0155443\SkyDrive\Documents\Windows\Powershell\Ping_Hostlist.txt'
$CredTLR = Get-Credential -Credential TLR\M0155443

foreach ($computer in $computer_list){
	try	{
	$csvline = New-Object PSObject
	$Drive_Space = Get-WmiObject Win32_LogicalDisk -ComputerName "$computer" -Credential $CredTLR -ErrorAction SilentlyContinue | Where-Object {$_.DeviceID -eq "C:"} 
	$Hostname = $computer
	
	Write-Host $computer -ForegroundColor Green
	$Drive_Space | Select-Object FreeSpace | Format-list 
	
	$csvline | Add-member NoteProperty 'Computer Name' ("$computer")
	
	$csvline | Add-Member NoteProperty 'Disk Space' ("$Drive_Space")
	
	
	$csvsheet += @($csvline)
	
	}
	catch{ write-host "$computer" has failed -ForegroundColor Red
	$csvline | Add-Member NoteProperty 'Failed' ($computer)}
	
	$csvsheet += @($csvline)
	}
	
	
	
	
	$csvsheet | Export-CSV c:\Temp\DriveSize.csv
	Invoke-Item c:\Temp\DriveSize.csv
	