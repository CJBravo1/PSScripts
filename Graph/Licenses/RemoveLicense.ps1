
# Import the Microsoft Graph PowerShell module
#Import-Module Microsoft.Graph

# Define the parameters
param (
    [Parameter(Mandatory=$true)]
    [string]$UserId,
    [Parameter(Mandatory=$true)]
    [string]$SkuId
)

# Set the usage location
$UsageLocation = "US"

#Find the License
$SKULicense = Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq "$SkuId"}
$SkuId = $SKULicense.SkuId

# Set the license to add
$RemoveLicense = @{SkuId = $SkuId; DisabledPlans = @()}

# Get the user object from Microsoft Graph
$User = Get-MgUser -UserId $UserId

# Update the user object in Microsoft Graph
Update-MGUser -UserId $User.Id -UsageLocation $UsageLocation

# Add the license to the user
Set-MguserLicense -UserId $User.Id -RemoveLicenses $RemoveLicense -RemoveLicenses @()
