$import = Import-Csv -Path "C:\Scripts\ManagerChange.csv"

ForEach ($user in $import) {
	$user2 = $user.username
	$manager = $user.manager
	
	Set-ADUser -Identity "$user2" -Manager "$manager"
	Write-Host "Set" $User2 "'s manager to " $manager "."
	}
	
Write-Host "Press any key to continue ..."

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")