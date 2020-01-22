#Gather Each Active Directory User and Check if the Email Address Property and UPN Property match
Import-Module ActiveDirectory

#Create Table
$table = @()

#Select Wich OU to filter by
$UserOU = Read-Host -Prompt "User's OU"

#Backup Current User's properties
$BackupLocation = Test-Path C:\Temp\UPNMatch 
If ($BackupLocation -eq $false)
    {
    mkdir C:\Temp\UPNMatch
    Write-Host "Files will be Exported to C:\Temp\UPNMatch" -ForegroundColor Yellow
    }
Else
    {
    rm C:\Temp\UPNMatch\*
    Write-Host "Files will be Exported to C:\Temp\UPNMatch" -ForegroundColor Yellow
    }

Get-ADUser -Filter * -SearchBase $UserOU -Properties * | where {$_.Enabled -eq $true -and $_.EmailAddress -ne $null} | select name,givenName,Surname,UserPrincipalName,EmailAddress,SamAccountName | Export-Csv -NoTypeInformation C:\Temp\UPNMatch\UPNMatchBackup.csv

#Gather AD Users and Start Foreach Loop
Get-ADUser -Filter * -SearchBase $UserOU -Properties * | where {$_.Enabled -eq $true -and $_.EmailAddress -ne $null} | foreach 
    {
    #Sort Attributes into Variables
    $ADDisplayname = $_.DisplayName
    $ADEmailAddress = $_.Mail
    $ADSamAccount = $_.SamAccountName
    $ADUPN = $_.UserPrincipalName
    
    Write-Host $_.DisplayName
    
    #Start Matching
    if ($ADEmailAddress -ne $ADUPN) 
        {
        Write-Host "Does not Match" -ForegroundColor Yellow -BackgroundColor Red
        $Match = "No Match"
        Set-Aduser -Identity $ADSAmAccount -UserPrincipalName $ADEmailAddress -whatif
        }
    else 
        {
        Write-Host "Match!!!" -ForegroundColor Green -BackgroundColor Blue
        $Match = "MATCH"
        }
    
    #Add Values to CSV
    $csv | Add-Member -NotePropertyName "Name Of User" -NotePropertyValue "$ADDisplayname"
    $csv | Add-Member -NotePropertyName "EmailAddress" -NotePropertyValue "$ADEmailAddress"
    $csv | Add-Member -NotePropertyName "UPN" -NotePropertyValue $ADUPN
    $csv | Add-Member -NotePropertyName "Match" -NotePropertyValue  "$MATCH"
    
    #Add CSV Values to Table
    $table += @($csv)


    $csv = New-Object PSObject
}
if ($(Test-Path C:\temp) -eq $true)
    {
    $table | Export-Csv -NoTypeInformation C:\Temp\UPNMatch.csv -Verbose
    }
else
    {
    mkdir C:\Temp
    $table | Export-Csv -NoTypeInformation C:\Temp\UPNMatch.csv -Verbose
    }