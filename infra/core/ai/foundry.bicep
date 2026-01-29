param name string
param location string = resourceGroup().location
param tags object = {}
param deployments array = []

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'OpenAI'
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
  }
  sku: {
    name: 'S0'
  }
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for deployment in deployments: {
  parent: account
  name: deployment.name
  properties: {
    model: deployment.model
    raiPolicyName: contains(deployment, 'raiPolicyName') ? deployment.?raiPolicyName : null
  }
  sku: {
    name: 'Standard'
    capacity: deployment.capacity
  }
}]

output endpoint string = account.properties.endpoint
output id string = account.id
output name string = account.name
