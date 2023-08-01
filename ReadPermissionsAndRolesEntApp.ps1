param(
    [Parameter(Mandatory = $true)]
    [string] $enterpriseAppObjId,
    # Filename will be created from the application name if left empty
    [string] $rolesOutputFile,
    [string] $permissionsOutputFile
)

## Authenticate as admin (delegated). Use MS Graph PowerShell SDK to leverage existing (well known) clientId/app.
## Will sign you in using your browser and ask for granting permissions if needed.
Connect-MgGraph -Scopes "AppRoleAssignment.ReadWrite.All,Application.Read.All,RoleManagement.Read.Directory"

# Find the Enterprise App
$entApp = Get-MgServicePrincipal -ServicePrincipalId $enterpriseAppObjId -ErrorAction Stop

# Make sure, outputPaths exist
if (-not $rolesOutputFile) {
    $rolesOutputFile = ($entapp.DisplayName -replace "[$([RegEx]::Escape([string][IO.Path]::GetInvalidFileNameChars()))]+", "_") + "_roles.json"
}
if (-not $permissionsOutputFile) {
    $permissionsOutputFile = ($entapp.DisplayName -replace "[$([RegEx]::Escape([string][IO.Path]::GetInvalidFileNameChars()))]+", "_") + "_permissions.json"
}

$permissions = @()

# Read Permissions from Enterprise App
$appRoles = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $enterpriseAppObjId



$appRoles | Group-Object -Property 'ResourceId' | ForEach-Object {
    $permissionDescription = @{}
    $permissionDescription["Name"] = $_.Group[0].ResourceDisplayName
    $resource = Get-MgServicePrincipal -ServicePrincipalId $_.Group[0].ResourceId
    $permissionDescription["Id"] = $resource.AppId

    $appRoleNames = @()
    $_.Group | ForEach-Object {
        $AppRoleId = $_.AppRoleId
        $appRoleNames += ($resource.AppRoles | Where-Object { $_.Id -eq $AppRoleId }).Value
    }
    $permissionDescription["AppRoleAssignments"] = $appRoleNames
    
    $permissions += $permissionDescription
}

if ($permissions) {
    ConvertTo-Json -InputObject $permissions > $permissionsOutputFile
    "## Permissions successfully written to '$permissionsOutputFile'."
}
else {
    "## No permissions found. Not writing to '$permissionsOutputFile'."
}

$roles = @()

# Get Roles by ent. app
$directoryRoles = Get-MgServicePrincipalMemberOf -ServicePrincipalId $entapp.id | Where-Object { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.directoryRole' }
$directoryRoles | ForEach-Object {
    $roles += (Get-MgDirectoryRole -DirectoryRoleId $_.Id).DisplayName
}

if ($roles) {
    ConvertTo-Json -InputObject $roles > $rolesOutputFile
    "## Roles successfully writte to '$rolesOutputFile'."
}
else {
    "## No roles found. Not writing to '$rolesOutputFile'."
}