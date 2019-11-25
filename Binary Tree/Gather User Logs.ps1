#Gather Wave Session and Users
$salesWave = Get-BTWave "Sales Wave 1"
$salesWaveUsers = Get-BTUser -Wave $salesWave

#Create Blank Table
$LogTable = @()
$TableLine = New-Object psobject   

Write-Host "Current Wave shows" $SalesWaveUsers.Count "Users" -ForegroundColor Green

foreach ($user in $salesWaveUsers) {
    Write-Host "Processing:" $user.UserPrincipalName -ForegroundColor Cyan
    #Gather Logs from each user
    $Logs = Get-BTSync -User $user | select -first 2 |Get-BTLog | where {$_.Level -eq "SyncJob" -or $_.Level -eq "Error" -or $_.Level -eq "Info"}
    foreach ($Log in $Logs){
        $userDisplayName = $user.DisplayName
        $userUPN = $user.UserPrincipalName
        $userLogLevel = $Log.level
        $userLogMessage = $log.message
        #Write-Host $userUPN -ForegroundColor Cyan
        $TableLine | Add-Member -NotePropertyName "UserDisplayName" -NotePropertyValue $userDisplayName
        $TableLine | Add-Member -NotePropertyName "UserUPN" -NotePropertyValue $userUPN
        $TableLine | Add-Member -NotePropertyName "LogLevel" -NotePropertyValue $userLogLevel
        $TableLine | Add-Member -NotePropertyName "LogMessage" -NotePropertyValue $userLogMessage
        $LogTable += $TableLine
        $TableLine = New-Object psobject
    }
$LogTable | Export-Csv -NoTypeInformation .\UserErrors.csv
}