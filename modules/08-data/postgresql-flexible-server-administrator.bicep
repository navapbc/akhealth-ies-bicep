metadata name = 'DBforPostgreSQL Flexible Server Administrators'
metadata description = 'This module deploys a DBforPostgreSQL Flexible Server Administrator.'
param flexibleServerName string
param objectId string
param principalName string
@allowed([
  'Group'
  'ServicePrincipal'
  'Unknown'
  'User'
])
param principalType string
param tenantId string

resource flexibleServer 'Microsoft.DBforPostgreSQL/flexibleServers@2025-08-01' existing = {
  name: flexibleServerName
}

resource administrator 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2025-08-01' = {
  name: objectId
  parent: flexibleServer
  properties: {
    principalName: principalName
    principalType: principalType
    tenantId: tenantId
  }
}
output name string = administrator.name
output resourceId string = administrator.id
output resourceGroupName string = resourceGroup().name
