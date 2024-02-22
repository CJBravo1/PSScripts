#Use this script to assign the appropriate Graph API permissions to the managed identity
Connect-MgGraph -Scopes "Application.Read.All","AppRoleAssignment.ReadWrite.All,RoleManagement.ReadWrite.Directory"

#Change the managed identity ID to the ID of the managed identity you created.
$managedIdentityID = "MANAGED_IDENTITY_GUID"  
$graphApp = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"


# Add the required Graph scopes
$graphScopes = @(
    "AccessReview.ReadWrite.Membership"
    "AccessReview.ReadWrite.All"
    "User.Read.All"
    "Mail.Send"
    "AuditLog.Read.All"
)
ForEach($scope in $graphScopes){
  $appRole = $graphApp.AppRoles | Where-Object {$_.Value -eq $scope}
  New-MgServicePrincipalAppRoleAssignment -PrincipalId $managedIdentityId -ServicePrincipalId $managedIdentityId -ResourceId $graphApp.Id -AppRoleId $appRole.Id
}