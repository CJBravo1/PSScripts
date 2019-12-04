
$Computers = Get-Content 'C:\Users\U0155443\SkyDrive\Documents\Windows\Powershell\Ping_Hostlist.txt'
#$Error_Msg = Write-Host "$Computer is Offline!"

#Get all the computers in the domain
import-module activedirectory


$computers = Get-ADComputer -Filter *

$count = 0 
foreach ($Computer in $Computers) 
	{
	#Create and object to hold the results. Think of as on row in a CSV
	$csvline = New-Object PSObject
	Write-Host "Working on " $Computer.DistinguishedName
	
	$testresults = Test-Connection $Computer.Name -Count 1
	
	#If the results of test-connection are $null the computer did not respond
	If ($testresults -eq $null)
		{
		$csvline | Add-Member NoteProperty 'Computer Responded' ('No')	
		Write-host $Computer.Name " is offline" -BackgroundColor Red -ForegroundColor Yellow
		}
		else
		{
		$csvline | Add-Member NoteProperty 'Computer Responded' ('Yes')
		Write-host $Computer.Name " is online" -BackgroundColor blue -ForegroundColor White
		}
		

	$csvline | Add-Member NoteProperty 'ComputerName' ($Computer.Name)
	$csvline | Add-Member NoteProperty 'IPV4Address' ($testresults.IPV4Address)
	$csvline | Add-Member NoteProperty 'IPV6Address' ($testresults.IPV6Address)
	$csvline | Add-Member NoteProperty 'DNS Name' ($computer.DNSHostName)
	$csvline | Add-Member NoteProperty 'Computer DN' ($Computer.DistinguishedName)

	#add the columns to a sheet
	$csvsheet += @($csvline)	
	
	
	#increase the display counter by 1
	$count ++
	Write-Host "Processed " $count " computers"
	}

#export to a real csv
$csvsheet| Export-CSV c:\Users\U0155443\Desktop\csvsheet.csv  -NoTypeInformation