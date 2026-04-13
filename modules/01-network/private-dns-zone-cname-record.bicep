metadata name = 'Private DNS Zone CNAME record'
metadata description = 'This module deploys a Private DNS Zone CNAME record.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'

@description('Conditional. The name of the parent Private DNS zone. Required if the template is used in a standalone deployment.')
param privateDnsZoneName string

@description('Required. The name of the CNAME record.')
param name string

@description('Optional. A CNAME record.')
param cnameRecord resourceInput<'Microsoft.Network/privateDnsZones/CNAME@2024-06-01'>.properties.cnameRecord?

@description('Optional. The metadata attached to the record set.')
param metadata resourceInput<'Microsoft.Network/privateDnsZones/CNAME@2024-06-01'>.properties.metadata?

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

resource CNAME 'Microsoft.Network/privateDnsZones/CNAME@2024-06-01' = {
  name: name
  parent: privateDnsZone
  properties: {
    cnameRecord: cnameRecord
    metadata: metadata
    ttl: ttl
  }
}

resource CNAME_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(CNAME.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: CNAME
  }
]

output name string = CNAME.name

output resourceId string = CNAME.id

output resourceGroupName string = resourceGroup().name
