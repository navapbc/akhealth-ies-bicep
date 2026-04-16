metadata name = 'Site Deployment Extension '
metadata description = 'This module deploys a Site extension for MSDeploy.'
param appName string
param slotName string
@allowed([
  'MSDeploy'
])
param name string = 'MSDeploy'
@allowed([
  'MSDeploy'
])
param kind string = 'MSDeploy'
param properties resourceInput<'Microsoft.Web/sites/slots/extensions@2025-03-01'>.properties?

resource app 'Microsoft.Web/sites@2025-03-01' existing = {
  name: appName

  resource slot 'slots' existing = {
    name: slotName
  }
}
resource msdeploy 'Microsoft.Web/sites/slots/extensions@2025-03-01' = {
  name: name
  kind: kind
  parent: app::slot
  properties: properties
}
output name string = msdeploy.name
output resourceId string = msdeploy.id
output resourceGroupName string = resourceGroup().name
