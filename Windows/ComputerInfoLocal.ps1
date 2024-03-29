###########################################################################
#
# NAME: Comp Info
#
# AUTHOR:  Chris Jorenby
#
#
# VERSION HISTORY:
# 1.0
#
#       
###########################################################################




write-host "##################################################
#              !Local Machine Info!              #
#     Gather System Information on any Server    #    
##################################################" -ForegroundColor Green
#Remove All Error Messages
$ErrorActionPreference = 'SilentlyContinue'

Write-Host "Gathering Informaiton!" -ForegroundColor Yellow
#$cred = Get-Credential verisae\vtech




$testConnection = Test-Connection -ComputerName $remoteHost -Count 1 -ErrorAction SilentlyContinue
$csvline = New-Object PSObject
	#Get Operating System
	$Win32 = Invoke-Command -ScriptBlock {Get-WmiObject Win32_ComputerSystem -ErrorAction SilentlyContinue}
	$operatingSystem = Get-WmiObject Win32_OperatingSystem 
	$OSName = $operatingSystem.Caption
	$Processor = $operatingSystem.OSArchitecture
	$BIOS = Get-WmiObject Win32_bios 
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
	$Serial = $BIOS.SerialNumber
	#Get Drive Space
	$diskResult_C = Get-WmiObject Win32_LogicalDisk -ComputerName $remoteHost -Credential $cred -Filter {DeviceID = 'C:'} -ErrorAction SilentlyContinue 
	#$diskResult_D = Get-WmiObject Win32_LogicalDisk -ComputerName $remoteHost -Credential $cred -Filter {DeviceID = 'D:'} -ErrorAction SilentlyContinue
	$diskResult_CMB = [Math]::Truncate($diskResult_C.FreeSpace /1GB)
	$diskResult_DMB = [Math]::Truncate($diskResult_D.FreeSpace /1MB)
	
	#Output
	$csvline | Add-Member NoteProperty "Computer Name" ($Name)
	$csvline | Add-Member NoteProperty "Domain" ($Domain)
	$csvline | Add-Member NoteProperty "IP Address" ($ipAddress)
	$csvline | Add-Member NoteProperty "Hardware Make" ($Make)
	$csvline | Add-Member NoteProperty "Hardware Model" ($Model)
	$csvline | Add-Member NoteProperty "Hardware Serial" ($Serial)
	$csvline | Add-Member NoteProperty "Operating System" ($OSName)
	$csvline | Add-Member NoteProperty "Processor" ($Processor)
	$csvline | Add-Member NoteProperty "Last Boot" ($lastBoot)
	#$csvline | Add-Member NoteProperty "Uptime in Days" ($uptime)
	$csvline | Add-Member NoteProperty "Remaining C: in GB" ($diskResult_CMB)
	#$csvline | Add-Member NoteProperty "Remaining D:" ($diskResult_DMB)
	
	$csvline 
	


Write-Host "Script will now Exit" 
pause 