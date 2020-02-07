# FullCalendarDetails.ps1
# Created by Regan Vecera
# 11.21.2017

# Purpose: 
# Give a user the ability to see the details of another user's calendar instead
# of just free/busy. Without giving them Editor rights to the calendar

Clear-Host
#Log in to O365 by referencing Jonny's script
Do
{
	$error.clear()
	$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
	$adminUN = ([ADSI]$sidbind).mail.tostring()
	$UserCredential = Get-Credential -UserName $adminUN -Message "Enter your password"
	$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

	If ($error.count -gt 0) 
	{
		Clear-Host
		$failed = Read-Host "Login Failed! Retry? [y/n]"
		if ($failed  -eq 'n'){exit}
	}	
} While ($error.count -gt 0)
Import-PSSession $Session -AllowClobber

#Outer loop that will keep prompting for a user one at a time
		:anotherUserLoop While($true)
		{
			#Searches for user in Active Directory, and prompts for confirmation
		    :searchLoop While($true)
		    {
				#Search for user using Name field
		        $userIn = Read-Host "Whom do you wish to grant access to? (in the form firstname lastname (ex. John Doe)) " 
				"`n"
		        $userFound = get-aduser -f {Name -eq $userIn} -properties *
				
				#Display the user found
		        $userFound.CN
		        $userFound.UserprincipalName
		        				
				#Boolean value to confirm the correct user is selected
		        $correctUserBool = Read-Host "`nIs this the user who should be getting access? [y/n]"
				"`n"
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
						break anotherUserLoop
					}	
				}
		    }
			$fullName = $userFound.CN
			$targetMailbox = Read-Host "What mailbox will they be getting access to? (enter email address or full name)"
			"`n"
			try
			{
				Add-MailboxFolderPermission -Identity $targetMailbox":\calendar" -user $userFound.UserprincipalName -AccessRights "LimitedDetails" -ErrorAction Stop
				Throw 'Existing entry already exists, trying to change value now'
			}
			catch
			{
				try
				{
					Set-MailboxFolderPermission -Identity $targetMailbox":\calendar" -user $userFound.UserprincipalName -AccessRights "LimitedDetails" -ErrorAction Stop
					Throw 'No changes made'
				}
				catch
				{
					
				}
			}
			
			#Loop if the user wants to edit another number
			$again = Read-Host "Would you like to edit another user? [y/n]"
			"`n"
			if($again -eq "n")
			{
				break anotherUserLoop
			}
		}