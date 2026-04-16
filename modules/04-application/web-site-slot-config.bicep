metadata name = 'Site App Settings'
metadata description = 'This module deploys a Site App Setting.'
param appName string
param slotName string
@allowed([
  'appsettings'
  'authsettings'
  'authsettingsV2'
  'azurestorageaccounts'
  'backup'
  'connectionstrings'
  'logs'
  'metadata'
  'pushsettings'
  'web'
])
param name string
param properties object = {}
param functionHostStorageAccount {
  name: string
  resourceGroupName: string
}?
param applicationInsightsComponent {
  name: string
  resourceGroupName: string
}?
var storageAccountReference = functionHostStorageAccount
var applicationInsightsReference = applicationInsightsComponent
var hasStorageAccount = storageAccountReference != null
var hasApplicationInsights = applicationInsightsReference != null
var azureWebJobsValues = hasStorageAccount
  ? {
      AzureWebJobsStorage__accountName: storageAccountReference!.name
      AzureWebJobsStorage__blobServiceUri: storageAccount!.properties.primaryEndpoints.blob
      AzureWebJobsStorage__queueServiceUri: storageAccount!.properties.primaryEndpoints.queue
      AzureWebJobsStorage__tableServiceUri: storageAccount!.properties.primaryEndpoints.table
      AzureWebJobsStorage__credential: 'managedidentity'
    }
  : {}

var appInsightsValues = hasApplicationInsights
  ? {
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights!.properties.ConnectionString
    }
  : {}

var expandedProperties = union(properties, azureWebJobsValues, appInsightsValues)

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if (hasApplicationInsights) {
  name: applicationInsightsReference!.name
  scope: resourceGroup(applicationInsightsReference!.resourceGroupName)
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-08-01' existing = if (hasStorageAccount) {
  name: storageAccountReference!.name
  scope: resourceGroup(storageAccountReference!.resourceGroupName)
}

resource app 'Microsoft.Web/sites@2025-03-01' existing = {
  name: appName

  resource slot 'slots' existing = {
    name: slotName
  }
}

resource config 'Microsoft.Web/sites/slots/config@2025-03-01' = {
  parent: app::slot
  #disable-next-line BCP225
  name: name
  properties: expandedProperties
}
output name string = config.name
output resourceId string = config.id
output resourceGroupName string = resourceGroup().name
