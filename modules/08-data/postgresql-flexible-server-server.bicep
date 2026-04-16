metadata name = 'PostgreSQL Flexible Server'
metadata description = 'Deploys an Azure Database for PostgreSQL Flexible Server for this workload template set.'

import {
  diagnosticSettingFullType
  lockType
  roleAssignmentType
} from '../shared/avm-common-types.bicep'
import { builtInRoleNames } from '../shared/role-definitions.bicep'

param name string
param location string
param administrators administratorType[]
param authConfig resourceInput<'Microsoft.DBforPostgreSQL/flexibleServers@2025-08-01'>.properties.authConfig
param skuName string
@allowed([
  'GeneralPurpose'
  'Burstable'
  'MemoryOptimized'
])
param tier string
@allowed([
  -1
  1
  2
  3
])
param availabilityZone int
@allowed([
  -1
  1
  2
  3
])
param highAvailabilityZone int
@allowed([
  'Disabled'
  'SameZone'
  'ZoneRedundant'
])
param highAvailability string
@minValue(7)
@maxValue(35)
param backupRetentionDays int
@allowed([
  'Disabled'
  'Enabled'
])
param geoRedundantBackup string
@allowed([
  32
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
])
param storageSizeGB int
@allowed([
  'Disabled'
  'Enabled'
])
param autoGrow string
@allowed([
  '11'
  '12'
  '13'
  '14'
  '15'
  '16'
  '17'
  '18'
])
param version string
@allowed([
  'Disabled'
  'Enabled'
])
param publicNetworkAccess string
param delegatedSubnetResourceId string?
param privateDnsZoneArmResourceId string?
param databases databaseType[]
param configurations configurationType[]
param lock lockType?
param roleAssignments roleAssignmentType[]
param diagnosticSettings diagnosticSettingFullType[]
param tags resourceInput<'Microsoft.DBforPostgreSQL/flexibleServers@2025-08-01'>.tags?
var diagnosticSettingsDerivedName = replace(name, 'psqlfx-', 'dgspsqlfx-')
var privateAccessEnabled = delegatedSubnetResourceId != null
var privateDnsZoneProvided = privateDnsZoneArmResourceId != null
var privateAccessContractIsValid = privateAccessEnabled
  ? (privateDnsZoneProvided
      ? true
      : fail('PostgreSQL private access requires privateDnsZoneArmResourceId when delegatedSubnetResourceId is provided.'))
  : (!privateDnsZoneProvided
      ? true
      : fail('PostgreSQL public access must not provide privateDnsZoneArmResourceId when delegatedSubnetResourceId is null.'))
var standbyAvailabilityZone = {
  Disabled: -1
  SameZone: availabilityZone
  ZoneRedundant: highAvailabilityZone
}[?highAvailability]

var formattedRoleAssignments = [
  for roleAssignment in roleAssignments: union(roleAssignment, {
    roleDefinitionId: contains(builtInRoleNames, roleAssignment.roleDefinitionIdOrName)
      ? builtInRoleNames[?roleAssignment.roleDefinitionIdOrName]!
      : (contains(roleAssignment.roleDefinitionIdOrName, '/providers/Microsoft.Authorization/roleDefinitions/')
          ? roleAssignment.roleDefinitionIdOrName
          : subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionIdOrName))
  })
]

resource flexibleServer 'Microsoft.DBforPostgreSQL/flexibleServers@2025-08-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: tier
  }
  properties: {
    authConfig: authConfig
    availabilityZone: availabilityZone != -1 ? string(availabilityZone) : null
    highAvailability: {
      mode: highAvailability
      standbyAvailabilityZone: standbyAvailabilityZone != -1 ? string(standbyAvailabilityZone) : null
    }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    network: privateAccessContractIsValid && privateAccessEnabled
      ? {
          delegatedSubnetResourceId: delegatedSubnetResourceId
          privateDnsZoneArmResourceId: privateDnsZoneArmResourceId
          publicNetworkAccess: publicNetworkAccess
        }
      : {
          publicNetworkAccess: publicNetworkAccess
        }
    storage: {
      storageSizeGB: storageSizeGB
      autoGrow: autoGrow
    }
    version: version
  }
}

resource flexibleServer_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for roleAssignment in formattedRoleAssignments: {
    name: roleAssignment.?name ?? guid(flexibleServer.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: flexibleServer
  }
]

module flexibleServer_databases './postgresql-flexible-server-database.bicep' = [
  for (database, index) in databases: {
    name: '${uniqueString(deployment().name, location)}-postgresql-database-${index}'
    params: {
      name: database.name
      flexibleServerName: flexibleServer.name
      collation: database.?collation
      charset: database.?charset
    }
  }
]

@batchSize(1)
module flexibleServer_configurations './postgresql-flexible-server-configuration.bicep' = [
  for (configuration, index) in configurations: {
    name: '${uniqueString(deployment().name, location)}-postgresql-configuration-${index}'
    params: {
      name: configuration.name
      flexibleServerName: flexibleServer.name
      source: configuration.?source
      value: configuration.?value
    }
  }
]

module flexibleServer_administrators './postgresql-flexible-server-administrator.bicep' = [
  for (administrator, index) in administrators: {
    name: '${uniqueString(deployment().name, location)}-postgresql-administrator-${index}'
    params: {
      flexibleServerName: flexibleServer.name
      objectId: administrator.objectId
      principalName: administrator.principalName
      principalType: administrator.principalType
      tenantId: administrator.tenantId
    }
  }
]

resource flexibleServer_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
  for (diagnosticSetting, index) in diagnosticSettings: {
    name: diagnosticSetting.?name ?? (length(diagnosticSettings) > 1 ? '${diagnosticSettingsDerivedName}-${index + 1}' : diagnosticSettingsDerivedName)
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
    scope: flexibleServer
  }
]
output name string = flexibleServer.name
output resourceId string = flexibleServer.id
output resourceGroupName string = resourceGroup().name
output location string = flexibleServer.location
output fqdn string? = flexibleServer.properties.?fullyQualifiedDomainName
output systemAssignedMIPrincipalId string? = flexibleServer.?identity.?principalId
@export()
type administratorType = {
  objectId: string
  principalName: string
  principalType: ('Group' | 'ServicePrincipal' | 'Unknown' | 'User')
  tenantId: string
}

@export()
type databaseType = {
  name: string
  collation: string?
  charset: string?
}

@export()
type configurationType = {
  name: string
  source: string?
  value: string?
}

resource flexibleServer_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${name}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?notes ?? (lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: flexibleServer
}
