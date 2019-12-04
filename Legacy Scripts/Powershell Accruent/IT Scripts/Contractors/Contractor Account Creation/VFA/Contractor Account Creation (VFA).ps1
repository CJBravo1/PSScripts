$Users = $null
$Users = Import-Csv -Delimiter "," -Path C:\Scripts\Contractors.csv

# Load the AD modules
Import-Module ActiveDirectory

foreach ($User in $Users)  
    {
        # set each field into a variable for building command
		$FirstName = $User.FirstName
		$LastName = $User.LastName
        $LastName1 = $LastName.replace(' ','')
        $FirstInitial = ($FirstName.Substring(0,1))
        $Username = ($FirstInitial+$LastName1)
        $UID = $Username.ToLower()
		$FullName = "$LastName, $Firstname"
		$Department = $User.Department
		$Manager = $User.Manager
		        
        # create ADUser (This is will put them in the Remote OU"
		New-ADUser -Name $FullName -DisplayName $FullName -Path "OU=Users,OU=Remote,DC=vfa,DC=corp" -SamAccountName $UID -GivenName $FirstName -Surname $LastName -AccountPassword (ConvertTo-SecureString Accruent1 -AsPlainText -Force) -ChangePasswordAtLogon $false -Enabled $true
		
        
		# build command to update AD information, checking to see if variable has value, if it does, add it to the command
		Set-ADUser -identity $UID -EmailAddress "$UID@contractors.accruent.com" -userPrincipalName "$UID@vfa.corp" -Description "MGR: $Manager" -Department $Department
		
                # add the users to VPN Groups.
                Add-ADGroupMember -Identity "ASA-VPN-Users" -Member $Username
    }




