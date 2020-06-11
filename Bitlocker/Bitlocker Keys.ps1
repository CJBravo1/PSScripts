$testconnection = Test-Connection -ComputerName Deepthought -Count 1 -ErrorAction Stop
$Comp = "SERVERNAME"
if ($testconnection -ne $null) 
	{
	#Test Connectivity and Get Credentails
	Write-Host "I need your AD Password" -ForegroundColor Yellow
	$cred = Get-Credential cyberdyne.com\cjorenby
	Switch ($lockUnlock = Read-Host "1.Lock or 2.Unlock Bitlocker Drives?" )
		{
	
	
	
	
	
	
	#Lock Drives
		1 {
		Write-Host "Which drive do you want to lock?" -ForegroundColor Yellow
		switch ($Drive = Read-Host "(I)mages, (B)ackup, or (A)ll")
			{
			I
				{
				$lock = Invoke-Command -ComputerName $Comp -Credential $cred -ScriptBlock {manage-bde -lock I: -ForceDismount}
				Write-Host "Images Harddrive is now locked" -ForegroundColor Green
				$respond ++
				}
			B
				{
				Invoke-Command -ComputerName $Comp -Credential $cred -ScriptBlock {manage-bde -lock B: -ForceDismount
				Write-Host "Backup Harddrive is now locked" -ForegroundColor Green
				$respond ++}
				}
			A
				{
				Invoke-Command -ComputerName $Comp -Credential $cred -ScriptBlock {manage-bde -lock I: -ForceDismount}
				Invoke-Command -ComputerName $Comp -Credential $cred -ScriptBlock {manage-bde -lock B: -ForceDismount}
				Write-Host "Images and Backup Drives are now Locked" -ForegroundColor Green
				}
			$Null
				{
				Write-Host "Please specify which drive"
				pause
				Clear-Host
				}
			}
		Write-Host "Script will now end"
		pause
		exit
	
		}
	
	2
		{
		Write-Host "Unlocking Bitlocker Volumes"
		$bitlockerVolumes = Invoke-Command -ComputerName $Comp -Credential $cred -ScriptBlock {Get-BitlockerVolume | Where-Object {$_.CapacityGB -eq "0"}}
		$unlockCommand = Invoke-Command -ComputerName $Comp -Credential $cred -ScriptBlock {Get-BitlockerVolume | Where-Object {$_.CapacityGB -eq "0"} | Unlock-Bitlocker -Password (Read-Host " I need your Bitlocker Password" -AsSecureString) -ErrorAction SilentlyContinue}
		Write-Host "The Following Drives are now unlocked" -ForegroundColor Green
		Write-Host $unlockCommand
		}
	}
}
else 
	{
	Write-Host "Deepthought is offline. Unable to unlock bitlocker drives" -BackgroundColor Red -ForegroundColor Yellow
	}
pause