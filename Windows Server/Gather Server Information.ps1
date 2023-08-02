# Define a function to display text in green
function Write-Green {
    param([string]$Text)
    Write-Host $Text -ForegroundColor Green
}

# Get basic server information
Write-Green "Gathering basic server information..."
$hostname = $env:COMPUTERNAME
$os = (Get-WmiObject Win32_OperatingSystem).Caption
$buildNumber = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId

# Get processor information
Write-Green "Gathering processor information..."
$processor = (Get-WmiObject Win32_Processor).Caption

# Get RAM information
Write-Green "Gathering RAM information..."
$ram = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory
$ramGB = [Math]::Round($ram / 1GB, 2)

# Get RAM usage information
Write-Green "Gathering RAM usage information..."
$ramUsage = (Get-WmiObject Win32_OperatingSystem).TotalVisibleMemorySize
$ramUsageGB = [Math]::Round($ramUsage / 1GB, 2)

# Get installed applications
Write-Green "Gathering installed applications..."
$applications = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
                Where-Object { $_.DisplayName -ne $null } |
                Select-Object DisplayName, Publisher, InstallDate

# Convert the applications to plain text representation
$applicationsText = $applications | ForEach-Object {
    $installDate = $_.InstallDate
    if ($installDate -ne $null) {
        $installDate = [DateTime]::ParseExact($installDate, "yyyyMMdd", $null).ToString("yyyy-MM-dd")
    }

    "{0} (Publisher: {1}, Install Date: {2})" -f $_.DisplayName, $_.Publisher, $installDate
}

# Get installed server roles
Write-Green "Gathering installed server roles..."
$roles = Get-WindowsFeature |
         Where-Object { $_.Installed -eq $true } |
         Select-Object Name

# Convert the roles to plain text representation
$rolesText = $roles | ForEach-Object {
    $_.Name
}

# Get network interfaces and IP addresses
Write-Green "Gathering network interfaces and IP addresses..."
$networkInterfaces = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } |
                     ForEach-Object {
                        $interfaceAlias = $_.InterfaceAlias
                        $interfaceDescription = $_.InterfaceDescription
                        $macAddress = $_.MACAddress
                        
                        $ipConfiguration = $_ | Get-NetIPAddress -AddressFamily 'IPv4' -ErrorAction SilentlyContinue
                        $ipAddress = if ($ipConfiguration) { $ipConfiguration.IPAddress -join "," } else { "N/A" }
                        $subnetMask = if ($ipConfiguration) { $ipConfiguration.PrefixLength -join "," } else { "N/A" }
                        
                        $dnsAddresses = $_ | Get-DnsClientServerAddress -AddressFamily 'IPv4' -ErrorAction SilentlyContinue
                        $dnsAddressesText = if ($dnsAddresses) { $dnsAddresses.ServerAddresses -join "," } else { "N/A" }
                        
                        $dhcpAddress = $_ | Get-NetIPConfiguration -ErrorAction SilentlyContinue
                        $dhcpAddressText = if ($dhcpAddress) { $dhcpAddress.Dhcp -eq 'Enabled' } else { "N/A" }
                        
                        [PSCustomObject]@{
                            InterfaceAlias = $interfaceAlias
                            InterfaceDescription = $interfaceDescription
                            MACAddress = $macAddress
                            IPAddress = $ipAddress
                            SubnetMask = $subnetMask
                            DNSAddresses = $dnsAddressesText
                            DHCPEnabled = $dhcpAddressText
                        }
                     }

# Get hard drive information
Write-Green "Gathering hard drive information..."
$drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object DeviceID, VolumeName, Size, FreeSpace

# Convert the drives information to plain text representation
$drivesText = $drives | ForEach-Object {
    $deviceID = $_.DeviceID
    $volumeName = $_.VolumeName
    $sizeGB = [Math]::Round($_.Size / 1GB, 2)
    $freeSpaceGB = [Math]::Round($_.FreeSpace / 1GB, 2)

    "{0} (Volume: {1}, Size: {2} GB, Free Space: {3} GB)" -f $deviceID, $volumeName, $sizeGB, $freeSpaceGB
}

# Get driver information
Write-Green "Gathering driver information..."
$drivers = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -ne $null } |
           Select-Object DeviceName, Manufacturer, DriverVersion, DriverDate

# Convert the driver information to plain text representation
$driversText = $drivers | ForEach-Object {
    $deviceName = $_.DeviceName
    $manufacturer = $_.Manufacturer
    $driverVersion = $_.DriverVersion
    $driverDate = $_.ConvertToDateTime($_.DriverDate).ToString("yyyy-MM-dd")

    "{0},{1},{2},{3}" -f $deviceName, $manufacturer, $driverVersion, $driverDate
}

# Get network shares
Write-Green "Gathering network shares..."
$networkShares = Get-WmiObject Win32_Share | Select-Object Name, Path

# Convert the network shares information to plain text representation
$networkSharesText = $networkShares | ForEach-Object {
    "{0} (Path: {1})" -f $_.Name, $_.Path
}

# Get shared printers
Write-Green "Gathering shared printers..."
$sharedPrinters = Get-WmiObject Win32_Printer | Where-Object { $_.Shared -eq $true } |
                  Select-Object Name, ShareName, PortName

# Convert the shared printers information to plain text representation
$sharedPrintersText = $sharedPrinters | ForEach-Object {
    "{0} (Share Name: {1}, Port Name: {2})" -f $_.Name, $_.ShareName, $_.PortName
}

# Combine the information into a single object
$serverInfo = [PSCustomObject]@{
    Hostname = $hostname
    OperatingSystem = $os
    BuildNumber = $buildNumber
    Processor = $processor
    RAMGB = $ramGB
    RAMUsageGB = $ramUsageGB
    ApplicationsInstalled = $applicationsText -join "`n"  # Join the application texts with newlines
    RolesInstalled = $rolesText -join "`n"  # Join the role texts with newlines
    HardDrives = $drivesText -join "`n"  # Join the hard drive texts with newlines
    NetworkShares = $networkSharesText -join "`n"  # Join the network share texts with newlines
    SharedPrinters = $sharedPrintersText -join "`n"  # Join the shared printer texts with newlines
}

# Export the server information to a CSV file
$scriptDirectory = $PSScriptRoot
$serverExportFileName = "${hostname}_ServerInfo.csv"
$serverExportFilePath = Join-Path -Path $scriptDirectory -ChildPath $serverExportFileName
$serverInfo | Export-Csv -Path $serverExportFilePath -NoTypeInformation

Write-Green "Server information has been exported to $serverExportFilePath."

# Export network interfaces to a separate CSV file
$networkInterfacesExportFileName = "${hostname}_NetworkInterfaces.csv"
$networkInterfacesExportFilePath = Join-Path -Path $scriptDirectory -ChildPath $networkInterfacesExportFileName
$networkInterfaces | Export-Csv -Path $networkInterfacesExportFilePath -NoTypeInformation

Write-Green "Network interfaces information has been exported to $networkInterfacesExportFilePath."

# Export drivers to a separate CSV file
$driversExportFileName = "${hostname}_Drivers.csv"
$driversExportFilePath = Join-Path -Path $scriptDirectory -ChildPath $driversExportFileName
$drivers | Export-Csv -Path $driversExportFilePath -NoTypeInformation

Write-Green "Driver information has been exported to $driversExportFilePath."
