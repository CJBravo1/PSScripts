
    param (
        [Parameter(Mandatory = $true)]
        [string]$User,

        [Parameter(Mandatory = $true)]
        [string]$License
    )
    function Add-MgLicense {
    $MGuser = Get-MgUser -UserId $User
    $licenses = Get-MgSubscribedSku 

    $selectedLicense = $licenses | Where-Object {$_.SkuPartNumber -eq $License}

    #$addLicenseParams = @{SkuId = $selectedLicense.skuId}

    Set-MgUserLicense -Userid $MGUser.id -AddLicense @{SkuId = $selectedLicense.skuId} -RemoveLicenses @()
}