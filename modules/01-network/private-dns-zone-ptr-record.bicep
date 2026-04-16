metadata name = 'Private DNS Zone PTR record'
metadata description = 'This module deploys a Private DNS Zone PTR record.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'

param privateDnsZoneName string
param name string
param metadata resourceInput<'Microsoft.Network/privateDnsZones/PTR@2024-06-01'>.properties.metadata?
param ptrRecords resourceInput<'Microsoft.Network/privateDnsZones/PTR@2024-06-01'>.properties.ptrRecords?
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

resource PTR 'Microsoft.Network/privateDnsZones/PTR@2024-06-01' = {
  name: name
  parent: privateDnsZone
  properties: {
    metadata: metadata
    ptrRecords: ptrRecords
    ttl: ttl
  }
}

resource PTR_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(PTR.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: PTR
  }
]
output name string = PTR.name
output resourceId string = PTR.id
output resourceGroupName string = resourceGroup().name
