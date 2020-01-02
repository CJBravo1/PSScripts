#Confirm There is a BTSession
$BTSession = Get-BTSession
if ($BTSession -eq $Null){
    Write-Host "There is no Binary Tree Session"
    $APIKey = Read-Host -Prompt "What is your Binary Tree API Key?"
    Connect-BTSession -ApiKey (ConvertTo-SecureString $APIKey -AsPlainText -Force)
    $BTSession = Get-BTSession
    }

#Create Blank Table
$LogTable = @()
$TableLine = New-Object psobject 

$BTSession = Get-BTSession
Write-Host "Binary Tree Client:" $BTSession.ClientName -ForegroundColor Yellow
Write-Host "User:" $BTSession.ApiKeyName -ForegroundColor Yellow
$MigWave = Read-Host -Prompt "Enter Migration Wave"

Write-Host "Gathering Users" -ForeGroundColor Green
$BTUsers = Get-BTUser -wave $MigWave
foreach ($user in $BTUsers) {
    $UPN = $user | Select-Object UserPrincipalName
    $DisplayName = $user.DisplayName

    Write-Host $Displayname -ForegroundColor Cyan
    $BTSync = Get-BTSync -User $user.UserPrincipalName | Where-Object {$_.SyncDataType -eq "OneDriveForBusiness" -and $_.ItemsFailed -ge 1 -and $_.SyncState -eq "SyncError"}
    #BTLogs = $BTSync | Get-BTLog | Where-Object {$_.Message -like "Unable to sync Item*" -or $_.Message -like "Unable to Sync Content*" }
    $BTLogs = $BTSync | Get-BTLog 

    foreach ($log in $BTLogs) {
        
        $logException = $log | Select-Object exception
        $logException = $logException -split "  "
        
        #Correct Timestamp
        $timestamp = $log.LogTimeStamp
        $timeStamp = [DateTime]::ParseExact($timestamp, 'yyyyMMddHHmmssfff', $null).ToString()

        $TableLine | Add-Member -NotePropertyName "DisplayName" -NotePropertyValue $DisplayName
        $TableLine | Add-Member -NotePropertyName "User" -NotePropertyValue $UPN
        $TableLine | Add-Member -NotePropertyName "Level" -NotePropertyValue $log.Level
        $TableLine | Add-Member -NotePropertyName "TimeStamp" -NotePropertyValue $timestamp
        $TableLine | Add-Member -NotePropertyName "Message" -NotePropertyValue $log.message
        $TableLine | Add-Member -NotePropertyName "Exception" -NotePropertyValue $logException[0]
        
        $LogTable += $TableLine
        $TableLine = New-Object psobject
        }
        $LogTable | Export-Csv -NoTypeInformation .\"$MigWave"OneDriveErrors.csv
    }