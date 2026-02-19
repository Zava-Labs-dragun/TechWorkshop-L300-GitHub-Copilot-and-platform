@description('App Service Plan name')
param planName string

@description('Location for resources')
param location string = resourceGroup().location

@description('SKU name for the App Service Plan')
param skuName string = 'B1'

@description('Tags to apply to resources')
param tags object = {}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: planName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: skuName
  }
  properties: {
    reserved: true  // Required for Linux
  }
}

output planId string = appServicePlan.id
output planName string = appServicePlan.name
