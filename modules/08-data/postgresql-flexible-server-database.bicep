metadata name = 'DBforPostgreSQL Flexible Server Databases'
metadata description = 'This module deploys a DBforPostgreSQL Flexible Server Database.'
param name string
param flexibleServerName string
param collation string?
param charset string?

resource flexibleServer 'Microsoft.DBforPostgreSQL/flexibleServers@2025-08-01' existing = {
  name: flexibleServerName
}

resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2025-08-01' = {
  name: name
  parent: flexibleServer
  properties: {
    collation: collation
    charset: charset
  }
}
output name string = database.name
output resourceId string = database.id
output resourceGroupName string = resourceGroup().name
