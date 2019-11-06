if ( Test-Path 'c:\Temp\Zipper.csv' ) { 
	Remove-Item 'c:\Temp\Zipper.csv' -Force -ErrorAction SilentlyContinue }

	


$Zipper = Get-Content 'C:\Users\U0155443\SkyDrive\Documents\Windows\Powershell\Zipper\Zipper.txt' 

$Zipper = $Zipper -replace 'Details ',''

$Zipper	> c:\Temp\Zipper.txt

$Zipper_csv = Import-Csv c:\Temp\Zipper.txt -Delimiter ':' -Header "IP Address","Hostname","Error" 

#####################################################################################################
#Ping Machine#
#####################################################################################################
$computerstatus = $null
foreach ($HostComp in $Zipper_csv) 
	{
	$computerstatus = 	Test-Connection $HostComp.Hostname -Count 1
		if ($computerstatus -ne $null)
			{
			Write-Host "The Comptuer " $computerstatus.Destination
			} 
		else
			{
			Write-Host "Could not Contact " $HostComp
			}
	}




$Zipper_csv | Export-Csv -Path c:\Temp\Zipper.csv -NoTypeInformation






#foreach ($Hostname in $Zipper_csv)
#{Write-Host "$Hostname"}



Invoke-Item c:\Temp\Zipper.csv

