param(
    # Please give the app registration's object id. 
    [Parameter(Mandatory = $true)]
    [string] $entAppObjectId
)

# Install Modules if needed
if ((Get-Module -Name Microsoft.Graph.Applications,Microsoft.Graph.Authentication,Microsoft.Graph.Identity.DirectoryManagement -ListAvailable).count -eq 0) {
    Install-Module -Name Microsoft.Graph.Applications,Microsoft.Graph.Authentication,Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser
}
# Verify Modules are available
if ((Get-Module -Name Microsoft.Graph.Applications -ListAvailable) -and (Get-Module Microsoft.Graph.Authentication -ListAvailable) -and (Get-Module Microsoft.Graph.Identity.DirectoryManagement -ListAvailable)) {
    "MS Graph Modules are available"
} else {
    "Could not find/install MS Graph modules. Please make sure these are available:"
    " - Microsoft.Graph.Authentication"
    " - Microsoft.Graph.Applications"
    " - Microsoft.Graph.Identity.DirectoryManagemet"
    ""
    throw ("modules not available")
}

# Do the login now with all scopes. This will prevent asking for multiple grants.
Select-MgProfile -Name "v1.0"
Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory,Application.ReadWrite.All,AppRoleAssignment.ReadWrite.All,Application.Read.All"

. ..\GrantAppPermToEntApp.ps1 -enterpriseAppObjId $entAppObjectId -permissionsTemplate .\RJvNextPermissions.json 
. ..\AssignAzureADRoleToEntApp.ps1 -objectId $entAppObjectId -rolesTemplate .\RJvNextRoles.json -disconnectAfterExecution:$true

