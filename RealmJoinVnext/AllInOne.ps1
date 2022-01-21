#Requires -modules Microsoft.Graph.Applications,Microsoft.Graph.Authentication,Microsoft.Graph.Identity.DirectoryManagement

param(
    # Please give the app registration's object id. 
    [Parameter(Mandatory = $true)]
    [string] $appRegObjectId
)

# Do the login now with all scopes. This will prevent asking for multiple grants.
Select-MgProfile -Name "v1.0"
Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory,Application.ReadWrite.All,AppRoleAssignment.ReadWrite.All,Application.Read.All"

## Get linked enterprise app
$entApp = Get-MgServicePrincipal -Filter "AppId eq '$((Get-MgApplication -ApplicationId $appRegObjectId).AppId)'"

. ..\GrantAppPermToAppReg.ps1 -appRegObjectId $appRegObjectId -permissionsTemplate .\RJvNextPermissions.json -updateEnterpriseApp:$true
. ..\AssignAzureADRoleToEntApp.ps1 -objectId $entApp.Id -rolesTemplate .\RJvNextRoles.json -disconnectAfterExecution:$true

