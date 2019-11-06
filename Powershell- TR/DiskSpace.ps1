
###########################################################################
#
# NAME: Disk Space
#
# AUTHOR:  Chris Jorenby
#
# COMMENT: To assist anyone working on Zipper errors.
#
# VERSION HISTORY:
# 1.0 10/07/2013
#
#       
###########################################################################


write-host "##################################################
#              !Disk Space!                      #
#         Checking C: drive Space                #
#     For best Results use FQDN or IP Address    #
##################################################" -ForegroundColor Green


$computer_list = Get-Content  'C:\Users\U0155443\SkyDrive\Documents\Windows\Powershell\Ping_Hostlist.txt'
$CredTLR = Get-Credential -Credential TLR\M0155443
$CredMGMT = Get-Credential -Credential MGMT\M0155443
$count = 0
$Line = 1
$ErrorActionPreference = "SilentlyContinue"
Write-Host "Hostlist has " $computer_list.count " hosts"

foreach ($computer in $computer_list)
	{
	$csvline = New-Object PSObject
	$diskResult_C = Get-WmiObject Win32_LogicalDisk -ComputerName "$computer" -Credential $CredTLR -Filter {DeviceID = 'C:'} -ErrorAction SilentlyContinue 
	$diskResult_D = Get-WmiObject Win32_LogicalDisk -ComputerName "$computer" -Credential $CredTLR -Filter {DeviceID = 'D:'} -ErrorAction SilentlyContinue
	$PingResult = Test-Connection $Computer  -Count 1 -ErrorAction SilentlyContinue
	$diskResult_CMB = [Math]::Truncate($diskResult_C.FreeSpace /1MB)
	$diskResult_DMB = [Math]::Truncate($diskResult_D.FreeSpace /1MB)
	
	if ($diskResult_CMB -eq 0)
		{
		$csvline | Add-Member NoteProperty "Response" ("No Space Free")
		$csvline | Add-Member NoteProperty "Hostname" ($computer)
		$csvline | Add-Member NoteProperty "IP Address" ($PingResult.IPV4Address)
		$csvline | Add-Member NoteProperty "C: DiskSpace" ("$diskResult_CMB MB")
		$csvline | Add-Member NoteProperty "D: DiskSpace" ("$diskResult_DMB MB")
		Write-Host $Line". " $computer "has" $diskResult_CMB "MB free. Please Free up Space or test the connectivity of the server" -BackgroundColor Red -ForegroundColor Yellow
		}
	elseif ($diskResult_CMB -lt 400)
		{
		$csvline | Add-Member NoteProperty "Response" ("Less than 400MB")
		$csvline | Add-Member NoteProperty "Hostname" ($computer)
		$csvline | Add-Member NoteProperty "IP Address" ($PingResult.IPV4Address)
		$csvline | Add-Member NoteProperty "DiskSpace" ("$diskResult_CMB MB")
		$csvline | Add-Member NoteProperty "D: DiskSpace" ("$diskResult_DMB MB")
		Write-Host $Line". " $computer "has" $diskResult_CMB "MB free. Please Free up Space" -BackgroundColor DarkGreen -ForegroundColor White
		}
	else
		{
		$csvline | Add-Member NoteProperty "Response" ("More than 400MB")
		$csvline | Add-Member NoteProperty "Hostname" ($computer)
		$csvline | Add-Member NoteProperty "IP Address" ($PingResult.IPV4Address)
		$csvline | Add-Member NoteProperty "DiskSpace" ("$diskResult_CMB MB")
		$csvline | Add-Member NoteProperty "D: DiskSpace" ("$diskResult_DMB MB")
		Write-Host $Line". " $computer "has" $diskResult_CMB "MB free." -BackgroundColor DarkBlue -ForegroundColor White
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