metadata name = 'Virtual Network Subnets'
metadata description = 'This module deploys a Virtual Network Subnet.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'

param name string
param virtualNetworkName string
param addressPrefix string?
param ipamPoolPrefixAllocations object[]?
param networkSecurityGroupResourceId string?
param routeTableResourceId string?
param serviceEndpoints string[] = []
param delegation string?
param natGatewayResourceId string?
@allowed([
  'Disabled'
  'Enabled'
  'NetworkSecurityGroupEnabled'
  'RouteTableEnabled'
])
param privateEndpointNetworkPolicies string?
@allowed([
  'Disabled'
  'Enabled'
])
param privateLinkServiceNetworkPolicies string?
param addressPrefixes string[]?
param defaultOutboundAccess bool?
param sharingScope ('DelegatedServices' | 'Tenant')?
param applicationGatewayIPConfigurations array = []
param serviceEndpointPolicies array = []

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
param roleAssignments roleAssignmentType[]?
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
var delegatedPostgreSqlSubnetContractIsValid = delegation == 'Microsoft.DBforPostgreSQL/flexibleServers' && privateEndpointNetworkPolicies != null
  ? fail('Subnets delegated to Microsoft.DBforPostgreSQL/flexibleServers must not also declare privateEndpointNetworkPolicies. Leave privateEndpointNetworkPolicies unset for these delegated subnets and let the platform manage the resulting state.')
  : true

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2025-05-01' existing = {
  name: virtualNetworkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2025-05-01' = {
  name: delegatedPostgreSqlSubnetContractIsValid ? name : name
  parent: virtualNetwork
  properties: {
    // Keeps delegated subnet policy handling explicit and avoids mixing
    // private-endpoint subnet semantics into service-delegated subnets.
    addressPrefix: addressPrefix
    addressPrefixes: addressPrefixes
    ipamPoolPrefixAllocations: ipamPoolPrefixAllocations
    networkSecurityGroup: !empty(networkSecurityGroupResourceId)
      ? {
          id: networkSecurityGroupResourceId
        }
      : null
    routeTable: !empty(routeTableResourceId)
      ? {
          id: routeTableResourceId
        }
      : null
    natGateway: !empty(natGatewayResourceId)
      ? {
          id: natGatewayResourceId
        }
      : null
    serviceEndpoints: [
      for endpoint in serviceEndpoints: {
        service: endpoint
      }
    ]
    delegations: !empty(delegation)
      ? [
          {
            name: delegation
            properties: {
              serviceName: delegation
            }
          }
        ]
      : []
    privateEndpointNetworkPolicies: privateEndpointNetworkPolicies
    privateLinkServiceNetworkPolicies: privateLinkServiceNetworkPolicies
    applicationGatewayIPConfigurations: applicationGatewayIPConfigurations
    serviceEndpointPolicies: serviceEndpointPolicies
    defaultOutboundAccess: defaultOutboundAccess
    sharingScope: sharingScope
  }
}

resource subnet_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(subnet.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: subnet
  }
]
output resourceGroupName string = resourceGroup().name
output name string = subnet.name
output resourceId string = subnet.id
output addressPrefix string = subnet.properties.?addressPrefix ?? ''
output addressPrefixes array = subnet.properties.?addressPrefixes ?? []
output ipamPoolPrefixAllocations array = subnet.properties.?ipamPoolPrefixAllocations ?? []
