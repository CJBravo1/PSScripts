
    param (
        [Parameter(Mandatory = $true)]
        [string]$User,

        [Parameter(Mandatory = $true)]
        [string]$License
    )
    function Remove-MgLicense {
    $MGuser = Get-MgUser -UserId $User
    $licenses = Get-MgSubscribedSku 

    $selectedLicense = $licenses | Where-Object {$_.SkuPartNumber -eq $License}
    Set-MgUserLicense -Userid $MGUser.id -AddLicense @() -RemoveLicenses $selectedLicense.SkuId
}