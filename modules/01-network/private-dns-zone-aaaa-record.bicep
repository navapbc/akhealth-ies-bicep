metadata name = 'Private DNS Zone AAAA record'
metadata description = 'This module deploys a Private DNS Zone AAAA record.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'

param privateDnsZoneName string
param name string
param aaaaRecords resourceInput<'Microsoft.Network/privateDnsZones/AAAA@2024-06-01'>.properties.aaaaRecords?
param metadata resourceInput<'Microsoft.Network/privateDnsZones/AAAA@2024-06-01'>.properties.metadata?
param ttl int = 3600

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
@sys.description('Optional. Array of role assignments to create.')
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

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: privateDnsZoneName
}

resource AAAA 'Microsoft.Network/privateDnsZones/AAAA@2024-06-01' = {
  name: name
  parent: privateDnsZone
  properties: {
    aaaaRecords: aaaaRecords
    metadata: metadata
    ttl: ttl
  }
}

resource AAAA_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(AAAA.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: AAAA
  }
]
output name string = AAAA.name
output resourceId string = AAAA.id
output resourceGroupName string = resourceGroup().name
