metadata name = 'Virtual Networks'
metadata description = 'This module deploys a Virtual Network (vNet).'

import { builtInRoleNames } from '../shared/role-definitions.bicep'

param name string
param location string = resourceGroup().location
param addressPrefixes array
param ipamPoolNumberOfIpAddresses string?
param virtualNetworkBgpCommunity string?
param subnets subnetType[]?
param dnsServers string[]?
param ddosProtectionPlanResourceId string?
param peerings peeringType[]?
param vnetEncryption bool
@allowed([
  'AllowUnencrypted'
  'DropUnencrypted'
])
param vnetEncryptionEnforcement string
@maxValue(30)
param flowTimeoutInMinutes int

import { diagnosticSettingFullType } from '../shared/avm-common-types.bicep'
param diagnosticSettings diagnosticSettingFullType[]?

import { lockType } from '../shared/avm-common-types.bicep'
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
param roleAssignments roleAssignmentType[]?
param tags object?
param enableVmProtection bool?
@allowed([
  'Basic'
  'Disabled'
])
param enablePrivateEndpointVNetPolicies string
var formattedRoleAssignments = [
  for (roleAssignment, index) in (roleAssignments ?? []): union(roleAssignment, {
    roleDefinitionId: builtInRoleNames[?roleAssignment.roleDefinitionIdOrName] ?? (contains(
        roleAssignment.roleDefinitionIdOrName,
        '/providers/Microsoft.Authorization/roleDefinitions/'
      )
      ? roleAssignment.roleDefinitionIdOrName
      : subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionIdOrName))
  })
]

// ============ //
// Dependencies //
// ============ //

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2025-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: contains(addressPrefixes[0], '/Microsoft.Network/networkManagers/')
      ? {
          ipamPoolPrefixAllocations: [
            {
              pool: {
                id: addressPrefixes[0]
              }
              numberOfIpAddresses: ipamPoolNumberOfIpAddresses
            }
          ]
        }
      : {
          addressPrefixes: addressPrefixes
        }
    bgpCommunities: !empty(virtualNetworkBgpCommunity)
      ? {
          virtualNetworkCommunity: virtualNetworkBgpCommunity!
        }
      : null
    ddosProtectionPlan: !empty(ddosProtectionPlanResourceId)
      ? {
          id: ddosProtectionPlanResourceId
        }
      : null
    dhcpOptions: !empty(dnsServers)
      ? {
          dnsServers: array(dnsServers)
        }
      : null
    enableDdosProtection: !empty(ddosProtectionPlanResourceId)
    encryption: vnetEncryption == true
      ? {
          enabled: vnetEncryption
          enforcement: vnetEncryptionEnforcement
        }
      : null
    flowTimeoutInMinutes: flowTimeoutInMinutes != 0 ? flowTimeoutInMinutes : null
    enableVmProtection: enableVmProtection
    privateEndpointVNetPolicies: enablePrivateEndpointVNetPolicies
  }
}

#disable-diagnostics no-unnecessary-dependson
@batchSize(1)
module virtualNetwork_subnets './virtual-network-subnet.bicep' = [
  for (subnet, index) in (subnets ?? []): {
    name: '${uniqueString(subscription().id, resourceGroup().id, location)}-subnet-${index}'
    // The subnet module treats the VNet as an existing parent, so we need
    // explicit ordering here to prevent ARM from racing the child deployments.
    dependsOn: [
      virtualNetwork
    ]
    params: {
      virtualNetworkName: virtualNetwork.name
      name: subnet.name
      addressPrefix: subnet.?addressPrefix
      addressPrefixes: subnet.?addressPrefixes
      ipamPoolPrefixAllocations: subnet.?ipamPoolPrefixAllocations
      applicationGatewayIPConfigurations: subnet.?applicationGatewayIPConfigurations
      delegation: subnet.?delegation
      natGatewayResourceId: subnet.?natGatewayResourceId
      networkSecurityGroupResourceId: subnet.?networkSecurityGroupResourceId
      privateEndpointNetworkPolicies: subnet.?privateEndpointNetworkPolicies
      privateLinkServiceNetworkPolicies: subnet.?privateLinkServiceNetworkPolicies
      roleAssignments: subnet.?roleAssignments
      routeTableResourceId: subnet.?routeTableResourceId
      serviceEndpointPolicies: subnet.?serviceEndpointPolicies
      serviceEndpoints: subnet.?serviceEndpoints
      defaultOutboundAccess: subnet.?defaultOutboundAccess
      sharingScope: subnet.?sharingScope    }
  }
]

// Local to Remote peering
module virtualNetwork_peering_local './virtual-network-peering.bicep' = [
  for (peering, index) in (peerings ?? []): {
    name: '${uniqueString(subscription().id, resourceGroup().id, location)}-virtualNetworkPeering-local-${index}'
    // This is a workaround for an error in which the peering is deployed whilst the subnet creation is still taking place
    // TODO: https://github.com/Azure/bicep/issues/1013 would be a better solution
    dependsOn: [
      virtualNetwork_subnets
    ]
    params: {
      localVnetName: virtualNetwork.name
      remoteVirtualNetworkResourceId: peering.remoteVirtualNetworkResourceId
      name: peering.?name
      allowForwardedTraffic: peering.?allowForwardedTraffic
      allowGatewayTransit: peering.?allowGatewayTransit
      allowVirtualNetworkAccess: peering.?allowVirtualNetworkAccess
      doNotVerifyRemoteGateways: peering.?doNotVerifyRemoteGateways
      useRemoteGateways: peering.?useRemoteGateways
    }
  }
]
#restore-diagnostics no-unnecessary-dependson

// Remote to local peering (reverse)
module virtualNetwork_peering_remote './virtual-network-peering.bicep' = [
  for (peering, index) in (peerings ?? []): if (peering.?remotePeeringEnabled ?? false) {
    name: '${uniqueString(subscription().id, resourceGroup().id, location)}-virtualNetworkPeering-remote-${index}'
    // This is a workaround for an error in which the peering is deployed whilst the subnet creation is still taking place
    // TODO: https://github.com/Azure/bicep/issues/1013 would be a better solution
    dependsOn: [
      virtualNetwork_subnets
    ]
    scope: resourceGroup(peering.remoteVirtualNetworkSubscriptionId, peering.remoteVirtualNetworkResourceGroupName)
    params: {
      localVnetName: peering.remoteVirtualNetworkName
      remoteVirtualNetworkResourceId: virtualNetwork.id
      name: peering.?remotePeeringName
      allowForwardedTraffic: peering.?remotePeeringAllowForwardedTraffic
      allowGatewayTransit: peering.?remotePeeringAllowGatewayTransit
      allowVirtualNetworkAccess: peering.?remotePeeringAllowVirtualNetworkAccess
      doNotVerifyRemoteGateways: peering.?remotePeeringDoNotVerifyRemoteGateways
      useRemoteGateways: peering.?remotePeeringUseRemoteGateways
    }
  }
]

resource virtualNetwork_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
  for (diagnosticSetting, index) in (diagnosticSettings ?? []): {
    name: diagnosticSetting.?name ?? '${name}-diagnosticSettings'
    properties: {
      storageAccountId: diagnosticSetting.?storageAccountResourceId
      workspaceId: diagnosticSetting.?workspaceResourceId
      eventHubAuthorizationRuleId: diagnosticSetting.?eventHubAuthorizationRuleResourceId
      eventHubName: diagnosticSetting.?eventHubName
      metrics: [
        for group in (diagnosticSetting.?metricCategories ?? [{ category: 'AllMetrics' }]): {
          category: group.category
          enabled: group.?enabled ?? true
          timeGrain: null
        }
      ]
      logs: [
        for group in (diagnosticSetting.?logCategoriesAndGroups ?? [{ categoryGroup: 'allLogs' }]): {
          categoryGroup: group.?categoryGroup
          category: group.?category
          enabled: group.?enabled ?? true
        }
      ]
      marketplacePartnerId: diagnosticSetting.?marketplacePartnerResourceId
      logAnalyticsDestinationType: diagnosticSetting.?logAnalyticsDestinationType
    }
    scope: virtualNetwork
  }
]

resource virtualNetwork_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(virtualNetwork.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: virtualNetwork
  }
]
output resourceGroupName string = resourceGroup().name
output resourceId string = virtualNetwork.id
output name string = virtualNetwork.name
output subnetNames array = [for (subnet, index) in (subnets ?? []): virtualNetwork_subnets[index].outputs.name]
output subnetResourceIds array = [
  for (subnet, index) in (subnets ?? []): virtualNetwork_subnets[index].outputs.resourceId
]
output location string = virtualNetwork.location

// =============== //
//   Definitions   //
// =============== //

@export()
type peeringType = {
  name: string
  remoteVirtualNetworkResourceId: string
  remoteVirtualNetworkName: string
  remoteVirtualNetworkResourceGroupName: string
  remoteVirtualNetworkSubscriptionId: string
  allowForwardedTraffic: bool?
  allowGatewayTransit: bool?
  allowVirtualNetworkAccess: bool?
  doNotVerifyRemoteGateways: bool?
  useRemoteGateways: bool?
  remotePeeringEnabled: bool?
  remotePeeringName: string?
  remotePeeringAllowForwardedTraffic: bool?
  remotePeeringAllowGatewayTransit: bool?
  remotePeeringAllowVirtualNetworkAccess: bool?
  remotePeeringDoNotVerifyRemoteGateways: bool?
  remotePeeringUseRemoteGateways: bool?
}

@export()
type subnetType = {
  name: string
  addressPrefix: string?
  addressPrefixes: string[]?
  ipamPoolPrefixAllocations: [
    {
      pool: {
        id: string
      }
      numberOfIpAddresses: string
    }
  ]?
  applicationGatewayIPConfigurations: object[]?
  delegation: string?
  natGatewayResourceId: string?
  networkSecurityGroupResourceId: string?
  privateEndpointNetworkPolicies: ('Disabled' | 'Enabled' | 'NetworkSecurityGroupEnabled' | 'RouteTableEnabled')?
  privateLinkServiceNetworkPolicies: ('Disabled' | 'Enabled')?
  roleAssignments: roleAssignmentType[]?
  routeTableResourceId: string?
  serviceEndpointPolicies: object[]?
  serviceEndpoints: string[]?
  defaultOutboundAccess: bool?
  sharingScope: ('DelegatedServices' | 'Tenant')?
}

resource virtualNetwork_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${name}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?notes ?? (lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: virtualNetwork
}
