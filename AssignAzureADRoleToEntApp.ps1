# Allow assigning AzureAD Roles to a user, group or service principal - without using the AzureAD module
# Input should be readble (roles names in JSON), parsed from a file

#Requires -modules Microsoft.Graph.Authentication,Microsoft.Graph.Identity.DirectoryManagement

param(
    # Please give the managed identities AzureAD object id. 
    [Parameter(Mandatory = $true)]
    [string] $objectId,
    [string] $rolesTemplate = "RealmJoinVnext\RjvNextRoles.json",
    [switch] $disconnectAfterExecution = $false
)

## Authenticate as admin (delegated). Use MS Graph PowerShell SDK to leverage existing (well known) clientId/app.
## Will sign you in using your browser and ask for granting permissions if needed.
Select-MgProfile -Name "v1.0"
Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory"

## Read the roles template
$targetRoles = Get-Content -Path $rolesTemplate | ConvertFrom-Json

## Get all AzureAD roles. Create a hashtable giving "DisplayName -> Id"
$directoryRoles = @{}
Get-MgDirectoryRole | ForEach-Object {
    $directoryRoles.add($_.DisplayName, $_.Id)
}

## Add 
$targetRoles | ForEach-Object {
    New-MgDirectoryRoleMemberByRef -DirectoryRoleId ($directoryRoles[$_]) -AdditionalProperties @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$objectId" } -ErrorAction SilentlyContinue
}

if ($disconnectAfterExecution) {
    Disconnect-MgGraph
}