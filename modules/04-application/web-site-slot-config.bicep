metadata name = 'Site App Settings'
metadata description = 'This module deploys a Site App Setting.'

@description('Conditional. The name of the parent site resource. Required if the template is used in a standalone deployment.')
param appName string

@description('Conditional. The name of the parent web site slot. Required if the template is used in a standalone deployment.')
param slotName string

@description('Required. The name of the config.')
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

@description('Optional. The properties of the config. Note: This parameter is highly dependent on the config type, defined by its name.')
param properties object = {}

@description('Optional. Storage account resource reference used to derive function host storage app settings.')
param functionHostStorageAccount {
  @description('Required. Name of the storage account.')
  name: string

  @description('Required. Resource group name of the storage account.')
  resourceGroupName: string
}?

@description('Optional. Application Insights component reference used to derive the application insights connection string app setting.')
param applicationInsightsComponent {
  @description('Required. Name of the Application Insights component.')
  name: string

  @description('Required. Resource group name of the Application Insights component.')
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

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' existing = if (hasStorageAccount) {
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

@description('The name of the site config.')
output name string = config.name

@description('The resource ID of the site config.')
output resourceId string = config.id

@description('The resource group the site config was deployed into.')
output resourceGroupName string = resourceGroup().name
