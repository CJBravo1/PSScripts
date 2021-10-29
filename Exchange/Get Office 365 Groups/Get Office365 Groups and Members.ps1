#Change Window Title
$host.ui.RawUI.WindowTitle = "Get Office 365 Groups"

#Get Login Credentials
$UserCredential = Get-Credential -Message "Enter your Office 365 Credentials"

#Make new session
Write-Host "Connecting to Office 365" -ForegroundColor Green
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
#Connect to PsSession
Import-PSSession $Session -WarningAction SilentlyContinue
Connect-MsolService -Credential $UserCredential

#Create Blank Table
Write-Host "Creating Tables" -ForegroundColor Green
$CSV = New-Object PSObject
$csvTable = @()

#Gather Office 365 Groups
Write-Host "Gathering Office 365 Groups" -ForegroundColor Green
$unifiedGroups = Get-UnifiedGroup

foreach ($group in $unifiedGroups)
    {
    Write-Host "Processing $group" -ForegroundColor Yellow
    #Get Group's Members
    $members = Get-UnifiedGroupLinks -LinkType Member -Identity $group.PrimarySmtpAddress
    #Process Each Member for each group"
    foreach ($member in $members)
        {
        $CSV | Add-Member -NotePropertyName 'GroupName' -NotePropertyValue $group.DisplayName -Force
        $CSV | Add-Member -NotePropertyName 'GroupEmail' -NotePropertyValue $group.PrimarySmtpAddress -Force
        $CSV | Add-Member -NotePropertyName 'MemberName' -NotePropertyValue $member.Name -Force
        $CSV | Add-Member -NotePropertyName 'MemberEmail' -NotePropertyValue $member.PrimarySmtpAddress -Force

        #Export Data to table
        $csvTable += @($CSV)
        $CSV = New-Object PSObject
        }
    }
#Export Table to CSV File
Write-Host "Exporting Data to Office365Groups.csv" -ForegroundColor Green
$csvTable | Export-Csv -NoTypeInformation .\Office365Groups.csv