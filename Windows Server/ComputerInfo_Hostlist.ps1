write-host "##################################################
#              !Machine Info!                    #
#     Gather System Information on any Server    #    
#     For best Results use FQDN or IP Address    #
##################################################" -ForegroundColor Green
#Remove All Error Messages
$ErrorActionPreference = 'SilentlyContinue'

$hostlist = Get-Content 'c:\temp\Hostlist.txt'

Write-Host "I need your Credentials" -ForegroundColor Yellow
$cred = Get-Credential -Message "I need your Credentials to Continue"
Write-Host "Hostlists holds " $hostlist.count "hosts" -ForegroundColor Yellow

foreach ($remoteHost in $hostlist)
{
Write-Host "Finding"$remoteHost -ForegroundColor Green

#Write-Host "Enter Computername/FQDN/or IP Address" -ForegroundColor Yellow
#$remoteHost = Read-Host 

$testConnection = Test-Connection -ComputerName $remoteHost -Count 1 -ErrorAction SilentlyContinue
$csvline = New-Object PSObject
if ($null -ne $testConnection)
	{
	#$hostlistname = $hostlist[1]
	#Get Operating System
	$Win32 = Invoke-Command -ComputerName $remoteHost -Credential $cred -ScriptBlock {Get-WmiObject Win32_ComputerSystem -ErrorAction SilentlyContinue}
	$operatingSystem = Get-WmiObject Win32_OperatingSystem -ComputerName $remoteHost -Credential $cred 
	$OSName = $operatingSystem.Caption
	#When was the computer turned on
	$lastBoot = $operatingSystem.ConvertToDateTime($operatingSystem.LastBootupTime)
	#$uptime = [datetime]::Now.CompareTo($lastboot)
	#What is the computers Name/Address
	$Name = $Win32.Name
	$Domain = $Win32.Domain
	$ipAddress = ($testConnection.IPV4Address).IPAddressToString
	#Hardware Information
	$Make = $Win32.Manufacturer
	$Model = $Win32.Model
	#Get Drive Space
	$diskResult_C = Get-WmiObject Win32_LogicalDisk -ComputerName $remoteHost -Credential $cred -Filter {DeviceID = 'C:'} -ErrorAction SilentlyContinue 
	$diskResult_D = Get-WmiObject Win32_LogicalDisk -ComputerName $remoteHost -Credential $cred -Filter {DeviceID = 'D:'} -ErrorAction SilentlyContinue
	$diskResult_CMB = [Math]::Truncate($diskResult_C.FreeSpace /1GB)
	$diskResult_DMB = [Math]::Truncate($diskResult_D.FreeSpace /1MB)
	
	#Output
	$csvline | Add-Member NoteProperty "Hostlist Name" ($remotehost)
	$csvline | Add-Member NoteProperty "Computer Name" ($Name)
	$csvline | Add-Member NoteProperty "Domain" ($Domain)
	$csvline | Add-Member NoteProperty "IP Address" ($ipAddress)
	$csvline | Add-Member NoteProperty "Hardware Make" ($Make)
	$csvline | Add-Member NoteProperty "Hardware Model" ($Model)
	$csvline | Add-Member NoteProperty "Operating System" ($OSName)
	$csvline | Add-Member NoteProperty "Last Boot" ($lastBoot)
	#$csvline | Add-Member NoteProperty "Uptime in Days" ($uptime)
	$csvline | Add-Member NoteProperty "Remaining C: in GB" ($diskResult_CMB)
	#$csvline | Add-Member NoteProperty "Remaining D:" ($diskResult_DMB)
	
	$csvline 
	}
else
	{
	Write-Host $remoteHost "Does not respond." -ForegroundColor Red
	}

$csvsheet += @($csvline)

}




if (Test-Path 'C:\Temp\compinfo.csv') {
      Remove-Item 'C:\Temp\compinfo.csv' -Force}

$csvsheet | Export-Csv C:\Temp\compinfo.csv -NoTypeInformation

#pause
Invoke-Item C:\Temp\compinfo.csv

Write-Host "Script will now Exit" 
pause