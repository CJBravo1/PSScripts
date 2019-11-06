###########################################################################
#
# NAME: Comp Info
#
# AUTHOR:  Chris Jorenby
#
# COMMENT: To assist anyone working on Zipper errors.
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
	
	#Email Body
	$EmailBody = "
	"Computer Name" ($Name)
	"Domain" ($Domain)
	"IP Address" ($ipAddress)
	"Hardware Make" ($Make)
	"Hardware Model" ($Model)
	"Hardware Serial" ($Serial)
	"Operating System" ($OSName)
	"Processor" ($Processor)
	"Last Boot" ($lastBoot)
	"Uptime in Days" ($uptime)
	"Remaining C: in GB" ($diskResult_CMB)
	"Remaining D:" ($diskResult_DMB)
	"
	
	Send-MailMessage -From it@verisae.com -To cjorenby@verisae.com -Body "$EmailBody" -BodyAsHtml -SmtpServer mailrelay.verisae.int -Subject "TEST MAIL"

Write-Host "Script will now Exit" 
