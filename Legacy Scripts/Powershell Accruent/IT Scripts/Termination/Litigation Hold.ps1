###################################################################
## This is for placing a litigation/legal hold on an account.    ##
##                                                               ##
###################################################################

Do
{
$error.clear()
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
If ($error.count -gt 0) { 
Clear-Host
$failed = Read-Host "Login Failed! Retry? [y/n]"
	if ($failed  -eq 'n'){exit}
}
} While ($error.count -gt 0)
Import-PSSession $Session

Do
{
Clear-Host

$user = Read-Host 'Whose mailbox is being placed on litigation hold?'

"`n"

$days = Read-Host 'And for how many days?(For terms, set for 2555 days (7 years) unless told otherwise. Leave blank for an indefinite hold.)'

"`n"

    If ($days -lt 1) { 

    Set-Mailbox $user -LitigationHoldEnabled $true 


    Write-Host "$user has been placed on an indefinite litigation hold"

    }

    Elseif ($days -gt 0){

    Set-Mailbox $user -LitigationHoldEnabled $true -LitigationHoldDuration $days


    Write-Host "$user has been placed on a litigation hold for $days day(s)"

    }

"`n"

$repeat = Read-Host "Do you need to place any more accoutns on litigation hold? [y/n]"
} While ($repeat -ne "n")
Remove-PSSession $Session