metadata name = 'Virtual Networks'
metadata description = 'This module deploys a Virtual Network (vNet).'

import { builtInRoleNames } from '../shared/role-definitions.bicep'

@description('Required. The name of the Virtual Network (vNet).')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. An Array of 1 or more IP Address Prefixes OR the resource ID of the IPAM pool to be used for the Virtual Network. When specifying an IPAM pool resource ID you must also set a value for the parameter called `ipamPoolNumberOfIpAddresses`.')
param addressPrefixes array

@description('Optional. Number of IP addresses allocated from the pool. To be used only when the addressPrefix param is defined with a resource ID of an IPAM pool.')
param ipamPoolNumberOfIpAddresses string?

@description('Optional. The BGP community associated with the virtual network.')
param virtualNetworkBgpCommunity string?

@description('Optional. An Array of subnets to deploy to the Virtual Network.')
param subnets subnetType[]?

@description('Optional. DNS Servers associated to the Virtual Network.')
param dnsServers string[]?

@description('Optional. Resource ID of the DDoS protection plan to assign the VNET to. If it\'s left blank, DDoS protection will not be configured. If it\'s provided, the VNET created by this template will be attached to the referenced DDoS protection plan. The DDoS protection plan can exist in the same or in a different subscription.')
param ddosProtectionPlanResourceId string?

@description('Optional. Virtual Network Peering configurations.')
param peerings peeringType[]?

@description('Optional. Indicates if encryption is enabled on virtual network and if VM without encryption is allowed in encrypted VNet. Requires the EnableVNetEncryption feature to be registered for the subscription and a supported region to use this property.')
param vnetEncryption bool

@allowed([
  'AllowUnencrypted'
  'DropUnencrypted'
])
@description('Optional. If the encrypted VNet allows VM that does not support encryption. Can only be used when vnetEncryption is enabled.')
param vnetEncryptionEnforcement string

@maxValue(30)
@description('Optional. The flow timeout in minutes for the Virtual Network, which is used to enable connection tracking for intra-VM flows. Possible values are between 4 and 30 minutes. Default value 0 will set the property to null.')
param flowTimeoutInMinutes int

import { diagnosticSettingFullType } from '../shared/avm-common-types.bicep'
@description('Optional. The diagnostic settings of the service.')
param diagnosticSettings diagnosticSettingFullType[]?

import { lockType } from '../shared/avm-common-types.bicep'
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

param tags object?


@description('Optional. Indicates if VM protection is enabled for all the subnets in the virtual network.')
param enableVmProtection bool?

@allowed([
  'Basic'
  'Disabled'
])
@description('Optional. Enables high scale private endpoints for the virtual network. This is necessary if the virtual network requires more than 1000 private endpoints or is peered to virtual networks with a total of more than 4000 private endpoints.')
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

@description('The names of the deployed subnets.')
output subnetNames array = [for (subnet, index) in (subnets ?? []): virtualNetwork_subnets[index].outputs.name]

@description('The resource IDs of the deployed subnets.')
output subnetResourceIds array = [
  for (subnet, index) in (subnets ?? []): virtualNetwork_subnets[index].outputs.resourceId
]

output location string = virtualNetwork.location

// =============== //
//   Definitions   //
// =============== //

@export()
type peeringType = {
  @description('Required. The name of the VNet peering resource.')
  name: string

  @description('Required. The Resource ID of the VNet that is this Local VNet is being peered to. Should be in the format of a Resource ID.')
  remoteVirtualNetworkResourceId: string

  @description('Required. The name of the remote virtual network.')
  remoteVirtualNetworkName: string

  @description('Required. The resource group name of the remote virtual network.')
  remoteVirtualNetworkResourceGroupName: string

  @description('Required. The subscription ID of the remote virtual network.')
  remoteVirtualNetworkSubscriptionId: string

  @description('Optional. Whether the forwarded traffic from the VMs in the local virtual network will be allowed/disallowed in remote virtual network. Default is true.')
  allowForwardedTraffic: bool?

  @description('Optional. If gateway links can be used in remote virtual networking to link to this virtual network. Default is false.')
  allowGatewayTransit: bool?

  @description('Optional. Whether the VMs in the local virtual network space would be able to access the VMs in remote virtual network space. Default is true.')
  allowVirtualNetworkAccess: bool?

  @description('Optional. Do not verify the provisioning state of the remote gateway. Default is true.')
  doNotVerifyRemoteGateways: bool?

  @description('Optional. If remote gateways can be used on this virtual network. If the flag is set to true, and allowGatewayTransit on remote peering is also true, virtual network will use gateways of remote virtual network for transit. Only one peering can have this flag set to true. This flag cannot be set if virtual network already has a gateway. Default is false.')
  useRemoteGateways: bool?

  @description('Optional. Deploy the outbound and the inbound peering.')
  remotePeeringEnabled: bool?

  @description('Optional. The name of the VNet peering resource in the remote Virtual Network.')
  remotePeeringName: string?

  @description('Optional. Whether the forwarded traffic from the VMs in the local virtual network will be allowed/disallowed in remote virtual network. Default is true.')
  remotePeeringAllowForwardedTraffic: bool?

  @description('Optional. If gateway links can be used in remote virtual networking to link to this virtual network. Default is false.')
  remotePeeringAllowGatewayTransit: bool?

  @description('Optional. Whether the VMs in the local virtual network space would be able to access the VMs in remote virtual network space. Default is true.')
  remotePeeringAllowVirtualNetworkAccess: bool?

  @description('Optional. Do not verify the provisioning state of the remote gateway. Default is true.')
  remotePeeringDoNotVerifyRemoteGateways: bool?

  @description('Optional. If remote gateways can be used on this virtual network. If the flag is set to true, and allowGatewayTransit on remote peering is also true, virtual network will use gateways of remote virtual network for transit. Only one peering can have this flag set to true. This flag cannot be set if virtual network already has a gateway. Default is false.')
  remotePeeringUseRemoteGateways: bool?
}

@export()
type subnetType = {
  @description('Required. The Name of the subnet resource.')
  name: string

  @description('Conditional. The address prefix for the subnet. Required if `addressPrefixes` is empty.')
  addressPrefix: string?

  @description('Conditional. List of address prefixes for the subnet. Required if `addressPrefix` is empty.')
  addressPrefixes: string[]?

  @description('Conditional. The address space for the subnet, deployed from IPAM Pool. Required if `addressPrefixes` and `addressPrefix` is empty and the VNet address space configured to use IPAM Pool.')
  ipamPoolPrefixAllocations: [
    {
      @description('Required. The Resource ID of the IPAM pool.')
      pool: {
        @description('Required. The Resource ID of the IPAM pool.')
        id: string
      }
      @description('Required. Number of IP addresses allocated from the pool.')
      numberOfIpAddresses: string
    }
  ]?

  @description('Optional. Application gateway IP configurations of virtual network resource.')
  applicationGatewayIPConfigurations: object[]?

  @description('Optional. The delegation to enable on the subnet.')
  delegation: string?

  @description('Optional. The resource ID of the NAT Gateway to use for the subnet.')
  natGatewayResourceId: string?

  @description('Optional. The resource ID of the network security group to assign to the subnet.')
  networkSecurityGroupResourceId: string?

  @description('Optional. enable or disable apply network policies on private endpoint in the subnet.')
  privateEndpointNetworkPolicies: ('Disabled' | 'Enabled' | 'NetworkSecurityGroupEnabled' | 'RouteTableEnabled')?

  @description('Optional. enable or disable apply network policies on private link service in the subnet.')
  privateLinkServiceNetworkPolicies: ('Disabled' | 'Enabled')?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType[]?

  @description('Optional. The resource ID of the route table to assign to the subnet.')
  routeTableResourceId: string?

  @description('Optional. An array of service endpoint policies.')
  serviceEndpointPolicies: object[]?

  @description('Optional. The service endpoints to enable on the subnet.')
  serviceEndpoints: string[]?

  @description('Optional. Set this property to false to disable default outbound connectivity for all VMs in the subnet. This property can only be set at the time of subnet creation and cannot be updated for an existing subnet.')
  defaultOutboundAccess: bool?

  @description('Optional. Set this property to Tenant to allow sharing subnet with other subscriptions in your AAD tenant. This property can only be set if defaultOutboundAccess is set to false, both properties can only be set if subnet is empty.')
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
