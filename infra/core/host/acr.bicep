param name string
param location string = resourceGroup().location
param tags object = {}
param adminUserEnabled bool = false

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: adminUserEnabled
  }
}

output name string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer
output id string = containerRegistry.id
