$proxyaddresses = Import-Csv C:\Temp\proxyaddress.csv
$proxyaddresses | foreach {
Write-Host $_.Samaccountname -ForegroundColor Cyan
Write-Host $_.proxyaddresses -ForegroundColor Magenta
Write-Host $_.secondProxyAddress -ForegroundColor Yellow
$aduser = Get-ADUser -Identity $_.SamAccountName
$primaryProxy = $_.ProxyAddresses
$primaryProxy = $($primaryProxy | Out-String)
$secondaryProxy = $_.Secondproxyaddress
$secondaryProxy = $($secondaryProxy | Out-String)
Write-Host "@{proxyaddresses=$primaryProxy}" -ForegroundColor Green
Write-Host "@{proxyaddresses=$secondaryProxy}" -ForegroundColor Red
$primaryProxyOut = "@{proxyaddresses=$primaryProxy}"
$secondaryProxyOut = "@{proxyaddresses=$secondaryProxy}"
Write-Host $primaryProxyOut
Write-Host $secondaryProxyOut
Set-ADUser -Identity $aduser.distinguishedname -Add @{proxyaddresses=$([string]$primaryProxy)}
Set-ADUser -Identity $aduser.DistinguishedName -Add @{proxyaddresses=$([string]$secondaryProxy)}
}