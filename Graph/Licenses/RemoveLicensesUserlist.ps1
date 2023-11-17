
# Import the Microsoft Graph PowerShell module
#Import-Module Microsoft.Graph

# Define the parameters
param (
    [Parameter(Mandatory=$false)]
    [string]$CsvPath = ".\Users.csv"
)

# Import the CSV file
$Users = Import-Csv $CsvPath

# Loop through each row in the CSV file
foreach ($User in $Users) {
    # Extract the email address and SkuPartNumber
    $EmailAddress = $User.EmailAddress
    $SkuPartNumber = $User.SkuPartNumber

        # Get the user object from Microsoft Graph
        $UserObject = Get-MgUser -UserId $EmailAddress

        # Get the SkuId from Microsoft Graph
        $SKULicense = Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq "$SkuPartNumber"}

        # Check if the user has the license we are trying to remove
        if ($UserObject.AssignedLicenses.LicensedProducts.SkuId -notcontains $SKULicense.SkuId) {
            Write-Host "$EmailAddress" -ForegroundColor Green
            Write-Host "No License Found" -ForegroundColor Red
            continue
        }

        $SkuId = $SKULicense.SkuId

        # Set the license to add
        Write-Host "$EmailAddress" -ForegroundColor Green
        $RemoveLicense = @{SkuId = $SkuId; DisabledPlans = @()}
        Write-Host "License Removed" -ForegroundColor Cyan

        # Add the license to the user
        Set-MguserLicense -UserId $UserObject.Id -RemoveLicenses $SkuId -AddLicenses @()
    }
