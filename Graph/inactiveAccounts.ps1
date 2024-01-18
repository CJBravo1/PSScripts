#Connect to Graph
if ($null -eq (Get-MGContext))
{
    Connect-MgGraph -Scopes 'User.Read.All', 'Directory.AccessAsUser.All', 'User.ReadBasic.All', 'User.ReadWrite.All', 'Directory.Read.All', 'Directory.ReadWrite.All', 'Group.Read.All', 'User.Export.All','AuditLog.Read.All'
}

$CSVOutputFile = "~\Desktop\InactiveMicrosoftAccounts.csv"
#Gather Microsoft Accounts
$Userproperties = @(
    'AccountEnabled',
    'DisplayName',
    'mail',
    'SignInActivity',
    'UserPrincipalName')      
$InactiveMicrosoftAccounts = Get-MgUser -Filter 'accountEnabled eq false' -Property $Userproperties -All:$true
foreach ($MGAccount in $InactiveMicrosoftAccounts)
{
    #Each User Properties
    $AccountEnabled = $MGAccount.AccountEnabled
    $AssignedLicenses = Get-MgUserLicenseDetail -UserId $MGAccount.Id
    $DisplayName = $MGAccount.DisplayName
    $SignInActivity = $MGAccount.SignInActivity.LastSignInDateTime
    $UserPrincipalName = $MGAccount.UserPrincipalName

    #Create the Table
    $Table = [PSCustomObject]@{
        DisplayName      = $DisplayName
        UserPrincipalName = $UserPrincipalName
        AccountEnabled = $AccountEnabled
        SignInActivity = $SignInActivity 
        Licenses = $AssignedLicenses.SkuPartNumber -join ', '
    }
    $Table
    $Table | Export-Csv -NoTypeInformation $CSVOutputFile -Append 
}
Write-Host "CSV Outputed to $csvOutputFile" -ForegroundColor Green