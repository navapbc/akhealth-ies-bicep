metadata name = 'Network Security Groups'
metadata description = 'This module deploys a Network security Group (NSG).'

import { builtInRoleNames } from '../shared/role-definitions.bicep'

param name string
param location string = resourceGroup().location
param securityRules securityRuleType[]?
param flushConnection bool = false

import { diagnosticSettingLogsOnlyType } from '../shared/avm-common-types.bicep'
param diagnosticSettings diagnosticSettingLogsOnlyType[]?

import { lockType } from '../shared/avm-common-types.bicep'
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
param roleAssignments roleAssignmentType[]?
param tags resourceInput<'Microsoft.Network/networkSecurityGroups@2025-05-01'>.tags?
var diagnosticSettingsDerivedName = replace(name, 'nsg-', 'dgsnsg-')
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

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2025-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    flushConnection: flushConnection
    securityRules: [
      for securityRule in securityRules ?? []: {
        name: securityRule.name
        properties: {
          access: securityRule.properties.access
          description: securityRule.properties.?description ?? ''
          destinationAddressPrefix: securityRule.properties.?destinationAddressPrefix ?? ''
          destinationAddressPrefixes: securityRule.properties.?destinationAddressPrefixes ?? []
          destinationApplicationSecurityGroups: map(
            securityRule.properties.?destinationApplicationSecurityGroupResourceIds ?? [],
            (destinationApplicationSecurityGroupResourceId) => {
              id: destinationApplicationSecurityGroupResourceId
            }
          )
          destinationPortRange: securityRule.properties.?destinationPortRange ?? ''
          destinationPortRanges: securityRule.properties.?destinationPortRanges ?? []
          direction: securityRule.properties.direction
          priority: securityRule.properties.priority
          protocol: securityRule.properties.protocol
          sourceAddressPrefix: securityRule.properties.?sourceAddressPrefix ?? ''
          sourceAddressPrefixes: securityRule.properties.?sourceAddressPrefixes ?? []
          sourceApplicationSecurityGroups: map(
            securityRule.properties.?sourceApplicationSecurityGroupResourceIds ?? [],
            (sourceApplicationSecurityGroupResourceId) => {
              id: sourceApplicationSecurityGroupResourceId
            }
          )
          sourcePortRange: securityRule.properties.?sourcePortRange ?? ''
          sourcePortRanges: securityRule.properties.?sourcePortRanges ?? []
        }
      }
    ]
  }
}

resource networkSecurityGroup_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
  for (diagnosticSetting, index) in (diagnosticSettings ?? []): {
    name: diagnosticSetting.?name ?? (length(diagnosticSettings ?? []) > 1 ? '${diagnosticSettingsDerivedName}-${index + 1}' : diagnosticSettingsDerivedName)
    properties: {
      storageAccountId: diagnosticSetting.?storageAccountResourceId
      workspaceId: diagnosticSetting.?workspaceResourceId
      eventHubAuthorizationRuleId: diagnosticSetting.?eventHubAuthorizationRuleResourceId
      eventHubName: diagnosticSetting.?eventHubName
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
    scope: networkSecurityGroup
  }
]

resource networkSecurityGroup_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(
      networkSecurityGroup.id,
      roleAssignment.principalId,
      roleAssignment.roleDefinitionId
    )
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: networkSecurityGroup
  }
]
output resourceGroupName string = resourceGroup().name
output resourceId string = networkSecurityGroup.id
output name string = networkSecurityGroup.name
output location string = networkSecurityGroup.location

// =============== //
//   Definitions   //
// =============== //

@export()
type securityRuleType = {
  name: string
  properties: {
    access: ('Allow' | 'Deny')
    description: string?
    destinationAddressPrefix: string?
    destinationAddressPrefixes: string[]?
    destinationApplicationSecurityGroupResourceIds: string[]?
    destinationPortRange: string?
    destinationPortRanges: string[]?
    direction: ('Inbound' | 'Outbound')
    @minValue(100)
    @maxValue(4096)
    priority: int
    protocol: ('Ah' | 'Esp' | 'Icmp' | 'Tcp' | 'Udp' | '*')
    sourceAddressPrefix: string?
    sourceAddressPrefixes: string[]?
    sourceApplicationSecurityGroupResourceIds: string[]?
    sourcePortRange: string?
    sourcePortRanges: string[]?
  }
}

resource networkSecurityGroup_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${name}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?notes ?? (lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: networkSecurityGroup
}
