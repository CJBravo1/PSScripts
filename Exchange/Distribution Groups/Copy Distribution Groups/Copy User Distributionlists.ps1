#Get Mailbox distribution lists

#Get Mailbox names
Write-Host "This script requires you to be connected to the Exchange Powershell session" -ForegroundColor Green -BackgroundColor DarkBlue
Write-Host "If you have not done so, please run the connectExchange.ps1 script" -ForegroundColor Green -BackgroundColor DarkBlue

Write-Host "Enter Reference EMail Address" -ForegroundColor Yellow
$InputMail = Read-Host 

Write-Host "Enter Mailbox to Modify" -ForegroundColor Yellow
$OutputMail = Read-Host

#Set Variables for reference mailbox
$refMail = Get-Mailbox -Identity $InputMail
$refDN = $refMail.Distinguishedname
$refDist = Get-DistributionGroup -ResultSize Unlimited -Filter $("Members -like '$refDN'")
if ($refDist -eq $null)
        {
        Write-Host "Either the Mailbox Does not exist, or this mailbox does not have any Distribution list subscriptions" -ForegroundColor Yellow -BackgroundColor Red
        }
else
        {
		#For Loop to add new member to given distribution groups
		foreach ($group in $refDist)
        	{
			Write-Host $group.Displayname -foreground Green
			Add-DistributionGroupMember -Identity $group.displayname -Member $Outputmail
        	}
		}