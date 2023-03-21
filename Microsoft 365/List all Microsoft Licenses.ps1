#Check if Microsof.Graph and Azure Powershell Module are Installed.
if ($null -eq (Get-InstalledModule microsoft.graph -ErrorAction SilentlyContinue))
    {
        Write-Host "Installing Microsoft Graph Powershell Modules" -ForegroundColor Green
        Install-Module Microsoft.Graph -Scope CurrentUser
    } 
#Retrieve all Microsoft Licenses
$mgContext = Get-MgContext

if ($null -eq $mgContext)
{
    # Connect to Microsoft Graph
    Write-Host "Connecting to Microsoft Graph" -ForegroundColor Green
    Connect-MgGraph -Scopes "Directory.Read.All"
}
$Licenses = Get-MgSubscribedSku

foreach ($license in $Licenses)
{
    $Results = @(
    @{
        licenseName = $License.SkuPartNumber
        licensesinUse = $License.consumedUnits
        licenseTotal = $license.PrepaidUnits.Enabled
    }
    )
    $Results
}