Add-pssnapin Quest.ActiveRoles.ADManagement
Connect-qadservice -service 'SECT-ARS69-01.Fairview.org' -proxy

echo ""
echo ""

$usercsv = Import-Csv c:\import\AssignAVConfPolicy.csv
ForEach ($usr in $usercsv)
{
#
# Add user to the Lync "Allow A_V Conferencing 1" policy
#

Grant-CsConferencingPolicy -Identity $usr.Identity -PolicyName "Allow A_V conferencing 1" 
# }


#
#Look up AD phone number and assign to Lync telephone number with extension
#

$enabledUsers = Get-CsADUser -Identity $usr.Identity

 
foreach ($user in $enabledUsers)

    {

        $phoneNumber = $user.Phone

        $phoneNumber = $phoneNumber -replace "[^0-9]"
	$phoneNumber = $phoneNumber.Substring(3,7)

        $phonenumber = "TEL:+16123138777;ext=" + $phoneNumber

	echo "The phone number $phonenumber will be entered into Lync" 
		

        Set-CsUser -Identity $user.Identity -LineUri $phoneNumber


    } 
#
# Add to AD group so they have "Lync Full"clien in Windows 7
#


#Add-QADMemberOf -Identity $usr.Identity -group ICOGRP-WIN7-MSFT-LYNC-2013
Add-QADGroupMember -identity ICOGRP-WIN7-MSFT-LYNC-2013 -member $usr.identity | fl name, dn
echo "Has been added to the AD group, ICOGRP-WIN7-MSFT-LYNC-2013"
}