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

# Calculate the total and consumed license counts
$TotalLicenses = $Licenses.ActiveUnits | Measure-Object -Sum | Select-Object -ExpandProperty Sum
$ConsumedLicenses = $Licenses.ConsumedUnits | Measure-Object -Sum | Select-Object -ExpandProperty Sum

# Display the results
Write-Host "Total licenses: $TotalLicenses"
Write-Host "Consumed licenses: $ConsumedLicenses"
Write-Host ""
$Licenses | Format-Table -AutoSize