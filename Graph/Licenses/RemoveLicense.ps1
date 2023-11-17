
# Import the Microsoft Graph PowerShell module
#Import-Module Microsoft.Graph

# Define the parameters
param (
    [Parameter(Mandatory=$true)]
    [string]$UserId,
    [Parameter(Mandatory=$true)]
    [string]$SkuId
)

#Find the License
$SKULicense = Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq "$SkuId"}
$SkuId = $SKULicense.SkuId

# Set the license to Remove
$RemoveLicense = @{SkuId = $SkuId; DisabledPlans = @()}

# Get the user object from Microsoft Graph
$User = Get-MgUser -UserId $UserId

# Remove the license to the user
Set-MguserLicense -UserId $User.Id -AddLicenses @{} -RemoveLicenses $RemoveLicense 
