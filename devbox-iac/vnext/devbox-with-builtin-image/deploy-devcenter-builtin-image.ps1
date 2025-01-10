<#
.SYNOPSIS
    Deploys an Azure resource group using an ARM template and parameter file.
.DESCRIPTION
    This script reads an ARM template and parameter file, validates the location parameter,
    and creates a resource group followed by a deployment in Azure.
.PARAMETER ParametersFile
    The path to the parameter file in JSON format. Defaults to 'azuredeploy.parameters.json'.
.PARAMETER ResourceGroupName
    The name of the resource group to create. If not specified, the user will be prompted to enter it.
.PARAMETER TemplateUri
    The URI of the ARM template to use. Defaults to the Azure Quickstart template.
.EXAMPLE
    .\deploy-devcenter-builtin-image.ps1 -ParametersFile 'params.json' -ResourceGroupName 'myResourceGroup' -TemplateUri 'https://my-template-url'
.EXAMPLE
    .\deploy-devcenter-builtin-image.ps1 -ParametersFile "mui-azuredeploy.parameters.json" -TemplateUri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.devcenter/devbox-with-builtin-image/azuredeploy.json"
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]  # Optional parameter
    [string]$ParametersFile = "azuredeploy.parameters.json",

    [Parameter(Mandatory = $false)]  # Optional parameter
    [switch]$AddSuffix,

    [Parameter(Mandatory = $false)]  # Optional parameter
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]  # Optional parameter
    [string]$TemplateUri
)

# Set the default location
$location = "westus3"

# Validate and load the parameters file
if (-Not (Test-Path -Path $ParametersFile)) {
    Write-Error "Parameters file not found: $ParametersFile"
    exit 1
}

try {
    $ParametersContent = Get-Content -Path $ParametersFile -Raw | ConvertFrom-Json
} catch {
    Write-Error "Error reading or parsing the parameters file: $_"
    exit 1
}

# Check for location in the parameters file
if ($ParametersContent.parameters -and $ParametersContent.parameters.location) {
    $location = $ParametersContent.parameters.location.value
} else {
    Write-Warning "Location parameter is not specified in the parameter file. Using default location: $location"
}

# Prompt for the resource group name if not specified as an argument
if (-Not $ResourceGroupName) {
    $ResourceGroupName = Read-Host "Please enter resource group name (e.g., rg-devbox-dev)"
    if (-Not $ResourceGroupName) {
        Write-Error "Resource group name cannot be empty."
        exit 1
    }
}
# Append timestamp for uniqueness
$ResourceGroupName += "-$(Get-Date -Format 'MMddHHmmss')"

# Create the resource group using PowerShell cmdlet
try {
    Write-Host "Creating resource group: $ResourceGroupName in location: $location"
    New-AzResourceGroup -Name $ResourceGroupName -Location $location
} catch {
    Write-Error "Failed to create resource group: $_"
    exit 1
}

# Deploy the ARM template using PowerShell cmdlet
try {
    Write-Host "Deploying ARM template from $TemplateUri with parameters file: $ParametersFile"
    if ($AddSuffix) {
        New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName `
                                      -TemplateUri $TemplateUri `
                                      -TemplateParameterFile $ParametersFile `
                                      -TemplateParameterObject @{suffix = $AddSuffix} `
                                      -verbose -debug
    } else {
        New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName `
                                      -TemplateUri $TemplateUri `
                                      -TemplateParameterFile $ParametersFile `
                                      -verbose -debug
    }
                                  
    Write-Host "Deployment successful."
} catch {
    Write-Error "Failed during deployment: $_"
    exit 1
}
