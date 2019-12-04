$computer_list = Get-Content  'C:\Users\U0155443\SkyDrive\Documents\Windows\Powershell\Ping_Hostlist.txt'
$CredTLR = Get-Credential -Credential TLR\M0155443
$count = 0
Write-Host "Hostlist has " $computer_list.count " hosts"

foreach ($computer in $computer_list)
	{
	$csvline = New-Object PSObject
	$diskResult = Get-WmiObject Win32_LogicalDisk -ComputerName "$computer" -Credential $CredTLR -ErrorAction SilentlyContinue -Amended | Where-Object {$_.DeviceID -eq "C:"} | Select-Object FreeSpace | Format-List
	
	try
		{
		$csvline | Add-Member NoteProperty "Hostname" ($computer)
		$csvline | Add-Member NoteProperty "DiskSpace" ($diskResult)
		Write-Host $computer "has " $diskResult -BackgroundColor Blue -ForegroundColor White
		}
	catch
		{ 
		write-host $computer " is denying access or cannot respond. Please test connectivity or try another password" -ForegroundColor Yellow -BackgroundColor Red 
		}
	
	$count ++
	
	$csvsheet += @($csvline)
	
	}
Write-Host "Processed " $count " hosts"

if (Test-Path 'C:\Temp\diskspace.csv') 
	{
      Remove-Item 'C:\Temp\diskspace.csv' -Force
	}

$csvsheet | Export-Csv C:\Temp\diskspace.csv -NoTypeInformation
Invoke-Item C:\Temp\diskspace.csv

pause