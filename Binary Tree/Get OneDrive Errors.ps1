#Create Blank Table
$LogTable = @()
$TableLine = New-Object psobject 

$MigWave = Read-Host -Prompt "Enter Migration Wave"

Write-Host "Gathering Users" -ForeGroundColor Green
$BTUsers = Get-BTUser -wave $MigWave
foreach ($user in $BTUsers) {
    $UPN = $user | Select-Object UserPrincipalName
    $DisplayName = $user.DisplayName

    Write-Host $Displayname -ForegroundColor Magenta
    $BTSync = Get-BTSync -User $user.UserPrincipalName | Where-Object {$_.SyncDataType -eq "OneDriveForBusiness" -and $_.ItemsFailed -ge 1 -and $_.SyncState -eq "SyncError"}
    $BTLogs = $BTSync | Get-BTLog | Where-Object {$_.Message -like "Unable to sync Item*" -or $_.Message -like "Unable to Sync Content*" }

    foreach ($log in $BTLogs) {
        
        $TableLine | Add-Member -NotePropertyName "DisplayName" -NotePropertyValue $DisplayName
        $TableLine | Add-Member -NotePropertyName "User" -NotePropertyValue $UPN
        $TableLine | Add-Member -NotePropertyName "Level" -NotePropertyValue $log.Level
        $TableLine | Add-Member -NotePropertyName "TimeStamp" -NotePropertyValue $Log.LogTimeStamp
        $TableLine | Add-Member -NotePropertyName "Message" -NotePropertyValue $log.message
        $TableLine | Add-Member -NotePropertyName "Exception" -NotePropertyValue $log.exception
        
        $LogTable += $TableLine
        $TableLine = New-Object psobject
        }
        $LogTable | Export-Csv -NoTypeInformation .\"$MigWave"OneDriveErrors.csv
    }