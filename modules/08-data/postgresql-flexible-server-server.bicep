metadata name = 'PostgreSQL Flexible Server'
metadata description = 'Deploys an Azure Database for PostgreSQL Flexible Server for this workload template set.'

import {
  diagnosticSettingFullType
  lockType
  roleAssignmentType
} from '../shared/avm-common-types.bicep'
import { builtInRoleNames } from '../shared/role-definitions.bicep'

@description('Required. The name of the PostgreSQL flexible server.')
param name string

@description('Required. Location for all resources.')
param location string

@description('Required. Azure AD administrators for the server.')
param administrators administratorType[]

@description('Required. Authentication configuration for the server.')
param authConfig resourceInput<'Microsoft.DBforPostgreSQL/flexibleServers@2025-08-01'>.properties.authConfig

@description('Required. The SKU name for the server.')
param skuName string

@allowed([
  'GeneralPurpose'
  'Burstable'
  'MemoryOptimized'
])
@description('Required. The pricing tier for the server.')
param tier string

@allowed([
  -1
  1
  2
  3
])
@description('Required. Availability zone. Use -1 to omit an explicit zone.')
param availabilityZone int

@allowed([
  -1
  1
  2
  3
])
@description('Required. Standby availability zone. Use -1 to omit an explicit standby zone.')
param highAvailabilityZone int

@allowed([
  'Disabled'
  'SameZone'
  'ZoneRedundant'
])
@description('Required. High availability mode.')
param highAvailability string

@minValue(7)
@maxValue(35)
@description('Required. Backup retention days.')
param backupRetentionDays int

@allowed([
  'Disabled'
  'Enabled'
])
@description('Required. Geo-redundant backup setting.')
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
@description('Required. Maximum storage size in GB.')
param storageSizeGB int

@allowed([
  'Disabled'
  'Enabled'
])
@description('Required. Storage autogrow setting.')
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
@description('Required. PostgreSQL engine version.')
param version string

@allowed([
  'Disabled'
  'Enabled'
])
@description('Required. Public network access setting.')
param publicNetworkAccess string

@description('Conditional. Delegated subnet resource ID used for private access.')
param delegatedSubnetResourceId string?

@description('Conditional. Private DNS zone resource ID used for private access.')
param privateDnsZoneArmResourceId string?

@description('Required. Databases to create on the server.')
param databases databaseType[]

@description('Required. Configurations to create on the server.')
param configurations configurationType[]

@description('Optional. Resource lock for the server.')
param lock lockType?

@description('Required. Role assignments to create on the server.')
param roleAssignments roleAssignmentType[]

@description('Required. Diagnostic settings for the server.')
param diagnosticSettings diagnosticSettingFullType[]

@description('Optional. Tags for the server.')
param tags resourceInput<'Microsoft.DBforPostgreSQL/flexibleServers@2025-08-01'>.tags?

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
  for diagnosticSetting in diagnosticSettings: {
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
    scope: flexibleServer
  }
]

@description('The name of the deployed PostgreSQL Flexible server.')
output name string = flexibleServer.name

@description('The resource ID of the deployed PostgreSQL Flexible server.')
output resourceId string = flexibleServer.id

@description('The resource group of the deployed PostgreSQL Flexible server.')
output resourceGroupName string = resourceGroup().name

@description('The location the resource was deployed into.')
output location string = flexibleServer.location

@description('The FQDN of the PostgreSQL Flexible server.')
output fqdn string? = flexibleServer.properties.?fullyQualifiedDomainName

@description('The principal ID of the system-assigned managed identity, when enabled.')
output systemAssignedMIPrincipalId string? = flexibleServer.?identity.?principalId

@export()
type administratorType = {
  @description('Required. The object ID of the Active Directory administrator.')
  objectId: string

  @description('Required. Active Directory administrator principal name.')
  principalName: string

  @description('Required. The principal type used to represent the type of Active Directory administrator.')
  principalType: ('Group' | 'ServicePrincipal' | 'Unknown' | 'User')

  @description('Required. The tenant ID of the Active Directory administrator.')
  tenantId: string
}

@export()
type databaseType = {
  @description('Required. The database name.')
  name: string

  @description('Optional. The collation of the database.')
  collation: string?

  @description('Optional. The charset of the database.')
  charset: string?
}

@export()
type configurationType = {
  @description('Required. The configuration name.')
  name: string

  @description('Optional. The source of the configuration.')
  source: string?

  @description('Optional. The value of the configuration.')
  value: string?
}
