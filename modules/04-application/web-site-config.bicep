metadata name = 'Site App Settings'
metadata description = 'This module deploys a Site App Setting.'

@description('Conditional. The name of the parent site resource. Required if the template is used in a standalone deployment.')
param appName string

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
  'slotConfigNames'
  'web'
])
param name string

@description('Optional. The properties of the config. Note: This parameter is highly dependent on the config type, defined by its name.')
param properties object = {}

// Parameters only relevant for the config type 'appsettings'
@description('Optional. Existing storage account reference used for function host storage.')
param storageAccountReference {
  @description('Required. Name of the storage account.')
  name: string

  @description('Required. Resource group name of the storage account.')
  resourceGroupName: string
}?

@description('Optional. Existing Application Insights reference used for monitoring settings.')
param applicationInsightsReference {
  @description('Required. Name of the Application Insights component.')
  name: string

  @description('Required. Resource group name of the Application Insights component.')
  resourceGroupName: string
}?


@description('Optional. The current app settings.')
param currentAppSettings {
  @description('Required. The key-values pairs of the current app settings.')
  *: string
} = {}

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
      ...(!contains(properties, 'ApplicationInsightsAgent_EXTENSION_VERSION')
        ? {
            ApplicationInsightsAgent_EXTENSION_VERSION: contains(
                [
                  'functionapp,linux' // function app linux os
                  'functionapp,workflowapp,linux' // logic app docker container
                  'functionapp,linux,container' // function app linux container
                  'functionapp,linux,container,azurecontainerapps' // function app linux container azure container apps
                  'app,linux' // linux web app
                  'linux,api' // linux api app
                  'app,linux,container' // linux container app
                ],
                app.kind
              )
              ? '~3'
              : '~2'
          }
        : {})
    }
  : {}

var expandedProperties = union(currentAppSettings, properties, azureWebJobsValues, appInsightsValues)

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if (hasApplicationInsights) {
  name: applicationInsightsReference!.name
  scope: resourceGroup(applicationInsightsReference!.resourceGroupName)
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-06-01' existing = if (hasStorageAccount) {
  name: storageAccountReference!.name
  scope: resourceGroup(storageAccountReference!.resourceGroupName)
}

resource app 'Microsoft.Web/sites@2025-03-01' existing = {
  name: appName
}

resource config 'Microsoft.Web/sites/config@2025-03-01' = {
  parent: app
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
