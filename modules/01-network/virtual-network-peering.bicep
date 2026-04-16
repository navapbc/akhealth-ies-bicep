metadata name = 'Virtual Network Peerings'
metadata description = 'This module deploys a Virtual Network Peering.'
param name string
param localVnetName string
param remoteVirtualNetworkResourceId string
param allowForwardedTraffic bool = true
param allowGatewayTransit bool = false
param allowVirtualNetworkAccess bool = true
param doNotVerifyRemoteGateways bool = true
param useRemoteGateways bool = false

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2025-05-01' existing = {
  name: localVnetName
}

resource virtualNetworkPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-05-01' = {
  name: name
  parent: virtualNetwork
  properties: {
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    doNotVerifyRemoteGateways: doNotVerifyRemoteGateways
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: remoteVirtualNetworkResourceId
    }
  }
}
output resourceGroupName string = resourceGroup().name
output name string = virtualNetworkPeering.name
output resourceId string = virtualNetworkPeering.id
