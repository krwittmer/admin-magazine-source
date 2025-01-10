<#
.SYNOPSIS
    Assigns a role to a user for an Azure DevCenter project.
.DESCRIPTION
    This script fetches the resource ID for an Azure DevCenter project and assigns a specified role to a user.
.PARAMETER ResourceGroup
    The name of the resource group. Defaults to 'rg-learning-beagle'.
.PARAMETER ProjectName
    The name of the Azure DevCenter project. Defaults to 'dcprj-devbox-test'.
.PARAMETER ProjectResourceType
    The resource type of the Azure DevCenter project. Defaults to 'Microsoft.DevCenter/projects'.
.PARAMETER AssigneeEmail
    The email of the user to assign the role to. Defaults to 'wik2mtp@bosch.com'.
.PARAMETER RoleName
    The name of the role to assign. Defaults to 'DevCenter Project Admin'.
.EXAMPLE
    .\Assign-Role.ps1 -ResourceGroup 'myResourceGroup' -ProjectName 'myProject' -AssigneeEmail 'user@example.com' -RoleName 'Contributor'
#>

param (
    [string]$ResourceGroup = "rg-cg-devcenter-tzz3-1217081937",
    [string]$ProjectName = "project-33",
    [string]$ProjectResourceType = "Microsoft.DevCenter/projects",
    [string]$AssigneeEmail = "wik2mtp@bosch.com",
    [string]$RoleName = "DevCenter Project Admin"
)

# Connect to Azure account
Connect-AzAccount

# Fetch the resource ID for the Azure DevCenter project
try {
    $resource = Get-AzResource -ResourceGroupName $ResourceGroup -ResourceType $ProjectResourceType -ResourceName $ProjectName
    $resourceId = $resource.ResourceId

    if (-not $resourceId) {
        Write-Error "Error: Unable to fetch resource ID for $ProjectName in $ResourceGroup."
        exit 1
    } else {
        Write-Host "Resource ID: $resourceId"
    }
} catch {
    Write-Error "Error: Unable to fetch resource ID for $ProjectName in $ResourceGroup. $_"
    exit 1
}

# Assign the DevCenter Project Admin role
try {
    New-AzRoleAssignment -ObjectId (Get-AzADUser -UserPrincipalName $AssigneeEmail).Id -RoleDefinitionName $RoleName -Scope $resourceId

    Write-Host "Role assignment successful for $AssigneeEmail on resource $ProjectName."
} catch {
    Write-Error "Error: Role assignment failed. $_"
    exit 1
}