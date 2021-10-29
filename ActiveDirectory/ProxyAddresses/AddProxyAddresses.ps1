$activeDirectoryModule = Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"}
if ($null -eq $activeDirectoryModule) 
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
            Set-ADUser -Identity $ADUser.SamAccountName -Add @{ProxyAddresses="$newProxy"}
        }
    }