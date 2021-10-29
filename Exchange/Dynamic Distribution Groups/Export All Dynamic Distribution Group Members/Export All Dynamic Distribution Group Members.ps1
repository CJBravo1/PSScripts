$host.ui.RawUI.WindowTitle = "Export All Dynamic Distribution Group Members"
#Intro
Write-Host "This Script will grab ALL Dynamic Distribution Group and their Members, and Export them to separate CSV files." -ForegroundColor Yellow

#Import Exchange Session
$msolcred = Get-Credential -Message "Enter Office 365 Admin Password"
$CloudExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell-liveid/ -Credential $msolcred -Authentication Basic -AllowRedirection
Import-PSSession $CloudExchangeSession -DisableNameChecking -WarningAction SilentlyContinue | out-null

#Make Output Directory
$outputFolder = Test-Path -Path .\Output
if ($outputFolder -eq $null)
    {
    Write-Host "Creating Output folder" -ForegroundColor Green
    New-Item -ItemType Directory -Path .\Output
    }
else
    {
    Write-Host "Removing items in Output folder" -ForegroundColor Red
    Remove-Item .\Output\* -Recurse
    }


#Get Dynamic Distribution Groups
Write-Host "Gathering Dynamic Distribution Groups" -ForegroundColor Cyan
$ddGroup = Get-DynamicDistributionGroup

#Get Group Members and Export as separate CSV Files
foreach ($group in $ddGroup) 
    {
    $groupAlias = $group.Alias
    Write-Host "Processing $groupAlias" -ForegroundColor Yellow
    Get-Recipient -RecipientPreviewFilter $group.RecipientFilter -OrganizationalUnit $group.RecipientContainer | select Name,DisplayName,Alias,Identity,Company,Office,PrimarySMTPAddress,UserPrincipalName,AcceptMessagesOnlyFromSendersOrMembers  | Export-Csv -NoTypeInformation .\Output\"$groupAlias.csv"
    }
