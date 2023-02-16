$shares = Get-WmiObject -Class Win32_Share
$output = @()

foreach ($share in $shares) {
    $acl = Get-Acl -Path $share.Path
    $permissions = $acl.Access

    foreach ($permission in $permissions) {
        $output += [PSCustomObject]@{
            ShareName = $share.Name
            Path = $share.Path
            IdentityReference = $permission.IdentityReference
            FileSystemRights = $permission.FileSystemRights
        }
    }
}

$output | Export-Csv -Path "Shares.csv" -NoTypeInformation
