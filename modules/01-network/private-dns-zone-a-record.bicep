metadata name = 'Private DNS Zone A record'
metadata description = 'This module deploys a Private DNS Zone A record.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'

@description('Conditional. The name of the parent Private DNS zone. Required if the template is used in a standalone deployment.')
param privateDnsZoneName string

@description('Required. The name of the A record.')
param name string

@description('Optional. The list of A records in the record set.')
param aRecords resourceInput<'Microsoft.Network/privateDnsZones/A@2024-06-01'>.properties.aRecords?

@description('Optional. The metadata attached to the record set.')
param metadata resourceInput<'Microsoft.Network/privateDnsZones/A@2024-06-01'>.properties.metadata?

@description('Optional. The TTL (time-to-live) of the records in the record set.')
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

resource A 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  name: name
  parent: privateDnsZone
  properties: {
    aRecords: aRecords
    metadata: metadata
    ttl: ttl
  }
}

resource A_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(A.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: A
  }
]

output name string = A.name

output resourceId string = A.id

output resourceGroupName string = resourceGroup().name
