targetScope = 'resourceGroup'

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'
import {
  lockType
  diagnosticSettingFullType
  roleAssignmentType
} from '../shared/avm-common-types.bicep'

param systemAbbreviation string
param environmentAbbreviation string
param instanceNumber string
param workloadDescription string = ''
param location string = resourceGroup().location
param deployAseV3 bool
param deployPrivateNetworking bool
param vnetSpokeAddressSpace string
param subnetSpokeAppSvcAddressSpace string
param subnetSpokePrivateEndpointAddressSpace string
param applicationGatewayConfig {
  subnetAddressSpace: string
}?
param postgreSqlPrivateAccessConfig {
  subnetAddressSpace: string
}?
param egressFirewallConfig {
  internalIp: string
}?
param tags object
param enableEgressLockdown bool
@allowed(['frontDoor', 'applicationGateway', 'none'])
param networkingOption string
param deployPostgreSqlPrivateAccess bool = false
param logAnalyticsWorkspaceId string
param hubPeeringConfig {
  virtualNetworkResourceId: string
  virtualNetworkName: string
  resourceGroupName: string
  subscriptionId: string
  allowForwardedTraffic: bool
  allowGatewayTransit: bool
  allowVirtualNetworkAccess: bool
  doNotVerifyRemoteGateways: bool
  useRemoteGateways: bool
  reversePeeringConfig: {
    allowForwardedTraffic: bool
    allowGatewayTransit: bool
    allowVirtualNetworkAccess: bool
    doNotVerifyRemoteGateways: bool
    useRemoteGateways: bool
  }?
}?
param dnsServers string[]?
param ddosProtectionPlanResourceId string?
param vnetDiagnosticSettings diagnosticSettingFullType[]?
param vnetLock lockType?
param disableBgpRoutePropagation bool
param vnetRoleAssignments roleAssignmentType[]?
param vnetEncryption bool
@allowed(['AllowUnencrypted', 'DropUnencrypted'])
param vnetEncryptionEnforcement string
param flowTimeoutInMinutes int
param enableVmProtection bool?
@allowed(['Basic', 'Disabled'])
param enablePrivateEndpointVNetPolicies string
param virtualNetworkBgpCommunity string?
var deployAppGw = networkingOption == 'applicationGateway'
var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var sharedNamePrefix = '${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}'
var sharedNameSuffix = '${workloadSegment}-${instanceNumber}'
var spokeVnetName = take('vnet-${sharedNamePrefix}${sharedNameSuffix}', 80)
var appServiceSubnetName = take('snet-${sharedNamePrefix}-appservice-${instanceNumber}', 80)
var privateEndpointSubnetName = take('snet-${sharedNamePrefix}-privateendpoint-${instanceNumber}', 80)
var postgreSqlSubnetName = take('snet-${sharedNamePrefix}-postgresql-${instanceNumber}', 80)
var appGatewaySubnetName = take('snet-${sharedNamePrefix}-appgateway-${instanceNumber}', 80)
var appServiceNsgName = take('nsg-${sharedNamePrefix}-appservice-${instanceNumber}', 80)
var privateEndpointNsgName = take('nsg-${sharedNamePrefix}-privateendpoint-${instanceNumber}', 80)
var postgreSqlNsgName = take('nsg-${sharedNamePrefix}-postgresql-${instanceNumber}', 80)
var aseNsgName = take('nsg-${sharedNamePrefix}-ase-${instanceNumber}', 80)
var appGatewayNsgName = take('nsg-${sharedNamePrefix}-appgateway-${instanceNumber}', 80)
var routeTableName = take('rt-${sharedNamePrefix}${sharedNameSuffix}', 80)
var egressLockdownRouteName = take('route-${sharedNamePrefix}-egresslockdown-${instanceNumber}', 80)
var resourceNames = {
  vnetSpoke: spokeVnetName
  snetAppSvc: appServiceSubnetName
  snetPe: privateEndpointSubnetName
  snetPostgreSql: postgreSqlSubnetName
  snetAppGw: appGatewaySubnetName
  appSvcNsg: appServiceNsgName
  pepNsg: privateEndpointNsgName
  postgreSqlNsg: postgreSqlNsgName
  aseNsg: aseNsgName
  appGwNsg: appGatewayNsgName
  routeTable: routeTableName
  routeEgressLockdown: egressLockdownRouteName
}
var applicationGatewayConfigIsValid = networkingOption != 'applicationGateway' || applicationGatewayConfig != null
  ? true
  : fail('When networkingOption is "applicationGateway", applicationGatewayConfig must be provided.')
var postgreSqlPrivateAccessConfigIsValid = !deployPostgreSqlPrivateAccess || postgreSqlPrivateAccessConfig != null
  ? true
  : fail('When deployPostgreSqlPrivateAccess is true, postgreSqlPrivateAccessConfig must be provided.')
var egressFirewallConfigIsValid = !enableEgressLockdown || egressFirewallConfig != null
  ? true
  : fail('When enableEgressLockdown is true, egressFirewallConfig must be provided.')

var subnetSpokePostgreSqlAddressSpace = postgreSqlPrivateAccessConfigIsValid ? postgreSqlPrivateAccessConfig.?subnetAddressSpace : null
var subnetSpokeAppGwAddressSpace = applicationGatewayConfigIsValid ? applicationGatewayConfig.?subnetAddressSpace : null
var firewallInternalIp = egressFirewallConfigIsValid ? egressFirewallConfig.?internalIp : null
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
var spokeToHubPeeringName = take('peer-${sharedNamePrefix}-hub-${instanceNumber}', 80)
var hubToSpokePeeringName = take('peer-${sharedNamePrefix}-spoke-${instanceNumber}', 80)
var appServiceSubnetDelegation = deployAseV3 ? 'Microsoft.Web/hostingEnvironments' : 'Microsoft.Web/serverfarms'
var appServiceSubnetPrivateEndpointPolicies = deployAseV3 ? 'Disabled' : 'Enabled'
var appServiceSubnetNetworkSecurityGroupResourceId = deployAseV3
  ? nsgAse!.outputs.resourceId
  : nsgAppSvc!.outputs.resourceId
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
  networkSecurityGroupResourceId: nsgPep!.outputs.resourceId
}
var shouldCreatePostgreSqlSubnet = deployPostgreSqlPrivateAccess
var postgreSqlSubnet = {
  name: resourceNames.snetPostgreSql
  addressPrefix: subnetSpokePostgreSqlAddressSpace
  delegation: 'Microsoft.DBforPostgreSQL/flexibleServers'
  networkSecurityGroupResourceId: nsgPostgreSql!.outputs.resourceId
}
var shouldCreateAppGatewaySubnet = deployAppGw && !empty(subnetSpokeAppGwAddressSpace)
var appGatewaySubnet = {
  name: resourceNames.snetAppGw
  addressPrefix: subnetSpokeAppGwAddressSpace
  networkSecurityGroupResourceId: nsgAppGw!.outputs.resourceId
}
var baseSubnets = [
  appServiceSubnet
]
var privateEndpointSubnets = shouldCreatePrivateEndpointSubnet ? [privateEndpointSubnet] : []
var postgreSqlSubnets = shouldCreatePostgreSqlSubnet ? [postgreSqlSubnet] : []
var appGatewaySubnets = shouldCreateAppGatewaySubnet ? [appGatewaySubnet] : []
var subnets = concat(baseSubnets, privateEndpointSubnets, postgreSqlSubnets, appGatewaySubnets)
var postgreSqlSubnetIndex = 1 + (shouldCreatePrivateEndpointSubnet ? 1 : 0)
var appGatewaySubnetIndex = 1 + (shouldCreatePrivateEndpointSubnet ? 1 : 0) + (shouldCreatePostgreSqlSubnet ? 1 : 0)
var shouldCreateHubPeering = hubPeeringConfig != null
var reverseHubPeeringConfig = hubPeeringConfig.?reversePeeringConfig
var hubPeering = shouldCreateHubPeering
  ? {
      name: spokeToHubPeeringName
      remoteVirtualNetworkResourceId: hubPeeringConfig!.virtualNetworkResourceId
      remoteVirtualNetworkName: hubPeeringConfig!.virtualNetworkName
      remoteVirtualNetworkResourceGroupName: hubPeeringConfig!.resourceGroupName
      remoteVirtualNetworkSubscriptionId: hubPeeringConfig!.subscriptionId
      allowVirtualNetworkAccess: hubPeeringConfig!.allowVirtualNetworkAccess
      allowForwardedTraffic: hubPeeringConfig!.allowForwardedTraffic
      allowGatewayTransit: hubPeeringConfig!.allowGatewayTransit
      doNotVerifyRemoteGateways: hubPeeringConfig!.doNotVerifyRemoteGateways
      useRemoteGateways: hubPeeringConfig!.useRemoteGateways
      remotePeeringEnabled: reverseHubPeeringConfig != null
      remotePeeringName: hubToSpokePeeringName
      remotePeeringAllowForwardedTraffic: reverseHubPeeringConfig.?allowForwardedTraffic
      remotePeeringAllowGatewayTransit: reverseHubPeeringConfig.?allowGatewayTransit
      remotePeeringAllowVirtualNetworkAccess: reverseHubPeeringConfig.?allowVirtualNetworkAccess
      remotePeeringDoNotVerifyRemoteGateways: reverseHubPeeringConfig.?doNotVerifyRemoteGateways
      remotePeeringUseRemoteGateways: reverseHubPeeringConfig.?useRemoteGateways
    }
  : null

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
    peerings: shouldCreateHubPeering ? [hubPeering!] : []
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

module nsgAppSvc './network-security-group.bicep' = if (!deployAseV3) {
  name: '${uniqueString(deployment().name, location)}-nsgappsvc'
  params: {
    name: resourceNames.appSvcNsg
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

module nsgPep './network-security-group.bicep' = if (shouldCreatePrivateEndpointSubnet) {
  name: '${uniqueString(deployment().name, location)}-nsgpep'
  params: {
    name: resourceNames.pepNsg
    location: location
    tags: tags
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceId
      }
    ]
  }
}

module nsgPostgreSql './network-security-group.bicep' = if (shouldCreatePostgreSqlSubnet) {
  name: '${uniqueString(deployment().name, location)}-nsgpostgresql'
  params: {
    name: resourceNames.postgreSqlNsg
    location: location
    tags: tags
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceId
      }
    ]
  }
}

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
output vnetSpokeResourceId string = vnetSpoke.outputs.resourceId
output vnetSpokeName string = vnetSpoke.outputs.name
output snetAppSvcResourceId string = vnetSpoke.outputs.subnetResourceIds[0]
output snetAppSvcName string = vnetSpoke.outputs.subnetNames[0]
output snetPeResourceId string? = deployPrivateNetworking ? vnetSpoke.outputs.subnetResourceIds[1] : null
output snetPeName string? = deployPrivateNetworking ? vnetSpoke.outputs.subnetNames[1] : null
output snetPostgreSqlResourceId string? = deployPostgreSqlPrivateAccess ? vnetSpoke.outputs.subnetResourceIds[postgreSqlSubnetIndex] : null
output snetPostgreSqlName string? = deployPostgreSqlPrivateAccess ? vnetSpoke.outputs.subnetNames[postgreSqlSubnetIndex] : null
output snetAppGwResourceId string? = deployAppGw && !empty(subnetSpokeAppGwAddressSpace) ? vnetSpoke.outputs.subnetResourceIds[appGatewaySubnetIndex] : null
output snetAppGwName string? = deployAppGw && !empty(subnetSpokeAppGwAddressSpace) ? vnetSpoke.outputs.subnetNames[appGatewaySubnetIndex] : null
