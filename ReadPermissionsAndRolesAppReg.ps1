param(
    [Parameter(Mandatory = $true)]
    [string] $appRegObjectId,
    # Filenames will be created from the application name if left empty
    [string] $rolesOutputFile,
    [string] $permissionsOutputFile
)

# This is just a proxy to get the Managed (Enterprise) App from the App Registration and fetch roles and permissions there.

## Authenticate as admin (delegated). Use MS Graph PowerShell SDK to leverage existing (well known) clientId/app.
## Will sign you in using your browser and ask for granting permissions if needed.
Select-MgProfile -Name "v1.0"
Connect-MgGraph -Scopes "AppRoleAssignment.ReadWrite.All,Application.Read.All,RoleManagement.Read.Directory"

# Resolve ent. app by appreg
$appreg = Get-MgApplication -ApplicationId $appRegObjectId
$entapp = Get-MgServicePrincipal -Filter "AppId eq '$($appreg.appId)'"

. $PSScriptRoot\ReadPermissionsAndRolesEntApp.ps1 -enterpriseAppObjId $entapp.id -rolesOutputFile $rolesOutputFile -permissionsOutputFile $permissionsOutputFile