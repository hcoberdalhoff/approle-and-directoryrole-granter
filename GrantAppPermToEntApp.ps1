# Allow assigning MS Graph and similar permissions to a Managed Identity - without using the AzureAD module
# Input should be readble (claim names in JSON), parsed from a file

# based on https://techcommunity.microsoft.com/t5/integrations-on-azure-blog/grant-graph-api-permission-to-managed-identity-object/ba-p/2792127

#Requires -modules Microsoft.Graph.Applications,Microsoft.Graph.Authentication

param(
    # Please give the managed identity's or enterprise app's object id.  
    [Parameter(Mandatory = $true)]
    [string] $enterpriseAppObjId,
    [string] $permissionsTemplate = "RealmJoinVnext\RjvNextPermissions.json",
    [switch] $disconnectAfterExecution = $false,
    [switch] $showErrors = $false
)

## Authenticate as admin (delegated). Use MS Graph PowerShell SDK to leverage existing (well known) clientId/app.
## Will sign you in using your browser and ask for granting permissions if needed.
Connect-MgGraph -Scopes "AppRoleAssignment.ReadWrite.All,Application.Read.All"

## Read the permission template
$permissions = Get-Content -Path $permissionsTemplate | ConvertFrom-Json

"## Set permissions on the enterprise app/mgd identity"
$permissions | ForEach-Object {
    $appId = $_.Id

    ## Get Service Principal from Application:
    $resourceApp = Get-MgServicePrincipal -Filter "AppId eq '$appId'" 
    $resourceId = $resourceApp.Id

    ## Get all AppRoles. Create a hashtable giving "Claim -> AppRoleId"
    $appRoles = @{}
    $resourceApp.AppRoles | ForEach-Object {
        $appRoles.add($_.Value, $_.Id)
    }

    ## Apply each permission to the Ent App/Mgd. Identity
    $_.AppRoleAssignments | ForEach-Object {
        "## Assigning $($resourceApp.DisplayName):$_"
        try {
            New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $enterpriseAppObjId -AppRoleId $appRoles[$_] -ResourceId $resourceId -PrincipalId $enterpriseAppObjId -ErrorAction Stop | Out-Null
        }
        catch {
            "## - Permission already assigned or assignment failed. Skipping..."
            if ($showErrors) {
                $_
            }
        }
    }
}

if ($disconnectAfterExecution) {
    Disconnect-MgGraph | Out-Null
}
