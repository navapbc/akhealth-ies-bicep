metadata name = 'Public IP Addresses'
metadata description = 'This module deploys a Public IP Address.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'

param name string
param publicIpPrefixResourceId string?
param publicIPAllocationMethod resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.properties.publicIPAllocationMethod = 'Static'
@allowed([
  1
  2
  3
])
param availabilityZones int[] = [
  1
  2
  3
]
param publicIPAddressVersion resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.properties.publicIPAddressVersion = 'IPv4'
param dnsSettings resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.properties.dnsSettings?
param ipTags resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.properties.ipTags?

import { lockType } from '../shared/avm-common-types.bicep'
param lock lockType?
param skuName resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.sku.name = 'Standard'
param skuTier resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.sku.tier = 'Regional'
param ddosSettings resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.properties.ddosSettings?
param deleteOption resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.properties.deleteOption?
param location string = resourceGroup().location

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
param roleAssignments roleAssignmentType[]?
param idleTimeoutInMinutes int = 4
param tags resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.tags?

import { diagnosticSettingFullType } from '../shared/avm-common-types.bicep'
param diagnosticSettings diagnosticSettingFullType[]?
var diagnosticSettingsDerivedName = replace(name, 'pip-', 'dgspip-')
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

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2025-05-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
  zones: map(availabilityZones, zone => string(zone))
  properties: {
    ddosSettings: ddosSettings
    dnsSettings: dnsSettings
    publicIPAddressVersion: publicIPAddressVersion
    publicIPAllocationMethod: publicIPAllocationMethod
    publicIPPrefix: !empty(publicIpPrefixResourceId)
      ? {
          id: publicIpPrefixResourceId
        }
      : null
    idleTimeoutInMinutes: idleTimeoutInMinutes
    ipTags: ipTags
    deleteOption: deleteOption
  }
}

resource publicIpAddress_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(publicIpAddress.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: publicIpAddress
  }
]

resource publicIpAddress_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
  for (diagnosticSetting, index) in (diagnosticSettings ?? []): {
    name: diagnosticSetting.?name ?? (length(diagnosticSettings ?? []) > 1 ? '${diagnosticSettingsDerivedName}-${index + 1}' : diagnosticSettingsDerivedName)
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
    scope: publicIpAddress
  }
]
output resourceGroupName string = resourceGroup().name
output name string = publicIpAddress.name
output resourceId string = publicIpAddress.id
output ipAddress string = publicIpAddress.properties.?ipAddress ?? ''
output location string = publicIpAddress.location

resource publicIpAddress_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${name}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?notes ?? (lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: publicIpAddress
}
