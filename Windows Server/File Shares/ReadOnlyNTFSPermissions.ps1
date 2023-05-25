#Use this script to set Directory NTFS permisions for users to Read and Execute

$HomeDirectories = Get-ChildItem "C:\Temp\Directory"

foreach ($Directory in $HomeDirectories)
{
    Write-Host $Directory.Name -ForegroundColor Cyan
    #Get ACL
    $HomeDirectoryACL = Get-Acl $Directory.FullName

    #Filter To Specific User
    $ADUser = $HomeDirectoryACL.Access | Where-Object {$_.IdentityReference -notlike "S-1*" -and $_.IdentityReference -notlike "BUILTIN\*" -and $_.IdentityReference -notlike "NT AUTHORITY\*"}

    #Create New ACL Rule
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($ADUser.IdentityReference,"ReadAndExecute", "ContainerInherit,ObjectInherit", "none", "allow")

    #Add ACL Rule to Variable
    $HomeDirectoryACL.SetAccessRule($rule)

    #Set ACL Rule
    Set-Acl -Path $Directory.FullName -AclObject $HomeDirectoryACL -WhatIf
}
