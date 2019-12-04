###########################################################################
#
# NAME: ZipperTool
#
# AUTHOR:  Dustin Giles
#
# COMMENT: To assist anyone working on Zipper errors.
#
# VERSION HISTORY:
# 1.0 1/15/2013 - Initial Release - Dustin Giles
#
#
###########################################################################







$a = New-Object -comobject Excel.Application
$a.visible = $True

$b = $a.Workbooks.Add()
$c = $b.Worksheets.Item(1)

$c.Cells.Item(1,1) = “IP Address”
$c.Cells.Item(1,2) = “Server Name”
$c.Cells.Item(1,3) = “Zipper Error”
$c.Cells.Item(1,4) = “Decommission - Brief Description”
$c.Cells.Item(1,5) = “Status”
$c.Cells.Item(1,6) = “IP Address in Service Manager”
$c.Cells.Item(1,7) = “Possible Name”

$c.Cells.Item(1).columnWidth = 12
$c.Cells.Item(2).columnWidth = 23
$c.Cells.Item(3).columnWidth = 80
$c.Cells.Item(4).columnWidth = 92
$c.Cells.Item(5).columnWidth = 32
$c.Cells.Item(6).columnWidth = 32
$c.Cells.Item(7).columnWidth = 32
$d = $c.UsedRange
$d.Interior.ColorIndex = 19
$d.Font.ColorIndex = 11
$d.Font.Bold = $True


$intRow = 2
$numbercounter = 0
$zero = 0

$WhereZipperReport_In = Get-Location

Write-Host $WhereZipperReport_In

$PathInFile = "$WhereZipperReport_In\ZipperReport_In.txt"


#Checks if ZipperReport_In is in current location
#If file is not in current location it is created and 
#script is exited and user is prompted to add data to file
#---------------------------------------------------------
If(-not(Test-Path -path $PathInFile))
  {


 New-Item -Path $PathInFile -ItemType file -Value ZipperReport_In.txt -force


"File did not exist. File was created named ZipperReport_In.txt. Please Re-Run when error report is added in ZipperReport_In.txt" ; exit
  }


(Get-Content ZipperReport_In.txt) | 
Foreach-Object {$_ -replace "Details", ""} | 
Set-Content ZipperReport_In.txt



Get-Content "$WhereZipperReport_In\ZipperReport_In.txt" | Foreach-Object{
	

	$var = $_.Split(':')

   	#New-Variable -Name $var[0] -Value $var[2]
	
	$asset = $var[1].Trim()
	
	$c.Cells.Item($intRow, 1) = $var[0]
	$c.Cells.Item($intRow, 2) = $asset #$var[1]
	$c.Cells.Item($intRow, 3) = $var[2]
	#$c.Cells.Item($intRow, 4) = $objRecordset.Fields.Item("Brief_desc").Value
	#$c.Cells.Item($intRow, 5) = $objRecordset.Fields.Item("Assignee").Value
	
	$asset = $asset -replace 'RA-',''
	$asset = $asset -replace '.tlr.thomson.com',''
	$asset = $asset -replace '.int.thomsonreuters.com',''
	$asset = $asset -replace '.delphion.com',''
	$asset = $asset -replace ' ilo',''
	$asset = $asset -replace '.tfn.com',''
	$asset = $asset -replace '-oob',''
	$asset = $asset -replace 'RA_',''
	
	$possibleAssetName = "%"+$asset+"%"
	$numbercounter = $numbercounter + 1
	write-host $numbercounter 
	write-host $asset
	$CR_ChangeType = ""
	


$adOpenStatic = 3
$adLockOptimistic = 3

$objConnection = New-Object -comobject ADODB.Connection
$objRecordset = New-Object -comobject ADODB.Recordset

#SQL?
$objConnection.Open("Provider=SQLOLEDB.1;Password=sm_reports;Persist Security Info=True;User ID=sm_reports;Initial Catalog=sm_shadow;Data Source=smshadow-prod, 1433")
if($objConnection.state -eq 0){   
	write-host '0:Could not establish connection'   exit 1 
}

$objRecordset.Open("select logical_name,DATE_ENTERED, CLOSE_TIME, NUMBER_STRING, BRIEF_DESCRIPTION,CM3RM4.closing_comments, wg_change_type from CM3RM1 INNER join CM3RM4 on CM3RM1.Number = CM3RM4.Number where CM3RM1.logical_name = '$asset'", $objConnection,$adOpenStatic,$adLockOptimistic)



if($objRecordset.EOF -eq $True)
{
	write-host '0:No Data found'   #exit 2 
}


while (!($objRecordset.EOF)){

	$CR_ChangeType = $objRecordset.Fields.Item("wg_change_type").Value
	IF ($CR_ChangeType -eq "Decommission"){
	
		$CR_ID = $objRecordset.Fields.Item("NUMBER_STRING").Value
		$CR_Asset = $objRecordset.Fields.Item("logical_name").Value
		$CR_ChangeType = $objRecordset.Fields.Item("wg_change_type").Value
		$CR_BriefDesc = $objRecordset.Fields.Item("BRIEF_DESCRIPTION").Value
		$CR_CloseTime = $objRecordset.Fields.Item("CLOSE_TIME").Value
	
		Write-Host "$CR_Asset - $CR_ID - $CR_ChangeType"
		$c.Cells.Item($intRow, 4) = "$CR_ID - $CR_ChangeType - $CR_BriefDesc - Close Time:$CR_CloseTime"
	}
$objRecordset.MoveNext()
}

$objRecordset.Close()
$objConnection.Close()

$adOpenStatic = 3
$adLockOptimistic = 3

$objConnection = New-Object -comobject ADODB.Connection
$objRecordset = New-Object -comobject ADODB.Recordset

$objConnection.Open("Provider=SQLOLEDB.1;Password=sm_reports;Persist Security Info=True;User ID=sm_reports;Initial Catalog=sm_shadow;Data Source=smshadow-prod, 1433")
if($objConnection.state -eq 0){   
	write-host '0:Could not establish connection'   
	exit 1 
}
$objRecordset.Open("Select Network_address, location, istatus from devicem1 where DEVICEM1.logical_name='$asset'", $objConnection,$adOpenStatic,$adLockOptimistic)



# *********** Check if there are records *******************
if($objRecordset.EOF -eq $True){

write-host '0:No Data found'   #exit 2

} 
$c.Cells.Item($intRow, 5) = $objRecordset.Fields.Item("istatus").Value
$c.Cells.Item($intRow, 6) = $objRecordset.Fields.Item("Network_address").Value

$objRecordset.Close()
$objConnection.Close()


$adOpenStatic = 3
$adLockOptimistic = 3

$objConnection = New-Object -comobject ADODB.Connection
$objRecordset = New-Object -comobject ADODB.Recordset

$objConnection.Open("Provider=SQLOLEDB.1;Password=sm_reports;Persist Security Info=True;User ID=sm_reports;Initial Catalog=sm_shadow;Data Source=smshadow-prod, 1433")
if($objConnection.state -eq 0){   
	write-host '0:Could not establish connection'   
	exit 1 
}
$objRecordset.Open("Select Network_address, location, istatus, logical_name from devicem1 where DEVICEM1.logical_name like'$possibleAssetName'", $objConnection,$adOpenStatic,$adLockOptimistic)



# *********** Check if there are records *******************
if($objRecordset.EOF -eq $True){

write-host '0:No Data found'   #exit 2

} 
$c.Cells.Item($intRow, 7) = $objRecordset.Fields.Item("logical_name").Value

$objRecordset.Close()
$objConnection.Close()



$intRow = $intRow + 1

}

