function Add-MgLicense {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$User,

        [Parameter(Mandatory = $true)]
        [string]$License
    )
    $MGuser = Get-MgUser -UserId $User
    $licenses = Get-MgSubscribedSku 

    $selectedLicense = $licenses | Where-Object {$_.SkuPartNumber -eq $License}

    #$addLicenseParams = @{SkuId = $selectedLicense.skuId}

    Set-MgUserLicense -Userid $MGUser.id -AddLicense @{SkuId = $selectedLicense.skuId} -RemoveLicenses @()
}
#Add-MgLicense -User $User -License $License