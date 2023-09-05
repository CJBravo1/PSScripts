# Connect to Microsoft 365
$credential = Get-Credential  # Enter your Microsoft 365 admin credentials
Connect-MsolService -Credential $credential

# Retrieve user information
$users = Get-MsolUser -All | Select-Object DisplayName, UserPrincipalName, isLicensed, Licenses

# Process license information
$processedUsers = foreach ($user in $users) {
    $userLicenses = $user.Licenses | ForEach-Object {
        $_.AccountSkuId
    }
    [PSCustomObject]@{
        DisplayName      = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        IsLicensed       = $user.isLicensed
        Licenses         = $userLicenses -join ', '
    }
}

# Export to CSV
$csvPath = ".\Microsoft Users and Licenses.csv"  # Specify the desired CSV file path
$processedUsers | Export-Csv -Path $csvPath -NoTypeInformation

# Disconnect from Microsoft 365
Disconnect-MsolService
