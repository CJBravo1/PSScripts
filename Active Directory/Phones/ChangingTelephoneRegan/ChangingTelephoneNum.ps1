# ChangingTelephoneNum.ps1
# Created by Regan Vecera
# 3.23.17

Start-Transcript ".\most_recent_run"

#Describe program and prompt for user input
Write-host "This program is for changing a user's office phone in Active Directory. How do you want to change the numbers? `n1) One at a time `n2) Import from .csv`n"

#Let user choose how they want to change phone numbers. Loop until either 1 or 2 is chosen
Do
{
    $choice = Read-Host "Enter either 1 or 2"
}
Until ($choice -eq 1 -or $choice -eq 2)

#Single User Change
If($choice -eq 1)
{
		#Outer loop that will keep prompting for a user one at a time
		:again While($true)
		{
			#Searches for user in Active Directory, and prompts for confirmation
		    :searchLoop While($true)
		    {
				#Search for user using Name field
		        $userIn = Read-Host "Enter the user's name you are searching for in the form firstname lastname (ex. John Doe) "
		        $userFound = get-aduser -f {Name -eq $userIn} -properties *
				
				#Display the user found
		        $userFound.CN
		        $userFound.UserprincipalName
		        $userFound.officePhone
				
				#Boolean value to confirm the correct user is selected
		        $correctUserBool = Read-Host "`nIs this the user who's office phone you wish to change? [y/n]"
				if($correctUserBool -eq "y")
				{
					break searchLoop
				}
				else
				{
					#If user was incorrect, either restart search or quit program
					$searchNew = Read-Host "Search for a different user? [y\n]"
					if($searchNew -eq "n")
					{
						break again
					}	
				}
		    }
		    #Test if the user input is in the valid form of a pone number, keep looping until it is
			$validNumber = $false
			While (!$validNumber)
			{
		    	$newNumber = Read-Host "Enter the new number with hyphens (ex 123-555-5555) or press 'q' to quit"
				$validNumber = $newNumber -match "^\d{3}-\d{3}-\d{4}$"
				if($newNumber -eq "q")
				{exit}
			}
			$oldNumber = $userFound.OfficePhone
			
			#Set the user's office phone
		    set-aduser -Identity $userFound -OfficePhone $newNumber
			
			#Grab new phone number from Active Directory and output to screen to await user confirmation
			$userConfirm = get-aduser -f {Name -eq $userFound.Name} -properties *
			$screenName = $userFound.CN
			Write-Host "$screenName's number was changed from $oldNumber to $newNumber"
			
			#Loop if the user wants to edit another number
			$again = Read-Host "Would you like to edit another user? [y/n]"
			if($again -eq "n")
			{
				break again
			}
		}
}
Elseif ($choice -eq 2)
{
	#Import from csv in same directory
	$Users = Import-Csv .\TelephoneNum.csv
	foreach($User in $Users)
	{
		$Name = $User.Name
		$newNumber = $User.NewNumber
		$userFound = get-aduser -f {Name -eq $Name} -properties *
		$oldNumber = $userFound.OfficePhone
		Set-ADUser -Identity $userFound -OfficePhone $newNumber
		$screenName = $userFound.CN
		Write-Host "$screenName's number was changed from $oldNumber to $newNumber"
	}
	Write-Host "Press any key to continue ..."
	$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	
}
Else
{
    #this branch should never get executed. Improper input should be handled by Do Until
}