$Users = $null
$Users = Get-Content .\userlist.txt

# Load the AD modules
Import-Module ActiveDirectory

foreach ($User in $Users)
    {
        $Account = $User
		Set-adUser $Account -Replace @{msExchHideFromAddressLists="TRUE"}
    }