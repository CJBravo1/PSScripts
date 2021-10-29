#Confirm There is a BTSession
$BTSession = Get-BTSession
if ($BTSession -eq $Null){
    Write-Host "There is no Binary Tree Session"
    $APIKey = Read-Host -Prompt "What is your Binary Tree API Key?"
    Connect-BTSession -ApiKey (ConvertTo-SecureString $APIKey -AsPlainText -Force)
    $BTSession = Get-BTSession
    }
    
    Write-Host "Binary Tree Client:" $BTSession.ClientName -ForegroundColor Yellow
    Write-Host "User:" $BTSession.ApiKeyName -ForegroundColor Yellow

#Gather Wave Session and Users
$UserWave = Read-Host -Prompt "Enter Source User's UserPrincipalName" 
$UserWaveUsers = Get-BTUser -Identity $UserWave

#Create Blank Table
$LogTable = @()
$TableLine = New-Object psobject   

#Write-Host "Current Wave shows" $SalesWaveUsers.Count "Users" -ForegroundColor Green

foreach ($user in $UserWaveUsers) {
    Write-Host "Processing:" $user.UserPrincipalName -ForegroundColor Cyan
    #Gather Logs from each user
    $BTUser = Get-BTUser -Identity $user
    $BTSync = Get-BTSync -User $user
    $Logs = $BTSync | Select-Object -first 2 |Get-BTLog | Where-Object {$_.Level -eq "SyncJob" -or $_.Level -eq "Error" -or $_.Level -eq "Info"}
    $LogWarn = $BTSync  | Get-BTLog | Where-Object {$_.Level -eq "Warn"} | Select-Object -First 1 -Unique
    

    foreach ($Log in $Logs){
       #Gather Variables
        $userDisplayName = $user.DisplayName
        $userLogLevel = $Log.level
        $userLogMessage = $log.message
        #$SyncStatus = $BTSync | Select-Object -first 1 SyncState
        $LogWarn = $LogWarn | Select-Object Message -Unique 
        $EXCHSyncData = $BTSync | Where-Object {$_.SyncDataType -eq "Mail"} | Select-Object -first 1 
        $ODBSyncData = $BTSync | Where-Object {$_.SyncDataType -eq "OneDriveForBusiness"} | Select-Object -first 1  
        
        #Correct Timestamp
        $timestamp = $log.LogTimeStamp
        $timeStamp = [DateTime]::ParseExact($timestamp, 'yyyyMMddHHmmssfff', $null).ToString() 

        #Create Table
        $TableLine | Add-Member -NotePropertyName "UserDisplayName" -NotePropertyValue $userDisplayName
        $TableLine | Add-Member -NotePropertyName "SourceUPN" -NotePropertyValue $BTUser.UserPrincipalName
        $TableLine | Add-Member -NotePropertyName "DestinationUPN" -NotePropertyValue $BTUser.NewUserPrincipalName
        $TableLine | Add-Member -NotePropertyName "SourceEmail" -NotePropertyValue $BTUser.PrimarySmtpAddress
        $TableLine | Add-Member -NotePropertyName "DestinationEmail" -NotePropertyValue $BTUser.NewPrimarySmtpAddress
        $TableLine | Add-Member -NotePropertyName "LogLevel" -NotePropertyValue $userLogLevel
        $TableLine | Add-Member -NotePropertyName "TimeStamp" -NotePropertyValue $timestamp
        $TableLine | Add-Member -NotePropertyName "UserMigrationStatus" -NotePropertyValue $BTUser.MigrationState
        $TableLine | Add-Member -NotePropertyName "ExchSyncState" -NotePropertyValue $EXCHSyncData.SyncState
        $TableLine | Add-Member -NotePropertyName "ExchPercentComplete" -NotePropertyValue $EXCHSyncData.PercentComplete
        $TableLine | Add-Member -NotePropertyName "ODBSyncState" -NotePropertyValue $ODBSyncData.SyncState
        $TableLine | Add-Member -NotePropertyName "ODBPercentComplete" -NotePropertyValue $ODBSyncData.PercentComplete
        $TableLine | Add-Member -NotePropertyName "LogMessage" -NotePropertyValue $userLogMessage
        if ($log.Exception -ne $Null) {
            $logException = $log | Where-Object {$_.Exception -ne $Null} | Select-Object exception
            $logException = $log.exception.ToString()
            $logException = $logException  -split "  "
            $TableLine | Add-Member -NotePropertyName "Exception" -NotePropertyValue $logException[0]
            }
            else {
                $TableLine | Add-Member -NotePropertyName "Exception" -NotePropertyValue $Null
            }
        
        #Export Data to Table and Clear Table Line Variable
        $LogTable += $TableLine
        $TableLine = New-Object psobject
    }
    }
$LogTable | Export-Csv -NoTypeInformation ~\Desktop\"$UserWave.csv"
#Write-Host "Logs Exported as $SalesWave.csv" -ForegroundColor Green

