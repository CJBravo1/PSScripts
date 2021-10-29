$activeDirectoryModule = Get-Module -ListAvailable | where {$_.Name -eq "ActiveDirectory"}
if ($activeDirectoryModule -eq $null) 
    {
    Write-Host "No Active Directory Module Imported" -ForegroundColor Red
    }
else 
    {
    $ActiveDirectoryUsers = Import-Csv .\ADUsers.csv
    foreach ($user in $ActiveDirectoryUsers)
        {
            Write-Host $user.Identity -ForegroundColor Green
            $ADuser = $User.Identity -split "@"
            $ADuser = $ADuser[0]
            $ADUser = Get-ADUser -Identity $ADuser
            $newProxy = $user.NewProxyAddress
            $newProxy = "smtp:$newProxy"
            Write-Host $newProxy -ForegroundColor Cyan
            Set-ADUser -Identity $ADUser.SamAccountName -Add @{ProxyAddresses="smtp:$newProxy"}
        }
    }