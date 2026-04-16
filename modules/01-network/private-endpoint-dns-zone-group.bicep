metadata name = 'Private Endpoint Private DNS Zone Groups'
metadata description = 'This module deploys a Private Endpoint Private DNS Zone Group.'
param privateEndpointName string
@minLength(1)
@maxLength(5)
param privateDnsZoneConfigs privateDnsZoneGroupConfigType[]
param name string = 'default'

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2025-05-01' existing = {
  name: privateEndpointName
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2025-05-01' = {
  name: name
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      for privateDnsZoneConfig in privateDnsZoneConfigs: {
        name: privateDnsZoneConfig.name
        properties: {
          privateDnsZoneId: privateDnsZoneConfig.privateDnsZoneResourceId
        }
      }
    ]
  }
}
output name string = privateDnsZoneGroup.name
output resourceId string = privateDnsZoneGroup.id
output resourceGroupName string = resourceGroup().name

// ================ //
// Definitions      //
// ================ //

@export()
type privateDnsZoneGroupConfigType = {
  name: string
  privateDnsZoneResourceId: string
}
