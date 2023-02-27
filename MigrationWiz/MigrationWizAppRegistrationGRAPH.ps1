#Under Construction!
#Create Azure AD Application Registration for BitTitan MigrationWiz
#Used for Modern Authentication in Exchange Online

# Install the Microsoft Graph PowerShell module if not already installed
if ($null -eq (Get-Module -ListAvailable Microsoft.graph)) {
    Write-Host "Installing Microsoft Graph PSModule" -ForegroundColor Green
    Install-Module Microsoft.Graph -Scope CurrentUser
}

# Connect to Microsoft Graph using a tenant administrator account
Connect-MgGraph -Scopes Application.ReadWrite.All,Directory.Read.All,Directory.AccessAsUser.All
$mgContext = Get-MgContext
$mgContextuser = $mgContext.Account
Write-Host "Connected As $mgContextuser" -ForegroundColor Yellow

# Define the application registration details
$AppName = "migrationWiz"
$RedirectUri = "urn:ietf:wg:oauth:2.0:oob"
$ResourceAccess = @(
    [Microsoft.Graph.RequiredResourceAccess]@{
        Id = "3b5f3d61-589b-4a3c-a359-5dd4b5ee5bd5"
        Type = "Scope"
    },
    [Microsoft.Graph.RequiredResourceAccess]@{
        Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
        Type = "Scope"
    }
)

# Register the application
$AppRegistration = New-MgApplication -DisplayName $AppName -DefaultRedirectUri $RedirectUri -RequiredResourceAccess $ResourceAccess

# Export the client ID and tenant ID
$ClientId = $AppRegistration.AppId
$TenantId = (Get-MgOrganization).Id

# Output the client ID and tenant ID
Write-Host "Client ID: $ClientId"
Write-Host "Tenant ID: $TenantId"
