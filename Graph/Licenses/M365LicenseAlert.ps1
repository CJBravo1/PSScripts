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
    $LicenseDetails += $LicenseDetail
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
    #Output
    #$LicenseName
    #$PercentUsed
