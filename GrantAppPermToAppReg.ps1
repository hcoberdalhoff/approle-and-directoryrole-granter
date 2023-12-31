# Allow assigning MS Graph and similar permissions to an App Regsitration - without using the AzureAD module
# Input should be readble (claim names in JSON), parsed from a file

#Requires -modules Microsoft.Graph.Applications,Microsoft.Graph.Authentication

param(
    # Please give the app registration's object id. 
    [Parameter(Mandatory = $true)]
    [string] $appRegObjectId,
    [string] $permissionsTemplate = "RealmJoinVnext\RjvNextPermissions.json",
    [switch] $updateEnterpriseApp = $false,
    [switch] $disconnectAfterExecution = $false,
    [switch] $showErrors = $false
)

## Authenticate as admin (delegated). Use MS Graph PowerShell SDK to leverage existing (well known) clientId/app.
## Will sign you in using your browser and ask for granting permissions if needed.
Connect-MgGraph -Scopes "Application.ReadWrite.All" 

## Read the permission template
$permissions = Get-Content -Path $permissionsTemplate | ConvertFrom-Json

$requiredResourceAccess = @()

$permissions | ForEach-Object {
    $appId = $_.Id

    ## Get Service Principal from Application:
    $resourceApp = Get-MgServicePrincipal -Filter "AppId eq '$appId'" 

    ## Get all AppRoles. Create a hashtable giving "Claim -> AppRoleId"
    $appRoles = @{}
    $resourceApp.AppRoles | ForEach-Object {
        $appRoles.add($_.Value, $_.Id)
    }

    $requiredResourceAccessItem = @{
        "resourceAppId"  = $appId
        "resourceAccess" = [array]($_.AppRoleAssignments | ForEach-Object { @{"Id" = $appRoles[$_]; "Type" = "Role" } } )
    }

    $requiredResourceAccess += $requiredResourceAccessItem

}
""
"## Setting new permissions on the App Registration..."
try {
    Update-MgApplication -ApplicationId $appRegObjectId -RequiredResourceAccess $requiredResourceAccess -ErrorAction Stop
}
catch {
    "## - Assignment failed."
    if ($showErrors) {
        $_
    }
}
""

if ($updateEnterpriseApp) {
    ## Option 1 - Use Graph on the linked enterprise app to grant.
    ## Get linked enterprise app
    $entApp = Get-MgServicePrincipal -Filter "AppId eq '$((Get-MgApplication -ApplicationId $appRegObjectId).AppId)'"

    ## Granting the permission to the managed/linked enterprise app
    . $PSScriptRoot\GrantAppPermToEntApp.ps1 -enterpriseAppObjId $entApp.Id -permissionsTemplate $permissionsTemplate
}
else {
    ## Option 2 - Grant new permissions manually:
    #"## Wating 30 sec. AzureAD needs a moment tp update the permissions..."
    #Start-Sleep 30
    #""
    "## To enable the new permissions, please wait some seconds and visit the follwing URL to grant the updated permissions."
    ""
    "https://login.microsoftonline.com/$((Get-MgContext).TenantId)/adminconsent?client_id=$((Get-MgApplication -ApplicationId $appRegObjectId).AppId)"
    ""
    "It is ok if this shows a 'No reply address is registered for the application' error."
}

if ($disconnectAfterExecution) {
    Disconnect-MgGraph | Out-Null
}