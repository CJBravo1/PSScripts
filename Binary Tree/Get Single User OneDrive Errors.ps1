Write-Host "This Script gathers ALL Binary Tree OneDrive Sync Logs, regardless of Error or Sync State 
This will take some time determining on the user, or the amount of sync's the user has gone through."

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

#Get Username
Write-Host "Binary Tree Client:" $BTSession.ClientName -ForegroundColor Yellow
Write-Host "User:" $BTSession.ApiKeyName -ForegroundColor Yellow
$MigUser = Read-Host -Prompt "Enter Source User's UPN"

Write-Host "Gathering User Info" -ForeGroundColor Green
$BTUsers = Get-BTUser -Identity $MigUser
foreach ($user in $BTUsers) {
    $UPN = $user | Select-Object UserPrincipalName
    $DisplayName = $user.DisplayName

    Write-Host $Displayname -ForegroundColor Cyan
    $BTSync = Get-BTSync -User $user.UserPrincipalName | Where-Object {$_.SyncDataType -eq "OneDriveForBusiness"}
    $BTLogs = $BTSync | Get-BTLog 
    #$BTLogs = $BTSync | Get-BTLog | Where-Object {$_.Message -like "Unable to sync Item*" -or $_.Message -like "Unable to Sync Content*" }
    foreach ($log in $BTLogs) {

        #Correct Timestamp
        $timestamp = $log.LogTimeStamp
        $timeStamp = [DateTime]::ParseExact($timestamp, 'yyyyMMddHHmmssfff', $null).ToString() 

        $TableLine | Add-Member -NotePropertyName "DisplayName" -NotePropertyValue $DisplayName
        $TableLine | Add-Member -NotePropertyName "User" -NotePropertyValue $UPN.UserPrincipalName.ToString()
        $TableLine | Add-Member -NotePropertyName "Level" -NotePropertyValue $log.Level
        $TableLine | Add-Member -NotePropertyName "TimeStamp" -NotePropertyValue $timestamp
        $TableLine | Add-Member -NotePropertyName "Message" -NotePropertyValue $log.message
        
        if ($log.Exception -ne $Null) {
            $logException = $log | where {$_.Exception -ne $Null} | Select-Object exception
            $logException = $log.exception.ToString()
            $logException = $logException  -split "  "
            $TableLine | Add-Member -NotePropertyName "Exception" -NotePropertyValue $logException[0]
            }
            else {
                $TableLine | Add-Member -NotePropertyName "Exception" -NotePropertyValue $Null
            }
        
        $LogTable += $TableLine
        $TableLine = New-Object psobject
        }
        $LogTable | Export-Csv -NoTypeInformation ~\Desktop\"$MigUser"OneDriveErrors.csv
    }