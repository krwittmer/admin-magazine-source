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
.PARAMETER TemplateFile
    The file of the BICEP template to use.
.EXAMPLE
    .\deploy-devcenter-cust-image.ps1 -ParametersFile 'params.json' -ResourceGroupName 'myResourceGroup' -TemplateUri 'https://my-template-url'
    .\deploy-devcenter-cust-image.ps1 -ResourceGroupName 'rg-cg-devcenter'
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]  # Optional parameter
    [string]$ParametersFile = "azuredeploy.parameters.json",

    [Parameter(Mandatory = $false)]  # Optional parameter
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]  # Optional parameter
    [string]$TemplateFile = "C:\Users\WIK2MTP\source\repos\devbox-IaaS\arm\devbox-with-customized-image\main.bicep"
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

# Add randomness to the deployment parameters
$randomSuffix = Get-Random -Minimum 1 -Maximum 99

# Deploy the ARM template using PowerShell cmdlet
try {
    Write-Host "Deploying ARM template from $TemplateUri with parameters file: $ParametersFile"

    $arguments = @{
        ResourceGroupName = $ResourceGroupName
        TemplateFile       = $TemplateFile
        TemplateParameterFile = $ParametersFile
        suffix            = $randomSuffix
        verbose           = $true
        debug             = $true
    }

#
# Add these flags to see what's happening and to capture info for debugging purposes:
#
#   New-AzResourceGroupDeployment  .. ..  -verbose -debug
#
#

    $formattedCmdlet = @"
New-AzResourceGroupDeployment -ResourceGroupName '$ResourceGroupName' `
                            -TemplateFile '$TemplateFile' `
                            -TemplateParameterFile '$ParametersFile' `
                            -suffix '$randomSuffix' `
                            -verbose -debug   (OPTIONAL FLAGS!)
"@
    Write-Host "Executing the following command:"
    Write-Host $formattedCmdlet -ForegroundColor Cyan

    New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName `
                                  -TemplateFile $TemplateFile `
                                  -TemplateParameterFile $ParametersFile `
                                  -suffix $randomSuffix `
                                  
    Write-Host "Deployment successful."
} catch {
    Write-Error "Failed during deployment: $_"
    exit 1
}
