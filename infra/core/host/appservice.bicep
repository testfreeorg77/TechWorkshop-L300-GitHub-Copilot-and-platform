param name string
param location string = resourceGroup().location
param tags object = {}
param appServicePlanId string
param allowedOrigins array = []
param appSettings object = {}
param containerRegistryName string
param managedIdentity bool = true

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: managedIdentity ? 'SystemAssigned' : 'None'
  }
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/${name}:latest'
      appSettings: [
        for item in items(appSettings): {
          name: item.key
          value: item.value
        }
      ]
      cors: {
        allowedOrigins: allowedOrigins
      }
      acrUseManagedIdentityCreds: true
    }
  }
}

resource config 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: appService
  name: 'logs'
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Verbose'
      }
    }
    detailedErrorMessages: {
      enabled: true
    }
    failedRequestsTracing: {
      enabled: true
    }
    httpLogs: {
      fileSystem: {
        enabled: true
        retentionInDays: 1
        retentionInMb: 35
      }
    }
  }
}

output name string = appService.name
output identityPrincipalId string = managedIdentity ? appService.identity.principalId : ''
output defaultHostName string = appService.properties.defaultHostName
