metadata name = 'Private DNS Zone SRV record'
metadata description = 'This module deploys a Private DNS Zone SRV record.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'

@description('Conditional. The name of the parent Private DNS zone. Required if the template is used in a standalone deployment.')
param privateDnsZoneName string

@description('Required. The name of the SRV record.')
param name string

@description('Optional. The metadata attached to the record set.')
param metadata resourceInput<'Microsoft.Network/privateDnsZones/SRV@2024-06-01'>.properties.metadata?

@description('Optional. The list of SRV records in the record set.')
param srvRecords resourceInput<'Microsoft.Network/privateDnsZones/SRV@2024-06-01'>.properties.srvRecords?

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

resource SRV 'Microsoft.Network/privateDnsZones/SRV@2024-06-01' = {
  name: name
  parent: privateDnsZone
  properties: {
    metadata: metadata
    srvRecords: srvRecords
    ttl: ttl
  }
}

resource SRV_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(SRV.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: SRV
  }
]

output name string = SRV.name

output resourceId string = SRV.id

output resourceGroupName string = resourceGroup().name
