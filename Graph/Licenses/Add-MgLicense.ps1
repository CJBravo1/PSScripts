function Assign-MgGraphLicense {
    param (
        [Parameter(Mandatory = $true)]
        [string]$License,

        [Parameter(Mandatory = $true)]
        [string]$User
    )

    $licenseSku = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -eq "ENTERPRISEPACK" }

    if ($licenseSku) {
        if ($User -like "*@example.com") {
            $user = Get-MgUser -Filter "userPrincipalName eq '$User'"
        } else {
            Write-Host "Invalid user format. User should include '@example.com'."
        }
        if ($user) {
            $licenseAssignment = New-MgLicenseAssignment -SkuId $licenseSku.SkuId -UserId $user.Id
            if ($licenseAssignment) {
                Write-Host "License '$License' assigned to user '$User' successfully."
            } else {
                Write-Host "Failed to assign license '$License' to user '$User'."
            }
        } else {
            Write-Host "User '$User' not found."
        }
    } else {
        Write-Host "License '$License' not found."
    }
}
