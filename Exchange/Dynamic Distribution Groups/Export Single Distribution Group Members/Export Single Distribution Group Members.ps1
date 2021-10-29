$host.ui.RawUI.WindowTitle = "Export Selected Dynamic Distribution Group Members"
#Intro
Write-Host "This Script will grab a selected Dynamic Distribution Group and its Members, and Export them to separate CSV files." -ForegroundColor Yellow

#Import Exchange Session
$msolcred = Get-Credential -Message "Enter Office 365 Admin Password"
$CloudExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell-liveid/ -Credential $msolcred -Authentication Basic -AllowRedirection
Import-PSSession $CloudExchangeSession -DisableNameChecking -WarningAction SilentlyContinue | out-null

#Make Output Directory
#mkdir C:\Temp\DynamicDistroExport

$inputGroup = Read-Host -Prompt "Enter Dynamic Distribution Group Alias"

$ddGroup = get-DynamicDistributionGroup -Identity $inputGroup
$ddGroupAlias = $ddGroup.Alias
$members = Get-Recipient -RecipientPreviewFilter $ddgroup.RecipientFilter -OrganizationalUnit $ddgroup.RecipientContainer
$members
$members | select Name,DisplayName,Alias,Identity,Company,Office,PrimarySMTPAddress,UserPrincipalName | Export-Csv -NoTypeInformation .\"$ddgroupAlias.csv"
Write-Host "CSV Export is at .\DynamicDistroExport" -ForegroundColor Green -BackgroundColor Blue
pause