param workbookName string
param location string = resourceGroup().location
param logAnalyticsWorkspaceId string
param openAiAccountName string
param contentSafetyAccountName string
param tags object = {}

resource workbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: guid(workbookName)
  location: location
  tags: tags
  kind: 'shared'
  properties: {
    displayName: workbookName
    serializedData: string(loadJsonContent('./workbook-template.json'))
    version: '1.0'
    sourceId: logAnalyticsWorkspaceId
    category: 'AI'
  }
}

output workbookId string = workbook.id
output workbookName string = workbook.name
