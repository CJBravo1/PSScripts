$creds = Get-Credential -Message "Enter your Office 365 Credentials"

#Connect to Office 365 and Exchange
Write-Host "Connecting to Office 365" -ForegroundColor Green
Connect-MsolService -Credential $creds
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Creds -Authentication Basic -AllowRedirection
Import-PSSession $ExchangeSession -WarningAction SilentlyContinue

Write-Host "Gathering Office 365 Groups and Members" -ForegroundColor Green

#Get List of Office 365 Groups
$OfficeGroups = Get-UnifiedGroup -ResultSize Unlimited

foreach ($group in $OfficeGroups) 
    {
    #Get Group Members "Linked" to Office 365 Groups
    Get-UnifiedGroupLinks -Identity $group.Name -LinkType Members -ResultSize Unlimited | foreach {
        #Create a new Hash Table with the group name and members
        $Export = New-Object -TypeName psobject -Property @{
            groupName=$group.DisplayName
            groupEmail = $group.PrimarySMTPAddress
            member = $_.Name
            memberEmail = $_.PrimarySMTPAddress
            }
            $Export | ft
            $Export | Export-Csv .\Office365Groups.csv -NoTypeInformation -Append
        }
    } 
    