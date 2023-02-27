$AcceptedDomains = Get-AcceptedDomain
foreach ($Domain in $AcceptedDomains)
{
$DKIMSigningConfig = Get-DkimSigningConfig $Domain.domainname -ErrorAction SilentlyContinue
if ($null -eq $DKIMSigningConfig) 
    {
    Write-Host "Generating New DKIM Key for $domain.DomaninName" -ForegroundColor Green
    $newDKIM = New-DkimSigningConfig -DomainName $Domain.DomainName -Enabled $false
    $newDKIM
    }
}
Get-DkimSigningConfig | Select-Object Domain,Selector1CNAME,Selector2CNAME