write-Host "Removing Dell Software" -ForegroundColor Magenta
	#$dell = (Get-WmiObject Win32_Product | Where {$_.Vendor -eq "Dell Inc."})
	#foreach ($app in $dell) 
	#	{
	#	Write-Host $app.Name -ForegroundColor Blue
	#	$app.Uninstall()
	#	}
	#Remove Dell Protected Workspace
	$dellsec = (Get-WmiObject Win32_Product | Where {$_.Vendor -eq "Dell Inc."})
	Write-Host $dellsec.Name -ForegroundColor Blue
	$dellsec.Uninstall()