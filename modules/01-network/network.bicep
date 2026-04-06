targetScope = 'resourceGroup'

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'
import {
  lockType
  diagnosticSettingFullType
  roleAssignmentType
} from '../shared/avm-common-types.bicep'

@description('Required. Abbreviation for the owning system.')
param systemAbbreviation string

@description('Required. Abbreviation for the lifecycle environment.')
param environmentAbbreviation string

@description('Required. Instance number used for deterministic naming.')
param instanceNumber string

@description('Optional. Workload descriptor to include in names when it adds value. When empty, the segment is omitted.')
param workloadDescription string = ''

@description('Optional. Location for all resources.')
param location string = resourceGroup().location


@description('Optional, default is false. Set to true if you want to deploy ASE v3 instead of Multitenant App Service Plan.')
param deployAseV3 bool

@description('Optional. Controls whether the private endpoint subnet is deployed.')
param deployPrivateNetworking bool

@description('Required. CIDR of the SPOKE vnet i.e. 192.168.0.0/24.')
param vnetSpokeAddressSpace string

@description('Required. CIDR of the subnet that will hold the app services plan.')
param subnetSpokeAppSvcAddressSpace string

@description('Conditional. CIDR of the subnet that will hold the private endpoints of the supporting services. Used only when deployPrivateNetworking is true.')
param subnetSpokePrivateEndpointAddressSpace string

@description('Optional. CIDR of the subnet that will hold the Application Gateway. Required if networkingOption is "applicationGateway".')
param subnetSpokeAppGwAddressSpace string

@description('Optional. Internal IP of the Azure firewall deployed in Hub. Used for creating UDR to route all vnet egress traffic through Firewall. If empty no UDR.')
param firewallInternalIp string

@description('Optional. Resource tags that we might need to add to all resources (i.e. Environment, Cost center, application name etc).')
param tags object

@description('Required. Create (or not) a UDR for the App Service Subnet, to route all egress traffic through Hub Azure Firewall.')
param enableEgressLockdown bool

@description('Optional. The networking option to use. Options: frontDoor, applicationGateway, none.')
@allowed(['frontDoor', 'applicationGateway', 'none'])
param networkingOption string

@description('Required. The resource ID of the Log Analytics workspace for diagnostic settings.')
param logAnalyticsWorkspaceId string

@description('Optional. The resource ID of the hub VNet. If not empty, VNet peering will be configured.')
param hubVnetResourceId string

@description('Optional. Allow forwarded traffic on the spoke-to-hub peering.')
param hubPeeringAllowForwardedTraffic bool

@description('Optional. Allow gateway transit on the spoke-to-hub peering.')
param hubPeeringAllowGatewayTransit bool

@description('Optional. Allow virtual network access on the spoke-to-hub peering.')
param hubPeeringAllowVirtualNetworkAccess bool

@description('Optional. Do not verify remote gateways on the spoke-to-hub peering.')
param hubPeeringDoNotVerifyRemoteGateways bool

@description('Optional. Use remote gateways on the spoke-to-hub peering.')
param hubPeeringUseRemoteGateways bool

@description('Optional. Create the reverse hub-to-spoke peering as well.')
param hubRemotePeeringEnabled bool

@description('Optional. Allow forwarded traffic on the hub-to-spoke peering.')
param hubRemotePeeringAllowForwardedTraffic bool

@description('Optional. Allow gateway transit on the hub-to-spoke peering.')
param hubRemotePeeringAllowGatewayTransit bool

@description('Optional. Allow virtual network access on the hub-to-spoke peering.')
param hubRemotePeeringAllowVirtualNetworkAccess bool

@description('Optional. Do not verify remote gateways on the hub-to-spoke peering.')
param hubRemotePeeringDoNotVerifyRemoteGateways bool

@description('Optional. Use remote gateways on the hub-to-spoke peering.')
param hubRemotePeeringUseRemoteGateways bool

@description('Optional. Custom DNS servers for the spoke VNet. If empty, Azure-provided DNS is used.')
param dnsServers string[]?

@description('Optional. The resource ID of a DDoS Protection Plan to associate with the spoke VNet.')
param ddosProtectionPlanResourceId string

@description('Optional. Diagnostic Settings for the spoke virtual network.')
param vnetDiagnosticSettings diagnosticSettingFullType[]?

@description('Optional. Specify the type of resource lock for the spoke virtual network.')
param vnetLock lockType?

@description('Optional. Whether to disable BGP route propagation on the route table. Defaults to true to prevent BGP-learned routes from bypassing the firewall.')
param disableBgpRoutePropagation bool

@description('Optional. Role assignments for the spoke virtual network.')
param vnetRoleAssignments roleAssignmentType[]?

@description('Optional. Enable VNet encryption.')
param vnetEncryption bool

@description('Optional. VNet encryption enforcement. Only used when vnetEncryption is true.')
@allowed(['AllowUnencrypted', 'DropUnencrypted'])
param vnetEncryptionEnforcement string

@description('Optional. The flow timeout in minutes for the VNet (max 30). 0 means disabled.')
param flowTimeoutInMinutes int

@description('Optional. Enable VM protection for the VNet.')
param enableVmProtection bool?

@description('Optional. Enables high scale private endpoints for the virtual network.')
@allowed(['Basic', 'Disabled'])
param enablePrivateEndpointVNetPolicies string

@description('Optional. The BGP community for the VNet.')
param virtualNetworkBgpCommunity string?

var deployAppGw = networkingOption == 'applicationGateway'

var regionAbbreviation = regionAbbreviations[?location] ?? location
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var sharedNamePrefix = '${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}'
var sharedNameSuffix = '${workloadSegment}-${instanceNumber}'
var spokeVnetName = take('vnet-${sharedNamePrefix}${sharedNameSuffix}', 80)
var appServiceSubnetName = take('snet-${sharedNamePrefix}-appservice-${instanceNumber}', 80)
var privateEndpointSubnetName = take('snet-${sharedNamePrefix}-privateendpoint-${instanceNumber}', 80)
var appGatewaySubnetName = take('snet-${sharedNamePrefix}-appgateway-${instanceNumber}', 80)
var privateEndpointNsgName = take('nsg-${sharedNamePrefix}-privateendpoint-${instanceNumber}', 80)
var aseNsgName = take('nsg-${sharedNamePrefix}-ase-${instanceNumber}', 80)
var appGatewayNsgName = take('nsg-${sharedNamePrefix}-appgateway-${instanceNumber}', 80)
var routeTableName = take('rt-${sharedNamePrefix}${sharedNameSuffix}', 80)
var egressLockdownRouteName = take('route-${sharedNamePrefix}-egresslockdown-${instanceNumber}', 80)

var resourceNames = {
  vnetSpoke: spokeVnetName
  snetAppSvc: appServiceSubnetName
  snetDevOps: take('snet-${sharedNamePrefix}-devops-${instanceNumber}', 80)
  snetPe: privateEndpointSubnetName
  snetAppGw: appGatewaySubnetName
  pepNsg: privateEndpointNsgName
  aseNsg: aseNsgName
  appGwNsg: appGatewayNsgName
  routeTable: routeTableName
  routeEgressLockdown: egressLockdownRouteName
}

var udrRoutes = [
  {
    name: 'defaultEgressLockdown'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopIpAddress: firewallInternalIp
      nextHopType: 'VirtualAppliance'
    }
  }
]

var appServiceSubnetDelegation = deployAseV3 ? 'Microsoft.Web/hostingEnvironments' : 'Microsoft.Web/serverfarms'
var appServiceSubnetPrivateEndpointPolicies = deployAseV3 ? 'Disabled' : 'Enabled'
var appServiceSubnetNetworkSecurityGroupResourceId = deployAseV3
  ? (nsgAse.?outputs.?resourceId ?? '')
  : nsgPep.outputs.resourceId
var appServiceSubnet = {
  name: resourceNames.snetAppSvc
  addressPrefix: subnetSpokeAppSvcAddressSpace
  privateEndpointNetworkPolicies: appServiceSubnetPrivateEndpointPolicies
  delegation: appServiceSubnetDelegation
  networkSecurityGroupResourceId: appServiceSubnetNetworkSecurityGroupResourceId
  routeTableResourceId: routeTableToFirewall.?outputs.?resourceId
}

var shouldCreatePrivateEndpointSubnet = deployPrivateNetworking
var privateEndpointSubnet = {
  name: resourceNames.snetPe
  addressPrefix: subnetSpokePrivateEndpointAddressSpace
  privateEndpointNetworkPolicies: 'Disabled'
  networkSecurityGroupResourceId: nsgPep.outputs.resourceId
}

var shouldCreateAppGatewaySubnet = deployAppGw && !empty(subnetSpokeAppGwAddressSpace)
var appGatewaySubnet = {
  name: resourceNames.snetAppGw
  addressPrefix: subnetSpokeAppGwAddressSpace
  networkSecurityGroupResourceId: nsgAppGw.?outputs.?resourceId ?? ''
}

var baseSubnets = [
  appServiceSubnet
]
var privateEndpointSubnets = shouldCreatePrivateEndpointSubnet ? [privateEndpointSubnet] : []
var appGatewaySubnets = shouldCreateAppGatewaySubnet ? [appGatewaySubnet] : []
var subnets = concat(baseSubnets, privateEndpointSubnets, appGatewaySubnets)

var shouldCreateHubPeering = !empty(hubVnetResourceId)
var hubPeering = {
  remoteVirtualNetworkResourceId: hubVnetResourceId
  allowVirtualNetworkAccess: hubPeeringAllowVirtualNetworkAccess
  allowForwardedTraffic: hubPeeringAllowForwardedTraffic
  allowGatewayTransit: hubPeeringAllowGatewayTransit
  doNotVerifyRemoteGateways: hubPeeringDoNotVerifyRemoteGateways
  useRemoteGateways: hubPeeringUseRemoteGateways
  remotePeeringEnabled: hubRemotePeeringEnabled
  remotePeeringAllowForwardedTraffic: hubRemotePeeringAllowForwardedTraffic
  remotePeeringAllowGatewayTransit: hubRemotePeeringAllowGatewayTransit
  remotePeeringAllowVirtualNetworkAccess: hubRemotePeeringAllowVirtualNetworkAccess
  remotePeeringDoNotVerifyRemoteGateways: hubRemotePeeringDoNotVerifyRemoteGateways
  remotePeeringUseRemoteGateways: hubRemotePeeringUseRemoteGateways
}

module vnetSpoke './virtual-network.bicep' = {
  name: '${uniqueString(deployment().name, location)}-spokevnet'
  params: {
    name: resourceNames.vnetSpoke
    location: location
    tags: tags
    addressPrefixes: [
      vnetSpokeAddressSpace
    ]
    dnsServers: dnsServers
    ddosProtectionPlanResourceId: ddosProtectionPlanResourceId
    diagnosticSettings: vnetDiagnosticSettings
    lock: vnetLock
    roleAssignments: vnetRoleAssignments
    vnetEncryption: vnetEncryption
    vnetEncryptionEnforcement: vnetEncryption ? vnetEncryptionEnforcement : 'AllowUnencrypted'
    flowTimeoutInMinutes: flowTimeoutInMinutes
    enableVmProtection: enableVmProtection
    enablePrivateEndpointVNetPolicies: enablePrivateEndpointVNetPolicies
    virtualNetworkBgpCommunity: virtualNetworkBgpCommunity
    subnets: subnets
    peerings: shouldCreateHubPeering ? [hubPeering] : []
  }
}

module routeTableToFirewall './route-table.bicep' = if (!empty(firewallInternalIp) && (enableEgressLockdown)) {
  name: '${uniqueString(deployment().name, location)}-rt'
  params: {
    name: resourceNames.routeTable
    location: location
    tags: tags
    routes: udrRoutes
    disableBgpRoutePropagation: disableBgpRoutePropagation
  }
}

@description('NSG for the private endpoint subnet.')
module nsgPep './network-security-group.bicep' = {
  name: '${uniqueString(deployment().name, location)}-nsgpep'
  params: {
    name: resourceNames.pepNsg
    location: location
    tags: tags
    securityRules: [
      {
        name: 'deny-hop-outbound'
        properties: {
          priority: 200
          access: 'Deny'
          protocol: '*'
          direction: 'Outbound'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '3389'
            '22'
          ]
        }
      }
    ]
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceId
      }
    ]
  }
}

@description('NSG for ASE subnet')
module nsgAse './network-security-group.bicep' = if (deployAseV3) {
  name: '${uniqueString(deployment().name, location)}-nsgase'
  params: {
    name: resourceNames.aseNsg
    location: location
    tags: tags
    securityRules: [
      {
        name: 'SSL_WEB_443'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          priority: 100
        }
      }
    ]
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceId
      }
    ]
  }
}

@description('NSG for Application Gateway subnet')
module nsgAppGw './network-security-group.bicep' = if (deployAppGw) {
  name: '${uniqueString(deployment().name, location)}-nsgappgw'
  params: {
    name: resourceNames.appGwNsg
    location: location
    tags: tags
    securityRules: [
      {
        name: 'AllowGatewayManager'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
          priority: 100
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          priority: 110
        }
      }
      {
        name: 'AllowHTTP'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
          priority: 120
        }
      }
      {
        name: 'AllowAzureLoadBalancer'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          priority: 130
        }
      }
    ]
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceId
      }
    ]
  }
}

@description('The resource ID of the spoke virtual network.')
output vnetSpokeResourceId string = vnetSpoke.outputs.resourceId

@description('The name of the spoke virtual network.')
output vnetSpokeName string = vnetSpoke.outputs.name

@description('The resource ID of the App Service subnet.')
output snetAppSvcResourceId string = vnetSpoke.outputs.subnetResourceIds[0]

@description('The resource ID of the private endpoint subnet.')
output snetPeResourceId string = deployPrivateNetworking ? vnetSpoke.outputs.subnetResourceIds[1] : ''

@description('The name of the private endpoint subnet.')
output snetPeName string = deployPrivateNetworking ? vnetSpoke.outputs.subnetNames[1] : ''

@description('The resource ID of the Application Gateway subnet. Empty if not deployed.')
output snetAppGwResourceId string = deployAppGw && !empty(subnetSpokeAppGwAddressSpace) ? vnetSpoke.outputs.subnetResourceIds[deployPrivateNetworking ? 2 : 1] : ''

@description('The name of the Application Gateway subnet. Empty if not deployed.')
output snetAppGwName string = deployAppGw && !empty(subnetSpokeAppGwAddressSpace) ? vnetSpoke.outputs.subnetNames[deployPrivateNetworking ? 2 : 1] : ''
