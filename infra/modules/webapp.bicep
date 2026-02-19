@description('Web App name')
param webAppName string

@description('Location for resources')
param location string = resourceGroup().location

@description('App Service Plan ID')
param appServicePlanId string

@description('ACR login server (e.g. myacr.azurecr.io)')
param acrLoginServer string

@description('Container image name and tag (e.g. zavastore:latest)')
param containerImage string = 'zavastore:latest'

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Tags to apply to resources')
param tags object = {}

resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  tags: union(tags, { 'azd-service-name': 'web' })
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${containerImage}'
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
      ]
      alwaysOn: false
    }
    httpsOnly: true
  }
}

output webAppId string = webApp.id
output webAppName string = webApp.name
output webAppPrincipalId string = webApp.identity.principalId
output webAppDefaultHostName string = webApp.properties.defaultHostName
