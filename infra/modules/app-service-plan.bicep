@description('Region. The same as the resource group, given by main.bicep.')
param location string

@description('Name of the App Service plan.')
@minLength(1)
@maxLength(60)
param planName string

@description('Plan tier: B1, or P0v3 for the faster alternative.')
param planSku string

resource appServicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: planName
  location: location
  kind: 'linux'
  sku: {
    name: planSku
  }
  properties: {
    reserved: true
  }
}

// Another file cannot read this resource directly. What it needs comes out through an output.
output appServicePlanId string = appServicePlan.id
