<#
.SYNOPSIS
This script connects to Microsoft Graph and retrieves license information for M365 subscriptions. It then sends an email with a table displaying the license usage details.

.DESCRIPTION
The script first checks if the Microsoft.Graph and Azure PowerShell modules are installed. If not, it installs the Microsoft.Graph module. It then connects to Microsoft Graph using the Connect-MgGraph cmdlet.

Next, it defines email variables for the sender and recipient addresses.

The script creates an empty table to store license details. It retrieves all M365 subscriptions using the Get-MgSubscribedSKU cmdlet and iterates through each subscription to gather properties such as license name, consumed units, available units, and percent used. It calculates the percent used by dividing consumed units by available units and multiplying by 100.

The script converts the array of license details to an HTML table using the ConvertTo-Html cmdlet. It then constructs the email body with the license table embedded in HTML.

Finally, it sends the email using the Send-MgUserMail cmdlet.

.PARAMETER None

.EXAMPLE
.\M365LicenseAlert.ps1
# Connects to Microsoft Graph, retrieves license details, and sends an email with the license usage table.

.NOTES
- This script requires the Microsoft.Graph and Azure PowerShell modules to be installed.
- The sender and recipient email addresses need to be specified in the script.
- The script requires appropriate permissions to access Microsoft Graph.
#>


#Connect to Microsoft Graph
#Check if Microsof.Graph and Azure Powershell Module are Installed.
if ($null -eq (Get-InstalledModule microsoft.graph -ErrorAction SilentlyContinue))
    {
        Write-Host "Installing Microsoft Graph Powershell Modules" -ForegroundColor Green
        Install-Module Microsoft.Graph -Scope CurrentUser -Verbose
    } 
#Check for current Graph Connections
$MGContext = Get-MgContext
if ($null -eq $MGContext)
{
    Connect-MgGraph -Scopes 'User.Read.All', 'Directory.AccessAsUser.All', 'User.ReadBasic.All', 'User.ReadWrite.All', 'Directory.Read.All', 'Directory.ReadWrite.All', 'Group.Read.All', 'User.Export.All','AuditLog.Read.All'
}

#Email Variables
$EmailTO = "example@domain.com"
$EmailFrom = "example@domain.com"

#Create Table
$LicenseDetails = @()
#Gather All M365 Subscriptions
$MGSubscribedSku = Get-MgSubscribedSKU -All -Property @("SkuId", "ConsumedUnits", "PrepaidUnits","AccountId","AccountName","SkuPartNumber")
#$MGSubscribedSku = $MGSubscribedSku | Where-Object {$_.SkuPartNumber -eq "ENTERPRISEPACK" -or $_.SkuPartNumber -eq "SPE_E3"}

foreach ($Subscription in $MGSubscribedSku)
{
    #Gather Properties
    $LicenseName = $Subscription.SkuPartNumber
    $ConsumedUnits = $Subscription.ConsumedUnits
    $AvailableUnits = $Subscription.PrepaidUnits.Enabled
    $PercentUsed = [math]::Round(($ConsumedUnits / $AvailableUnits) * 100, 2)

    $LicenseDetail = [PSCustomObject]@{
        LicenseName = $LicenseName
        ConsumedUnits = $ConsumedUnits
        AvailableUnits = $AvailableUnits
        PercentUsed = $PercentUsed
    }
    
    # Add condition to check if percent used is greater than 80
    if ($PercentUsed -gt 80) {
        $LicenseDetails += $LicenseDetail
    }
}
# Convert the array of license details to an HTML table
$LicenseTable = $LicenseDetails | ConvertTo-Html -Property LicenseName, ConsumedUnits, AvailableUnits, PercentUsed -As Table | Out-String

#Email specifications that's going to be sent out.
$params = @{
    Message = @{
        Subject = "M365 License Alert"
        Body = @{
            ContentType = "HTML"
            Content = "
        <html>
        <head>
        <style>
            table {
                border-collapse: collapse;
                width: 80%;
            }
            th, td {
                border: 1px solid black;
                padding: 8px;
                text-align: left;
            }
        </style>
        </head>
        <body>
        <p>Office 365 E3 and Microsoft 365 E3 License Usage:</p>
        $LicenseTable
        </table>
        </body>
        </html>
        "}
    
ToRecipients = @(
    @{
        EmailAddress = @{
            Address = $EmailTO
        }
    }
)
    }
}

    #Send Email
Send-MgUserMail -UserId $EmailFrom -BodyParameter $params