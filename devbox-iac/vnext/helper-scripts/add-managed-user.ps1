# Capture user input
$resourceGroupName = Read-Host "Enter the Azure resource group name"
$location = Read-Host "Enter the Azure region (e.g., eastus, westus3)"
$identityName = Read-Host "Enter the managed identity name"

# Create the resource group
Write-Host "Creating resource group..."
$rgCreateResult = az group create --name $resourceGroupName --location $location

# Check if resource group creation was successful
if (-not $?) {
    Write-Host "Failed to create resource group. Exiting."
    exit
}

# Create the managed identity
Write-Host "Creating managed user identity..."
$identityCreateResult = az identity create --name $identityName --resource-group $resourceGroupName --location $location

# Check if managed identity creation was successful
if (-not $?) {
    Write-Host "Failed to create managed identity. Exiting."
    exit
}

# Display the managed identity details
Write-Host "Managed identity created successfully. Details:"
az identity show --name $identityName --resource-group $resourceGroupName --output table

# Optional: Assign a role to the managed identity
$assignRole = Read-Host "Do you want to assign a role to the managed identity? (y/n)"
if ($assignRole -eq "y") {
    $role = Read-Host "Enter the role (e.g., Contributor, Reader)"
    $principalId = az identity show --name $identityName --resource-group $resourceGroupName --query "principalId" --output tsv
    $subscriptionId = az account show --query 'id' --output tsv
    az role assignment create --assignee $principalId --role $role --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"
    Write-Host "Role '$role' assigned to the managed identity."
}

Write-Host "Script execution completed."
