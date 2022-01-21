# AppRole and DirectoryRole Granter

Mass-Grant MS Graph and AzureAD permissions to App Registrations, Enterprise Apps and Mgd. Identities.

You don't need the legacy AzureAD / AzureADPreview modules. These scripts use Microsoft's Graph PowerShell SDK. 

## RealmJoin vNext 

### Prepare an Azure Automation Account for RJ vNext

Get the AzureAD object id of the AppRegistration belonging to the RunAs Account (e.g. `a489c529-c750-4100-91e4-c4cbeee96143`).

```powershell
cd RealmJoinVnext
. .\AllInOne.ps1 -appRegObjectId "a489c529-c750-4100-91e4-c4cbeee96143" 
``` 

This will open a browser to let a GA (or similiar admin) sign in and grant access to the Microsoft Graph Powershell. 

You can reapply these permissions at any time; for example if new permissions were added to the JSON files. Existing permissions will create (non-terminating) errors. You can ignore those.

## Generic Examples

### Assign MS Graph permissions to an App Registration

Get the AzureAD object id of the AppRegistration (e.g. `a489c529-c750-4100-91e4-c4cbeee96143`)

Prepare a JSON file `graphpermissions.json` containing the AppRole Names you want to assign. See [RealmJoin vNext Runbook permissions](RealmJoinVnext/RJvNextPermissions.json) as an example.

```powershell
. .\GrantAppPermToAppReg.ps1 -appRegObjectId "a489c529-c750-4100-91e4-c4cbeee96143" -permissionsTemplate .\graphpermissions.json
``` 

This will open a browser to let a GA (or similiar admin) sign in.

This script will automatically also grant the permissions on the corresponding Enterprise App by calling `GrantAppPermToEntApp.ps1`.

### Assign MS Graph permissions to a Service Principal (like a Managed Identity)

Get the AzureAD object id of the Mgd. Identity / Service Principal (e.g. `a489c529-c750-4100-91e4-c4cbeee96143`)

Prepare a JSON file `graphpermissions.json` containing the AppRole Names you want to assign. See [RealmJoin vNext Runbook permissions](RealmJoinVnext/RJvNextPermissions.json) as an example.

```powershell
. . .\GrantAppPermToEntApp.ps1 -enterpriseAppObjId "a489c529-c750-4100-91e4-c4cbeee96143" -permissionsTemplate .\graphpermissions.json
``` 

This will open a browser to let a GA (or similiar admin) sign in.

### Assign AzureAD admin roles to a Service Principal (like a Managed Identity)

Get the object id of the object you want to give roles to. (e.g. `a489c529-c750-4100-91e4-c4cbeee96143`)

Prepare a JSON file `roles.json` containing the AzureAD Role Names you want to assign. See [RealmJoin vNext Runbook Roles](RealmJoinVnext/RJvNextRoles.json) as an example.

```powershell
. .\AssignAzureADRoleToEntApp.ps1 -objectId "a489c529-c750-4100-91e4-c4cbeee96143" -rolesTemplate .\roles.json
``` 
