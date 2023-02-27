#Create Azure AD Application Registration for BitTitan MigrationWiz
#Used for Modern Authentication in Exchange Online

# Define variables for the application
$appName = "MigrationWiz"
$redirectUri = "urn:ietf:wg:oauth:2.0:oob"
$scope = "EWS.AccessAsUser.All"

# Register the application
$app = New-AzureADApplication -DisplayName $appName -PublicClient $false -ReplyURLs $redirectUri

# Add the required resource access
$resourceAppId1 = "00000002-0000-0ff1-ce00-000000000000"
$resourceAccess1 = [Microsoft.Open.AzureAD.Model.RequiredResourceAccess]@{
    ResourceAppId = $resourceAppId1
    ResourceAccess = [Microsoft.Open.AzureAD.Model.ResourceAccess]@{
        Id = "3b5f3d61-589b-4a3c-a359-5dd4b5ee5bd5"
        Type = "Scope"
    }
}

$resourceAppId2 = "00000003-0000-0000-c000-000000000000"
$resourceAccess2 = [Microsoft.Open.AzureAD.Model.RequiredResourceAccess]@{
    ResourceAppId = $resourceAppId2
    ResourceAccess = [Microsoft.Open.AzureAD.Model.ResourceAccess]@{
        Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
        Type = "Scope"
    }
}

$app | Set-AzureADApplication -RequiredResourceAccess $resourceAccess1,$resourceAccess2

# Export the client ID and tenant ID
$clientID = $app.AppId
$tenantID = Get-AzureADTenantDetail
$tenantId = $tenantId.ObjectId

Write-Host "App Name: $app.DisplayName" -ForegroundColor Green
Write-Host "Client ID: $clientID" -ForegroundColor Green
Write-Host "Tenant ID: $tenantID" -ForegroundColor Green

