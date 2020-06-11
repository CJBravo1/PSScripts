$Comp = "SERVERNAME"
$testconnection = Test-Connection -ComputerName $COMP -Count 1 -ErrorAction Stop

if ($testconnection -ne $null) 
	{
	Write-Host "Deepthought is Online" -ForegroundColor Green
	Write-Host "Unlocking Bitlocker Volumes"
	Write-Host "I need your AD Password" -ForegroundColor Yellow
	$cred = Get-Credential cyberdyne.com\cjorenby
	#$pass = Read-Host "I also need your Bitlocker Password" -AsSecureString
	$bitlockerVolumes = Invoke-Command -ComputerName $Comp -Credential $cred -ScriptBlock {Get-BitlockerVolume | Where-Object {$_.CapacityGB -eq "0"}}
	$unlockCommand = Invoke-Command -ComputerName $Comp -Credential $cred -ScriptBlock {Get-BitlockerVolume | Where-Object {$_.CapacityGB -eq "0"} | Unlock-Bitlocker -Password (Read-Host " I need your Bitlocker Password" -AsSecureString) -ErrorAction SilentlyContinue}
	Write-Host "The Following Drives are now unlocked" -ForegroundColor Green
	Write-Host $unlockCommand
	}
else 
	{
	Write-Host "Deepthought is offline. Unable to unlock bitlocker drives" -BackgroundColor Red -ForegroundColor Yellow
	}
pause