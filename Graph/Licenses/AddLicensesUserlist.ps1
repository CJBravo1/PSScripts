
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

    #Set the Usage Location
    $UsageLocation = "US"

    # Get the user object from Microsoft Graph
    $UserObject = Get-MgUser -UserId $EmailAddress

    # Get the SkuId from Microsoft Graph
    $SKULicense = Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq "$SkuPartNumber"}
    $SkuId = $SKULicense.SkuId

    # Set the license to add
    $AddLicense = @{SkuId = $SkuId; DisabledPlans = @()}

    # Update the user object in Microsoft Graph
    Update-MGUser -UserId $UserObject.Id -UsageLocation $UsageLocation

    # Add the license to the user
    Set-MguserLicense -UserId $UserObject.Id -AddLicenses $AddLicense -RemoveLicenses @()
}
