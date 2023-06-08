$serverlist = cat C:\Temp\serverlist.txt

foreach ($RemoteServer in $serverlist)
{
    Write-Host "Testing $RemoteServer" -foregroundColor Cyan
    $csvline = New-Object psobject
    $testConnection = Test-Connection -ComputerName $RemoteServer -Count 1 -ErrorAction SilentlyContinue
    if ($testConnection -ne $null) 
    {
        #Operating System Info
        $Win32OS = Get-WmiObject Win32_OperatingSystem -ComputerName $RemoteServer
        $Win32ComputerSystem = Get-WmiObject Win32_ComputerSystem -ComputerName $RemoteServer
        
        #Installed Features and Apps
        $installedFeatures = Invoke-Command -ComputerName $RemoteServer -ScriptBlock {Get-WindowsFeature | where {$_.Installed -eq $true} }
        $installedApps = Invoke-Command -ComputerName $RemoteServer -ScriptBlock {Get-WmiObject Win32_Product}

        $Table = New-Object psobject -Property @{
            Hostname = $Win32ComputerSystem.Name
            OperatingSystem = $Win32OS.Caption
            InstalledFeatures = $installedFeatures.Name | Out-String
            InstalledApps = $installedApps.Name | Out-String
        }
        $Table | Export-Csv -NoTypeInformation ~\Desktop\Servers.csv -Append
    }
    else {
        Write-Host "$RemoteServer is not Responsive" -ForegroundColor Red
        }
}
