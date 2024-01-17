#Change Window Title
#$host.ui.RawUI.WindowTitle = "Get Empty Distribution Groups"

#Get Login Credentials
#Write-Host "Connecting to Office 365" -ForegroundColor Yellow
#$UserCredential = Get-Credential -Message "Enter your Office 365 Credentials"

#Make new session
#$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

#Connect to PsSession
#Import-PSSession $Session -WarningAction SilentlyContinue

#Create Variables
Write-Host "Gathering Distribution Groups" -ForegroundColor Green
$groups = Get-DistributionGroup -Resultsize Unlimited -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
Write-Host "Total Amount of Groups: $groups.count" -ForegroundColor Yellow
$emptyGrouplist = New-Object 'System.Collections.Generic.List[System.Object]'

foreach ($group in $groups) {
    $members = Get-DistributionGroupMember -Identity $group.Name -ResultSize Unlimited
    if ($members.count -eq 0) 
        {
        Write-Host $group.Name -ForegroundColor Cyan
        $emptyGrouplist.Add("$group")
        }
    }

#Export CSV of Empty Groups
Write-Host "Exporting Data to Output.csv" -ForegroundColor Green
$emptyGrouplist | ForEach-Object {
    Get-DistributionGroup -Identity $_  -ErrorAction SilentlyContinue | select name,alias,primarysmtpaddress | Export-Csv -NoTypeInformation .\output.csv -Append
    }

#Write-Host "Ta Da!!" -ForegroundColor Green
