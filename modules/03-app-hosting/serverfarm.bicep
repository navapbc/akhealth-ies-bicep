metadata name = 'App Service Plan'
metadata description = 'This module deploys an App Service Plan.'

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

@description('Required. Abbreviation for the owning system.')
param systemAbbreviation string

@description('Required. Abbreviation for the lifecycle environment.')
param environmentAbbreviation string

@description('Required. Instance number used for deterministic naming.')
param instanceNumber string

@description('Optional. Workload descriptor to include in names when it adds value. When empty, the segment is omitted.')
param workloadDescription string = ''

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. The name of the SKU will determine the tier, size, family of the App Service Plan.')
@metadata({
  example: '''
  'F1'
  'B1'
  'P1v3'
  'I1v2'
  'FC1'
  '''
})
param skuName string

@description('Required. Number of workers associated with the App Service Plan.')
param skuCapacity int

@description('Required. Operating system family for the plan.')
@allowed([
  'windows'
  'linux'
])
param servicePlanKind string

@description('Required. App workload kind used to determine plan-specific hosting behavior.')
param workloadKind string

@description('Optional. The Resource ID of the App Service Environment to use for the App Service Plan.')
param appServiceEnvironmentResourceId string?

@description('Optional. Target worker tier assigned to the App Service plan.')
param workerTierName resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.workerTierName?

@description('Optional. If true, apps assigned to this App Service plan can be scaled independently. If false, apps assigned to this App Service plan will scale to all instances of the plan.')
param perSiteScaling resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.perSiteScaling

@description('Optional. Enable/Disable ElasticScaleEnabled App Service Plan.')
param elasticScaleEnabled resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.elasticScaleEnabled

@description('Optional. Maximum number of total workers allowed for this ElasticScaleEnabled App Service Plan.')
param maximumElasticWorkerCount resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.maximumElasticWorkerCount

@description('Optional. Scaling worker count.')
param targetWorkerCount resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.targetWorkerCount

@description('Optional. The instance size of the hosting plan (small, medium, or large).')
@allowed([
  0
  1
  2
])
param targetWorkerSize int

@description('Optional. Zone Redundant server farms can only be used on Premium or ElasticPremium SKU tiers within ZRS Supported regions (https://learn.microsoft.com/en-us/azure/storage/common/redundancy-regions-zrs).')
param zoneRedundant resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.zoneRedundant

@description('Optional. The resource ID of the subnet to integrate the App Service Plan with for VNet integration.')
param virtualNetworkSubnetId string?

@description('Optional. Set to true to enable Managed Instance custom mode. Required for App Service Managed Instance plans.')
param isCustomMode resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.isCustomMode

@description('Optional. Whether RDP is enabled for Managed Instance plans. Only applicable when isCustomMode is true. Requires a Bastion host deployed in the VNet.')
param rdpEnabled resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.rdpEnabled?

@description('Optional. A list of install scripts for Managed Instance plans. Only applicable when isCustomMode is true.')
param installScripts resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.installScripts?

@description('Optional. The default identity configuration for Managed Instance plans. Only applicable when isCustomMode is true.')
param planDefaultIdentity resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.planDefaultIdentity?

@description('Optional. A list of registry adapters for Managed Instance plans. Only applicable when isCustomMode is true.')
param registryAdapters resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.registryAdapters?

@description('Optional. A list of storage mounts for Managed Instance plans. Only applicable when isCustomMode is true.')
param storageMounts resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.storageMounts?

import { managedIdentityOnlySysAssignedType } from '../shared/avm-common-types.bicep'
@description('Optional. The managed identity definition for this resource.')
param managedIdentities managedIdentityOnlySysAssignedType?

import { lockType } from '../shared/avm-common-types.bicep'
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
import { builtInRoleNames } from '../shared/role-definitions.bicep'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

param tags resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.tags?

import { diagnosticSettingMetricsOnlyType } from '../shared/avm-common-types.bicep'
@description('Optional. The diagnostic settings of the service.')
param diagnosticSettings diagnosticSettingMetricsOnlyType[]?

var resourceAbbreviation = 'asp'
var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take('${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}', 40)
var resolvedName = derivedName
var hasSystemAssignedIdentity = managedIdentities.?systemAssigned ?? false
var isLinux = servicePlanKind =~ 'linux'
var isWindowsContainer = contains(workloadKind, 'container') && contains(workloadKind, 'windows')
var planKind = isLinux ? 'Linux' : 'Windows'
var identity = hasSystemAssignedIdentity
  ? {
      type: 'SystemAssigned'
    }
  : null

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

var planNetwork = virtualNetworkSubnetId != null
  ? {
      virtualNetworkSubnetId: virtualNetworkSubnetId
    }
  : null
var customModeRdpEnabled = isCustomMode ? rdpEnabled : null
var customModeInstallScripts = isCustomMode ? installScripts : null
var customModePlanDefaultIdentity = isCustomMode ? planDefaultIdentity : null
var customModeRegistryAdapters = isCustomMode ? registryAdapters : null
var customModeStorageMounts = isCustomMode ? storageMounts : null

resource appServicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: resolvedName
  kind: planKind
  location: location
  tags: tags
  identity: identity
  sku: skuName == 'FC1'
    ? {
        name: skuName
        tier: 'FlexConsumption'
      }
    : {
        name: skuName
        capacity: skuCapacity
      }
  properties: {
    workerTierName: workerTierName
    hostingEnvironmentProfile: appServiceEnvironmentResourceId != null
      ? {
          id: appServiceEnvironmentResourceId
        }
      : null
    perSiteScaling: perSiteScaling
    maximumElasticWorkerCount: maximumElasticWorkerCount
    elasticScaleEnabled: elasticScaleEnabled
    reserved: isLinux
    targetWorkerCount: targetWorkerCount
    targetWorkerSizeId: targetWorkerSize
    zoneRedundant: zoneRedundant
    hyperV: isWindowsContainer
    isCustomMode: isCustomMode
    network: planNetwork
    rdpEnabled: customModeRdpEnabled
    installScripts: customModeInstallScripts
    planDefaultIdentity: customModePlanDefaultIdentity
    registryAdapters: customModeRegistryAdapters
    storageMounts: customModeStorageMounts
  }
}

#disable-next-line use-recent-api-versions // The diagnostic settings API version used is the most recent available at the time of development.
resource appServicePlan_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
  for (diagnosticSetting, index) in (diagnosticSettings ?? []): {
    name: diagnosticSetting.?name ?? '${resolvedName}-diagnosticSettings'
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
      marketplacePartnerId: diagnosticSetting.?marketplacePartnerResourceId
      logAnalyticsDestinationType: diagnosticSetting.?logAnalyticsDestinationType
    }
    scope: appServicePlan
  }
]

resource appServicePlan_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(appServicePlan.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: appServicePlan
  }
]

output resourceGroupName string = resourceGroup().name

output name string = appServicePlan.name

output resourceId string = appServicePlan.id

output location string = appServicePlan.location

@description('The principal ID of the system assigned identity.')
output systemAssignedMIPrincipalId string? = appServicePlan.?identity.?principalId

resource appServicePlan_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${resolvedName}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?notes ?? (lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: appServicePlan
}
