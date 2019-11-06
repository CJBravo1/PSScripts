# file called with path specified after script name
# example: create_acquisition_users.ps1 c:\scripts\import_users.csv
$Users = $null
$Users = Import-Csv -Delimiter "," -Path $args[0]

# Set date for log file
$now = Get-Date -format "dd-MMM-yyyy HH:mm"
$now = $now.ToString().Replace(":","_") # change the : to a _
$now = $now.ToString().Replace(" ","_") # change the space to a _
$CSVfile = ".\forwarding_" + $now + ".csv" # set csv file name
$output = @()

foreach ($User in $Users)  
{
	$UID = $User.SamAccountName
	$mailbox = get-mailbox -identity $UID | select-object alias,forwardingaddress

	$userObj = New-Object PSObject

	$userObj | Add-Member NoteProperty -Name "Alias" -Value $mailbox.Alias
	$userObj | Add-Member NoteProperty -Name "Forwarding Address" -Value $mailbox.ForwardingAddress

	$output += $userObj
}

$output | Export-csv -Path $CSVfile -NoTypeInformation