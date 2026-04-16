metadata name = 'Private DNS Zone Virtual Network Link'
metadata description = 'This module deploys a Private DNS Zone Virtual Network Link.'
param privateDnsZoneName string
param name string
param tags resourceInput<'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01'>.tags?
param registrationEnabled bool
param virtualNetworkResourceId string
param resolutionPolicy string?

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: privateDnsZoneName
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: name
  parent: privateDnsZone
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: registrationEnabled
    virtualNetwork: {
      id: virtualNetworkResourceId
    }
    resolutionPolicy: resolutionPolicy
  }
}
output name string = virtualNetworkLink.name
output resourceId string = virtualNetworkLink.id
output resourceGroupName string = resourceGroup().name
output location string = virtualNetworkLink.location
