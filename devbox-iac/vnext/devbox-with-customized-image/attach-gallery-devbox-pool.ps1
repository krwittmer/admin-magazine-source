# Parameters
$resourceGroup = "rg-cg-devcenter-dotnet-gallery-y"
$templateFile = ".\customized-image\customized-image.json"

$randomNumber = Get-Random -Minimum 1001 -Maximum 10000

$galleryName = "MyDotnetGallery"
$galleryName = "$galleryName$randomNumber"
$parameters = @{
    personaImage = "dotnet"
    imageGalleryName = $galleryName
    imageDefinitionName = "DotnetDevImage"
}

$resourceGroupDevCenter = "rg-cg-devcenter-y-1128153247"

$devCenterName = "devcenter-3"
$devCenterId = "/subscriptions/aee045ae-fa1a-41e3-b381-8f33712dc76f/resourceGroups/$resourceGroupDevCenter/providers/Microsoft.DevCenter/devcenters/$devCenterName"
$projectName = "DotnetDevProject"
$projectName = "$projectName$randomNumber"

$location = "westus3"
$galleryResourceId = "/subscriptions/aee045ae-fa1a-41e3-b381-8f33712dc76f/resourceGroups/$resourceGroup/providers/Microsoft.Compute/galleries/$galleryName"

$poolName = "DotnetDevPool"
$networkConnectionName = "internal-network-connection"
$subnetId = "/subscriptions/aee045ae-fa1a-41e3-b381-8f33712dc76f/resourceGroups/internal-network-rg/providers/Microsoft.Network/virtualNetworks/vnet-dev-center/subnets/subnet-dev-center"
$domainName = "corp.microsoft.com"
$joinType = "HybridAzureADJoin"

# Step 1: Deploy the Azure Image Gallery
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroup `
    -TemplateFile $templateFile `
    -TemplateParameterObject $parameters

# Step 2: Attach the Azure Image Gallery to the Devcenter
New-AzDevCenterAdminGallery -Name $galleryName `
    -DevCenterName $devCenterName `
    -ResourceGroupName $resourceGroupDevCenter `
    -GalleryResourceId $galleryResourceId

# Step 3: Create a Devcenter Project
New-AzDevCenterAdminProject -ResourceGroupName $resourceGroupDevCenter `
    -DevCenterId $devCenterId -Name $projectName `
    -Description "Project for .NET Development with internal networking" `
    -Location $location

# Step 4: Assign a user to the new Devcenter project
$projectResourceType = "Microsoft.DevCenter/projects"
$assigneeEmail = "wik2mtp@bosch.com"
$roleName = "DevCenter Project Admin"

$resource = Get-AzResource -ResourceGroupName $resourceGroupDevCenter -ResourceType $projectResourceType -ResourceName $projectName
$resourceId = $resource.ResourceId
New-AzRoleAssignment -ObjectId (Get-AzADUser -UserPrincipalName $assigneeEmail).Id -RoleDefinitionName $roleName -Scope $resourceId

#
# ..
# Step 5: Create a Devcenter Definition - should be be straightforward
#   New-AzDevCenterAdminDevBoxDefinition -ResourceGroupName $resourceGroupName -ProjectName $projectName -Name $devBoxDefinitionName -Sku $sku ..
#   New-AzDevCenterAdminDevBoxDefinition -Name "WebDevBox" -DevCenterName $devCenterName -ResourceGroupName $resourceGroupDevCenter -Location "westus3" -HibernateSupport "Enabled" -ImageReferenceId "/subscriptions/aee045ae-fa1a-41e3-b381-8f33712dc76f/resourceGroups/AzCustomImageDeployGroup18/providers/Microsoft.Compute/galleries/MyDotnetGallery18/images/DotnetDevImage/versions/1.0.0" -OSStorageType "ssd_256gb" -SkuName "general_a_8c32gb_v1"

# Step 6: Create a Dev Center Pool - this is where you bind to the network!  (e.g., internal Microsoft network, local vnet)
#   Do this with Azure CLI, PowerShell, or maybe just show the GUI step.
#     New-AzDevCenterAdminPool -ResourceGroupName $resourceGroupName -ProjectName $projectName -Name $devBoxPoolName -Description $poolDescription -DevBoxDefinitionName $devBoxDefinitionName -MaxInstances $maxInstances
#

# Step N: Verification (Optional)
# List Projects
#  Get-AzDevCenterAdminProject -ResourceGroupName $resourceGroupDevCenter

# List Galleries
#  Get-AzDevCenterAdminGallery -ResourceGroupName $resourceGroupDevCenter
#   ..
