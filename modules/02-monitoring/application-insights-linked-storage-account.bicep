metadata name = 'Application Insights Linked Storage Account'
metadata description = 'This component deploys an Application Insights Linked Storage Account.'

@description('Conditional. The name of the parent Application Insights instance. Required if the template is used in a standalone deployment.')
param appInsightsName string

@description('Required. Linked storage account resource ID.')
param storageAccountResourceId string

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource linkedStorageAccount 'Microsoft.Insights/components/linkedStorageAccounts@2020-03-01-preview' = {
  name: 'ServiceProfiler'
  parent: appInsights
  properties: {
    linkedStorageAccount: storageAccountResourceId
  }
}

output name string = linkedStorageAccount.name

output resourceId string = linkedStorageAccount.id

output resourceGroupName string = resourceGroup().name
