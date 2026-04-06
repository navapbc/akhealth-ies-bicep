metadata name = 'Private Endpoints'
metadata description = 'This module deploys a Private Endpoint.'

@description('Required. Name of the private endpoint resource to create.')
param name string

@description('Required. Resource ID of the subnet where the endpoint needs to be created.')
param subnetResourceId string

@description('Optional. Application security groups in which the private endpoint IP configuration is included.')
param applicationSecurityGroupResourceIds string[]?

@description('Optional. The custom name of the network interface attached to the private endpoint.')
param customNetworkInterfaceName string?

@description('Optional. A list of IP configurations of the private endpoint. This will be used to map to the First Party Service endpoints.')
param ipConfigurations resourceInput<'Microsoft.Network/privateEndpoints@2025-05-01'>.properties.ipConfigurations?

@description('Optional. Specifies the IP version type for the private IPs of the private endpoint. If not defined, this defaults to IPv4.')
param ipVersionType resourceInput<'Microsoft.Network/privateEndpoints@2025-05-01'>.properties.ipVersionType = 'IPv4'

@description('Optional. The private DNS zone group to configure for the private endpoint.')
param privateDnsZoneGroup privateDnsZoneGroupType?

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

import { lockType } from '../shared/avm-common-types.bicep'
@description('Optional. The lock settings of the service.')
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

@description('Optional. Tags to be applied on all resources/resource groups in this deployment.')
param tags resourceInput<'Microsoft.Network/privateEndpoints@2025-05-01'>.tags?

@description('Optional. Custom DNS configurations.')
param customDnsConfigs resourceInput<'Microsoft.Network/privateEndpoints@2025-05-01'>.properties.customDnsConfigs?

@description('Conditional. A grouping of information about the connection to the remote resource. Used when the network admin does not have access to approve connections to the remote resource. Required if `privateLinkServiceConnections` is empty.')
param manualPrivateLinkServiceConnections resourceInput<'Microsoft.Network/privateEndpoints@2025-05-01'>.properties.manualPrivateLinkServiceConnections?

@description('Conditional. A grouping of information about the connection to the remote resource. Required if `manualPrivateLinkServiceConnections` is empty.')
param privateLinkServiceConnections resourceInput<'Microsoft.Network/privateEndpoints@2025-05-01'>.properties.privateLinkServiceConnections?


var builtInRoleNames = {
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  'DNS Resolver Contributor': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '0f2ebee7-ffd4-4fc0-b3b7-664099fdad5d'
  )
  'DNS Zone Contributor': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'befefa01-2a29-4197-83a8-272ff33ce314'
  )
  'Domain Services Contributor': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'eeaeda52-9324-47f6-8069-5d5bade478b2'
  )
  'Domain Services Reader': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '361898ef-9ed1-48c2-849c-a832951106bb'
  )
  'Network Contributor': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '4d97b98b-1d4f-4787-a291-c67834d212e7'
  )
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  'Private DNS Zone Contributor': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'b12aa53e-6015-4669-85d0-8515ebb3ae7f'
  )
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Role Based Access Control Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'f58310d9-a9f6-439a-9e8d-f62e7b41a168'
  )
}

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

@description('The resource group the private endpoint was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The resource ID of the private endpoint.')
output resourceId string = privateEndpoint.id

@description('The name of the private endpoint.')
output name string = privateEndpoint.name

@description('The location the resource was deployed into.')
output location string = privateEndpoint.location

@description('The custom DNS configurations of the private endpoint.')
output customDnsConfigs resourceOutput<'Microsoft.Network/privateEndpoints@2025-05-01'>.properties.customDnsConfigs = privateEndpoint.properties.customDnsConfigs

@description('The resource IDs of the network interfaces associated with the private endpoint.')
output networkInterfaceResourceIds string[] = map(privateEndpoint.properties.networkInterfaces, nic => nic.id)

@description('The group Id for the private endpoint Group.')
var manualGroupId = privateEndpoint.properties.?manualPrivateLinkServiceConnections[?0].properties.?groupIds[?0]
var standardGroupId = privateEndpoint.properties.?privateLinkServiceConnections[?0].properties.?groupIds[?0]
output groupId string? = manualGroupId ?? standardGroupId

// ================ //
// Definitions      //
// ================ //

import { privateDnsZoneGroupConfigType } from './private-endpoint-dns-zone-group.bicep'

@export()
@description('The type of a private dns zone group.')
type privateDnsZoneGroupType = {
  @description('Optional. The name of the Private DNS Zone Group.')
  name: string?

  @description('Required. The private DNS zone groups to associate the private endpoint. A DNS zone group can support up to 5 DNS zones.')
  privateDnsZoneGroupConfigs: privateDnsZoneGroupConfigType[]
}
