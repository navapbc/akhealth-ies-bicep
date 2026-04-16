targetScope = 'resourceGroup'

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'
import { subnetPlanItemType } from '../shared/shared.types.bicep'
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
param vnetSpokeAddressSpace string
param subnetPlan subnetPlanItemType[]
param egressFirewallConfig {
  internalIp: string
}?
param tags object
param enableEgressLockdown bool
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
var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var sharedNamePrefix = '${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}'
var sharedNameSuffix = '${workloadSegment}-${instanceNumber}'
var spokeVnetName = take('vnet-${sharedNamePrefix}${sharedNameSuffix}', 80)
var appServiceNsgName = take('nsg-${sharedNamePrefix}-appservice-${instanceNumber}', 80)
var privateEndpointNsgName = take('nsg-${sharedNamePrefix}-privateendpoint-${instanceNumber}', 80)
var postgreSqlNsgName = take('nsg-${sharedNamePrefix}-postgresql-${instanceNumber}', 80)
var aseNsgName = take('nsg-${sharedNamePrefix}-ase-${instanceNumber}', 80)
var appGatewayNsgName = take('nsg-${sharedNamePrefix}-appgateway-${instanceNumber}', 80)
var routeTableName = take('rt-${sharedNamePrefix}${sharedNameSuffix}', 80)
var egressLockdownRouteName = take('route-${sharedNamePrefix}-egresslockdown-${instanceNumber}', 80)
var resourceNames = {
  vnetSpoke: spokeVnetName
  appSvcNsg: appServiceNsgName
  pepNsg: privateEndpointNsgName
  postgreSqlNsg: postgreSqlNsgName
  aseNsg: aseNsgName
  appGwNsg: appGatewayNsgName
  routeTable: routeTableName
  routeEgressLockdown: egressLockdownRouteName
}
var createdSubnets = filter(subnetPlan, subnet => subnet.create)
var createdSubnetKeys = [for subnet in createdSubnets: subnet.key]
var createdNsgProfiles = [
  for subnet in createdSubnets: subnet.nsgProfile
]
var createdRouteProfiles = [
  for subnet in createdSubnets: subnet.routeProfile
]
var egressFirewallConfigIsValid = !contains(createdRouteProfiles, 'egressLockdown') || (enableEgressLockdown && egressFirewallConfig != null)
  ? true
  : fail('When a subnet uses routeProfile "egressLockdown", enableEgressLockdown must be true and egressFirewallConfig must be provided.')
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
var createdSubnetNames = [
  for subnet in createdSubnets: take('snet-${sharedNamePrefix}-${subnet.nameSuffix}-${instanceNumber}', 80)
]
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
    subnets: []
    peerings: shouldCreateHubPeering ? [hubPeering!] : []
  }
}

module routeTableToFirewall './route-table.bicep' = if (contains(createdRouteProfiles, 'egressLockdown') && !empty(firewallInternalIp) && enableEgressLockdown) {
  name: '${uniqueString(deployment().name, location)}-rt'
  params: {
    name: resourceNames.routeTable
    location: location
    tags: tags
    routes: udrRoutes
    disableBgpRoutePropagation: disableBgpRoutePropagation
  }
}

module nsgAppSvc './network-security-group.bicep' = if (contains(createdNsgProfiles, 'appService')) {
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

module nsgPep './network-security-group.bicep' = if (contains(createdNsgProfiles, 'privateEndpoint')) {
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

module nsgPostgreSql './network-security-group.bicep' = if (contains(createdNsgProfiles, 'postgresql')) {
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

module nsgAse './network-security-group.bicep' = if (contains(createdNsgProfiles, 'ase')) {
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

module nsgAppGw './network-security-group.bicep' = if (contains(createdNsgProfiles, 'applicationGateway')) {
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

@batchSize(1)
module subnetDeployments './virtual-network-subnet.bicep' = [
  for (subnet, index) in createdSubnets: {
    name: '${uniqueString(deployment().name, location)}-subnet-${subnet.key}-${index}'
    params: {
      virtualNetworkName: vnetSpoke.outputs.name
      name: createdSubnetNames[index]
      addressPrefix: subnet.cidr
      delegation: subnet.delegationProfile == 'appServicePlan'
        ? 'Microsoft.Web/serverfarms'
        : subnet.delegationProfile == 'appServiceEnvironment'
            ? 'Microsoft.Web/hostingEnvironments'
            : subnet.delegationProfile == 'postgresqlFlexibleServer'
                ? 'Microsoft.DBforPostgreSQL/flexibleServers'
                : null
      networkSecurityGroupResourceId: subnet.nsgProfile == 'appService'
        ? nsgAppSvc!.outputs.resourceId
        : subnet.nsgProfile == 'ase'
            ? nsgAse!.outputs.resourceId
            : subnet.nsgProfile == 'privateEndpoint'
                ? nsgPep!.outputs.resourceId
                : subnet.nsgProfile == 'postgresql'
                    ? nsgPostgreSql!.outputs.resourceId
                    : subnet.nsgProfile == 'applicationGateway'
                        ? nsgAppGw!.outputs.resourceId
                        : null
      routeTableResourceId: subnet.routeProfile == 'egressLockdown'
        ? routeTableToFirewall!.outputs.resourceId
        : null
      privateEndpointNetworkPolicies: subnet.?privateEndpointNetworkPolicies
      privateLinkServiceNetworkPolicies: subnet.?privateLinkServiceNetworkPolicies
      serviceEndpoints: subnet.?serviceEndpoints ?? []
      roleAssignments: subnet.?roleAssignments
      defaultOutboundAccess: subnet.?defaultOutboundAccess
      sharingScope: subnet.?sharingScope
    }
  }
]

output vnetSpokeResourceId string = vnetSpoke.outputs.resourceId
output vnetSpokeName string = vnetSpoke.outputs.name
output snetAppSvcResourceId string = subnetDeployments[indexOf(createdSubnetKeys, 'appService')].outputs.resourceId
output snetAppSvcName string = subnetDeployments[indexOf(createdSubnetKeys, 'appService')].outputs.name
output snetPeResourceId string? = indexOf(createdSubnetKeys, 'privateEndpoints') != -1 ? subnetDeployments[indexOf(createdSubnetKeys, 'privateEndpoints')].outputs.resourceId : null
output snetPeName string? = indexOf(createdSubnetKeys, 'privateEndpoints') != -1 ? subnetDeployments[indexOf(createdSubnetKeys, 'privateEndpoints')].outputs.name : null
output snetPostgreSqlResourceId string? = indexOf(createdSubnetKeys, 'postgresql') != -1 ? subnetDeployments[indexOf(createdSubnetKeys, 'postgresql')].outputs.resourceId : null
output snetPostgreSqlName string? = indexOf(createdSubnetKeys, 'postgresql') != -1 ? subnetDeployments[indexOf(createdSubnetKeys, 'postgresql')].outputs.name : null
output snetAppGwResourceId string? = indexOf(createdSubnetKeys, 'applicationGateway') != -1 ? subnetDeployments[indexOf(createdSubnetKeys, 'applicationGateway')].outputs.resourceId : null
output snetAppGwName string? = indexOf(createdSubnetKeys, 'applicationGateway') != -1 ? subnetDeployments[indexOf(createdSubnetKeys, 'applicationGateway')].outputs.name : null
