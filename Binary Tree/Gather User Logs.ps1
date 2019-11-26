#Gather Wave Session and Users
$salesWave = Read-Host -Prompt "Enter Migration Wave Name" 
$salesWaveUsers = Get-BTUser -Wave $salesWave

#Create Blank Table
$LogTable = @()
$TableLine = New-Object psobject   

Write-Host "Current Wave shows" $SalesWaveUsers.Count "Users" -ForegroundColor Green

foreach ($user in $salesWaveUsers) {
    Write-Host "Processing:" $user.UserPrincipalName -ForegroundColor Cyan
    #Gather Logs from each user
    $Logs = Get-BTSync -User $user | Select-Object -first 2 |Get-BTLog | Where-Object {$_.Level -eq "SyncJob" -or $_.Level -eq "Error" -or $_.Level -eq "Info"}
    $LogWarn = Get-BTSync -User $user | Select-Object -First 1 | Get-BTLog | Where-Object {$_.Level -eq "Warn"}
    foreach ($Log in $Logs){
       #Gather Variables
        $userDisplayName = $user.DisplayName
        $userUPN = $user.UserPrincipalName
        $userLogLevel = $Log.level
        $userLogMessage = $log.message
        $SyncStatus = $(Get-BTSync -User $user | Select-Object -first 1 SyncState)
        $LogWarn = $LogWarn | Select-Object Message -Unique
        #Create Table
        $TableLine | Add-Member -NotePropertyName "UserDisplayName" -NotePropertyValue $userDisplayName
        $TableLine | Add-Member -NotePropertyName "UserUPN" -NotePropertyValue $userUPN
        $TableLine | Add-Member -NotePropertyName "UserStatus" -NotePropertyValue $SyncStatus
        $TableLine | Add-Member -NotePropertyName "LogLevel" -NotePropertyValue $userLogLevel
        $TableLine | Add-Member -NotePropertyName "LogMessage" -NotePropertyValue $userLogMessage
        $TableLine | Add-Member -NotePropertyName "LogWarning" -NotePropertyValue $LogWarn
        $LogTable += $TableLine
        $TableLine = New-Object psobject
    }
$LogTable | Export-Csv -NoTypeInformation .\UserErrors.csv
}