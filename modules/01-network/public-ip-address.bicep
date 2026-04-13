metadata name = 'Public IP Addresses'
metadata description = 'This module deploys a Public IP Address.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'

@description('Required. The name of the Public IP Address.')
param name string

@description('Optional. Resource ID of the Public IP Prefix object. This is only needed if you want your Public IPs created in a PIP Prefix.')
param publicIpPrefixResourceId string?

@description('Optional. The public IP address allocation method.')
param publicIPAllocationMethod resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.properties.publicIPAllocationMethod = 'Static'

@description('Optional. A list of availability zones denoting the IP allocated for the resource needs to come from.')
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

@description('Optional. IP address version.')
param publicIPAddressVersion resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.properties.publicIPAddressVersion = 'IPv4'

@description('Optional. The DNS settings of the public IP address.')
param dnsSettings resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.properties.dnsSettings?

@description('Optional. The list of tags associated with the public IP address.')
param ipTags resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.properties.ipTags?

import { lockType } from '../shared/avm-common-types.bicep'
param lock lockType?

@description('Optional. Name of a public IP address SKU.')
param skuName resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.sku.name = 'Standard'

@description('Optional. Tier of a public IP address SKU.')
param skuTier resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.sku.tier = 'Regional'

@description('Optional. The DDoS protection plan configuration associated with the public IP address.')
param ddosSettings resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.properties.ddosSettings?

@description('Optional. The delete option for the public IP address.')
param deleteOption resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.properties.deleteOption?

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?


@description('Optional. The idle timeout of the public IP address.')
param idleTimeoutInMinutes int = 4

param tags resourceInput<'Microsoft.Network/publicIPAddresses@2025-05-01'>.tags?

import { diagnosticSettingFullType } from '../shared/avm-common-types.bicep'
@description('Optional. The diagnostic settings of the service.')
param diagnosticSettings diagnosticSettingFullType[]?

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
    name: diagnosticSetting.?name ?? '${name}-diagnosticSettings'
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

@description('The public IP address of the public IP address resource.')
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
