metadata name = 'DBforPostgreSQL Flexible Server Configurations'
metadata description = 'This module deploys a DBforPostgreSQL Flexible Server Configuration.'
param name string
param flexibleServerName string
param source string?
param value string?

resource flexibleServer 'Microsoft.DBforPostgreSQL/flexibleServers@2025-08-01' existing = {
  name: flexibleServerName
}

resource configuration 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2025-08-01' = {
  name: name
  parent: flexibleServer
  properties: {
    source: source
    value: value
  }
}
output name string = configuration.name
output resourceId string = configuration.id
output resourceGroupName string = resourceGroup().name
