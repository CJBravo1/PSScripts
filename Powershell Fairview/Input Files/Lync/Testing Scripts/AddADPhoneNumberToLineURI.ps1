
$enabledUsers = Get-CsUser -filter {ConferencingPolicy -eq "Allow A_V conferencing 1" -and LineURI -eq $null} | Get-CsADUser

 
foreach ($user in $enabledUsers)

    {

        $phoneNumber = $user.Phone

        $phoneNumber = $phoneNumber -replace "[^0-9]"
	$phoneNumber = $phoneNumber.Substring(3,7)

        $phonenumber = "TEL:+16123138777;ext=" + $phoneNumber
	echo $user.identity, $phonenumber
	

        Set-CsUser -Identity $user.Identity -LineUri $phoneNumber

    } 
