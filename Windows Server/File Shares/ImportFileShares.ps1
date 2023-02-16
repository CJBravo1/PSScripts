$shares = Import-Csv -Path "C:\Shares.csv"

foreach ($share in $shares) {
    New-SmbShare -Name $share.ShareName -Path $share.Path

    $acl = Get-Acl -Path $share.Path
    $permission = New-Object System.Security.AccessControl.FileSystemAccessRule($share.IdentityReference, $share.FileSystemRights, "Allow")
    $acl.SetAccessRule($permission)

    Set-Acl -Path $share.Path -AclObject $acl
}
