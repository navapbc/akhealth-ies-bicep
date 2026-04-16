metadata name = 'Private Endpoints'
metadata description = 'This module deploys a Private Endpoint.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'

param name string
param subnetResourceId string
param applicationSecurityGroupResourceIds string[]?
param customNetworkInterfaceName string?
param ipConfigurations resourceInput<'Microsoft.Network/privateEndpoints@2025-05-01'>.properties.ipConfigurations?
param ipVersionType resourceInput<'Microsoft.Network/privateEndpoints@2025-05-01'>.properties.ipVersionType = 'IPv4'
param privateDnsZoneGroup privateDnsZoneGroupType?
param location string = resourceGroup().location

import { lockType } from '../shared/avm-common-types.bicep'
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
param roleAssignments roleAssignmentType[]?
param tags resourceInput<'Microsoft.Network/privateEndpoints@2025-05-01'>.tags?
param customDnsConfigs resourceInput<'Microsoft.Network/privateEndpoints@2025-05-01'>.properties.customDnsConfigs?
param manualPrivateLinkServiceConnections resourceInput<'Microsoft.Network/privateEndpoints@2025-05-01'>.properties.manualPrivateLinkServiceConnections?
param privateLinkServiceConnections resourceInput<'Microsoft.Network/privateEndpoints@2025-05-01'>.properties.privateLinkServiceConnections?
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
var resolvedApplicationSecurityGroups = [
  for applicationSecurityGroupResourceId in (applicationSecurityGroupResourceIds ?? []): {
    id: applicationSecurityGroupResourceId
  }
]
var resolvedCustomDnsConfigs = customDnsConfigs ?? []
var resolvedCustomNetworkInterfaceName = customNetworkInterfaceName ?? ''
var resolvedIpConfigurations = ipConfigurations ?? []
var resolvedManualPrivateLinkServiceConnections = manualPrivateLinkServiceConnections ?? []
var resolvedPrivateLinkServiceConnections = privateLinkServiceConnections ?? []

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2025-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    applicationSecurityGroups: resolvedApplicationSecurityGroups
    customDnsConfigs: resolvedCustomDnsConfigs
    customNetworkInterfaceName: resolvedCustomNetworkInterfaceName
    ipConfigurations: resolvedIpConfigurations
    manualPrivateLinkServiceConnections: resolvedManualPrivateLinkServiceConnections
    privateLinkServiceConnections: resolvedPrivateLinkServiceConnections
    subnet: {
      id: subnetResourceId
    }
    ipVersionType: ipVersionType
  }
}

module privateEndpoint_privateDnsZoneGroup './private-endpoint-dns-zone-group.bicep' = if (!empty(privateDnsZoneGroup)) {
  name: '${uniqueString(deployment().name)}-PrivateEndpoint-PrivateDnsZoneGroup'
  params: {
    name: privateDnsZoneGroup.?name
    privateEndpointName: privateEndpoint.name
    privateDnsZoneConfigs: privateDnsZoneGroup!.privateDnsZoneGroupConfigs
  }
}

resource privateEndpoint_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(privateEndpoint.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: privateEndpoint
  }
]
output resourceGroupName string = resourceGroup().name
output resourceId string = privateEndpoint.id
output name string = privateEndpoint.name
output location string = privateEndpoint.location
output customDnsConfigs resourceOutput<'Microsoft.Network/privateEndpoints@2025-05-01'>.properties.customDnsConfigs = privateEndpoint.properties.customDnsConfigs
output networkInterfaceResourceIds string[] = map(privateEndpoint.properties.networkInterfaces, nic => nic.id)
var manualGroupId = privateEndpoint.properties.?manualPrivateLinkServiceConnections[?0].properties.?groupIds[?0]
var standardGroupId = privateEndpoint.properties.?privateLinkServiceConnections[?0].properties.?groupIds[?0]
output groupId string? = manualGroupId ?? standardGroupId

// ================ //
// Definitions      //
// ================ //

import { privateDnsZoneGroupConfigType } from './private-endpoint-dns-zone-group.bicep'

@export()
type privateDnsZoneGroupType = {
  name: string?
  privateDnsZoneGroupConfigs: privateDnsZoneGroupConfigType[]
}

resource privateEndpoint_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${name}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?notes ?? (lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: privateEndpoint
}
