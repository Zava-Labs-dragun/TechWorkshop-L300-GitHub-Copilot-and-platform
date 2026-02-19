@description('Azure Container Registry name')
param acrName string

@description('Location for resources')
param location string = resourceGroup().location

@description('SKU for ACR')
@allowed(['Basic', 'Standard', 'Premium'])
param acrSku string = 'Basic'

@description('Tags to apply to resources')
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: false
  }
}

output acrId string = acr.id
output acrLoginServer string = acr.properties.loginServer
output acrName string = acr.name
