
write-host "##################################################
#              !Disk Space!                      #
#         Checking C: drive Space                #
#     For best Results use FQDN or IP Address    #
##################################################" -ForegroundColor Green

#Get Computer list and credentials
$computer_list = Get-Content  'C:\Temp\virtualC.txt'
#$Cred = Get-Credential -Credential
$count = 0
$Line = 1
$ErrorActionPreference = "SilentlyContinue"
Write-Host "Hostlist has " $computer_list.count " hosts"


foreach ($computer in $computer_list)
	{
	#create new object and gather computer / disk information
	$csvline = New-Object PSObject
	$diskResult_C = Get-WmiObject Win32_LogicalDisk -ComputerName "$computer" -Credential $CredTLR -Filter {DeviceID = 'C:'} -ErrorAction SilentlyContinue 
	#$diskResult_D = Get-WmiObject Win32_LogicalDisk -ComputerName "$computer" -Credential $CredTLR -Filter {DeviceID = 'D:'} -ErrorAction SilentlyContinue
	$PingResult = Test-Connection $Computer  -Count 1 -ErrorAction SilentlyContinue
	$diskResult_CMB = [Math]::Truncate($diskResult_C.FreeSpace /1GB)
	#$diskResult_DMB = [Math]::Truncate($diskResult_D.FreeSpace /1MB)
	
	if ($diskResult_CMB -eq 0)
		{
		$csvline | Add-Member NoteProperty "Response" ("No Space Free")
		$csvline | Add-Member NoteProperty "Hostname" ($computer)
		$csvline | Add-Member NoteProperty "IP Address" ($PingResult.IPV4Address)
		$csvline | Add-Member NoteProperty "C: DiskSpace" ("$diskResult_CMB GB")
		#$csvline | Add-Member NoteProperty "D: DiskSpace" ("$diskResult_DMB GB")
		Write-Host $Line". " $computer "has" $diskResult_CMB "GB free. Please Free up Space or test the connectivity of the server" -BackgroundColor Red -ForegroundColor Yellow
		}
	elseif ($diskResult_CMB -lt 20)
		{
		$csvline | Add-Member NoteProperty "Response" ("Less than 20GB")
		$csvline | Add-Member NoteProperty "Hostname" ($computer)
		$csvline | Add-Member NoteProperty "IP Address" ($PingResult.IPV4Address)
		$csvline | Add-Member NoteProperty "DiskSpace" ("$diskResult_CMB GB")
		#$csvline | Add-Member NoteProperty "D: DiskSpace" ("$diskResult_DMB GB")
		Write-Host $Line". " $computer "has" $diskResult_CMB "GB free. Please Free up Space" -BackgroundColor DarkGreen -ForegroundColor White
		}
	else
		{
		$csvline | Add-Member NoteProperty "Response" ("More than 20GB")
		$csvline | Add-Member NoteProperty "Hostname" ($computer)
		$csvline | Add-Member NoteProperty "IP Address" ($PingResult.IPV4Address)
		$csvline | Add-Member NoteProperty "DiskSpace" ("$diskResult_CMB GB")
		#$csvline | Add-Member NoteProperty "D: DiskSpace" ("$diskResult_DMB GB")
		Write-Host $Line". " $computer "has" $diskResult_CMB "GB free." -BackgroundColor DarkBlue -ForegroundColor White
		}
		
	
	$count ++
	$Line ++
	$csvsheet += @($csvline)
	Clear-Variable diskResult_CMB
	Clear-Variable diskResult_DMB
	}
Write-Host "Processed " $count " hosts"

if (Test-Path 'C:\Temp\diskspace.csv') {
      Remove-Item 'C:\Temp\diskspace.csv' -Force}

$csvsheet | Export-Csv C:\Temp\diskspace.csv -NoTypeInformation
Invoke-Item C:\Temp\diskspace.csv

pause