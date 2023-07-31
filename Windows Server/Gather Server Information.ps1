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
$networkInterfaces = Get-NetIPConfiguration |
                     Where-Object { $_.IPv4Address -ne $null } |
                     Select-Object InterfaceAlias, IPv4Address |
                     ForEach-Object {
                        [PSCustomObject]@{
                            InterfaceName = $_.InterfaceAlias
                            IPAddress = $_.IPv4Address.ipaddress
                        }
                     }

# Get DNS server addresses and suffix list
Write-Green "Gathering DNS server addresses..."
$dnsAddresses = Get-DnsClientServerAddress | Select-Object -ExpandProperty ServerAddresses

Write-Green "Gathering DNS suffix list..."
$suffixList = Get-DnsClientGlobalSetting | Select-Object -ExpandProperty SuffixSearchList

# Combine the information into a single object
$serverInfo = [PSCustomObject]@{
    Hostname = $hostname
    OperatingSystem = $os
    BuildNumber = $buildNumber
    ApplicationsInstalled = $applicationsText -join "`n"  # Join the application texts with newlines
    RolesInstalled = $rolesText -join "`n"  # Join the role texts with newlines
}

# Add network interfaces and IP addresses as separate properties to the object
$networkInterfaces | ForEach-Object {
    $interfaceName = $_.InterfaceName
    $ipAddress = $_.IPAddress
    $serverInfo | Add-Member -MemberType NoteProperty -Name "Interface: $interfaceName" -Value $ipAddress
}

# Add DNS server addresses and suffix list as separate properties to the object
$serverInfo | Add-Member -MemberType NoteProperty -Name "DNS Server Addresses" -Value ($dnsAddresses -join ", ")
$serverInfo | Add-Member -MemberType NoteProperty -Name "Suffix List" -Value ($suffixList -join ", ")

# Determine the script's location and construct the export file path
$scriptDirectory = $PSScriptRoot
$exportFilePath = Join-Path -Path $scriptDirectory -ChildPath "ServerInfo.csv"

# Export the information to the CSV file in the current working directory
$serverInfo | Export-Csv -Path $exportFilePath -NoTypeInformation

Write-Green "Server information has been exported to $exportFilePath."
