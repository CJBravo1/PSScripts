
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
    $SkuId = $SKULicense.SkuId

    # Set the license to add
    $RemoveLicense = @{SkuId = $SkuId; DisabledPlans = @()}

    # Add the license to the user
    Set-MguserLicense -UserId $UserObject.Id -RemoveLicenses $RemoveLicense -RemoveLicenses @()
}
