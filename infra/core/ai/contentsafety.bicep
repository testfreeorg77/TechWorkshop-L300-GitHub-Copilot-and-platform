param name string
param location string = resourceGroup().location
param tags object = {}
param logAnalyticsWorkspaceId string = ''

resource contentSafetyAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'ContentSafety'
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true // Enforce identity-only access
  }
  sku: {
    name: 'S0'
  }
}

// Enable diagnostic settings for Content Safety
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${name}-diagnostics'
  scope: contentSafetyAccount
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Audit'
        enabled: true
      }
      {
        category: 'RequestResponse'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output endpoint string = contentSafetyAccount.properties.endpoint
output id string = contentSafetyAccount.id
output name string = contentSafetyAccount.name
