targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default naming conventions and tags
param resourceGroupName string = ''
param tags object = {}

// AI Parameters
param openAiServiceName string = ''
param contentSafetyServiceName string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
// Use a specific name if provided, otherwise generate one
var rgName = !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'

// Deploy Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
  tags: tags
}

module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    name: '${abbrs.logAnalyticsWorkspace}${resourceToken}'
  }
}

module registry './core/host/acr.bicep' = {
  name: 'registry'
  scope: rg
  params: {
    location: location
    tags: tags
    name: '${abbrs.containerRegistry}${resourceToken}'
    adminUserEnabled: false
  }
}

module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appServicePlan'
  scope: rg
  params: {
    location: location
    tags: tags
    name: '${abbrs.appServicePlan}${resourceToken}'
    sku: {
      name: 'B1'
      tier: 'Basic'
    }
  }
}

module web './core/host/appservice.bicep' = {
  name: 'web'
  scope: rg
  params: {
    location: location
    tags: union(tags, { 'azd-service-name': 'web' })
    name: '${abbrs.appService}${resourceToken}'
    appServicePlanId: appServicePlan.outputs.id
    containerRegistryName: registry.outputs.name
    appSettings: {
      AZURE_CONTAINER_REGISTRY_ENDPOINT: registry.outputs.loginServer
      APPLICATIONINSIGHTS_CONNECTION_STRING: monitoring.outputs.applicationInsightsConnectionString
      AZURE_OPENAI_ENDPOINT: openAi.outputs.endpoint
      AZURE_CONTENT_SAFETY_ENDPOINT: contentSafety.outputs.endpoint
    }
  }
}

module openAi './core/ai/foundry.bicep' = {
  name: 'openai'
  scope: rg
  params: {
    location: location
    tags: tags
    name: !empty(openAiServiceName) ? openAiServiceName : '${abbrs.openAi}${resourceToken}'
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    deployments: [
      {
        name: 'gpt-4o'
        model: {
          format: 'OpenAI'
          name: 'gpt-4o'
          version: '2024-05-13'
        }
        capacity: 10
      }
    ]
  }
}

module contentSafety './core/ai/contentsafety.bicep' = {
  name: 'contentsafety'
  scope: rg
  params: {
    location: location
    tags: tags
    name: !empty(contentSafetyServiceName) ? contentSafetyServiceName : 'cs${resourceToken}'
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// RBAC: Grant App Service Identity Pull access to ACR
module acrPullRole 'core/security/role.bicep' = {
  name: 'acr-pull-role'
  scope: rg
  params: {
    principalId: web.outputs.identityPrincipalId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
    principalType: 'ServicePrincipal'
  }
}

// RBAC: Grant App Service Identity User access to OpenAI
module openAiRole 'core/security/role.bicep' = {
  name: 'openai-role'
  scope: rg
  params: {
    principalId: web.outputs.identityPrincipalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd' // Cognitive Services OpenAI User
    principalType: 'ServicePrincipal'
  }
}

// RBAC: Grant App Service Identity User access to Content Safety
module contentSafetyRole 'core/security/role.bicep' = {
  name: 'contentsafety-role'
  scope: rg
  params: {
    principalId: web.outputs.identityPrincipalId
    roleDefinitionId: 'a001fd3d-188f-4b5d-821b-7da978bf7442' // Cognitive Services User
    principalType: 'ServicePrincipal'
  }
}

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = registry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = registry.outputs.name
output AZURE_WEB_APP_ENDPOINT string = 'https://${web.outputs.defaultHostName}'
output AZURE_WEB_APP_NAME string = web.outputs.name
output AZURE_OPENAI_ENDPOINT string = openAi.outputs.endpoint
output AZURE_CONTENT_SAFETY_ENDPOINT string = contentSafety.outputs.endpoint
