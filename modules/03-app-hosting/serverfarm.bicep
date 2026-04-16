metadata name = 'App Service Plan'
metadata description = 'This module deploys an App Service Plan.'

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

param systemAbbreviation string
param environmentAbbreviation string
param instanceNumber string
param workloadDescription string = ''
param location string = resourceGroup().location
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
param skuCapacity int
@allowed([
  'windows'
  'linux'
])
param servicePlanOsFamily string
param workloadKind string
param appServiceEnvironmentResourceId string?
param workerTierName resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.workerTierName?
param perSiteScaling resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.perSiteScaling
param elasticScaleEnabled resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.elasticScaleEnabled
param maximumElasticWorkerCount resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.maximumElasticWorkerCount
param targetWorkerCount resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.targetWorkerCount
@allowed([
  0
  1
  2
])
param targetWorkerSize int
param zoneRedundant resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.zoneRedundant
param virtualNetworkSubnetId string?
param isCustomMode resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.isCustomMode
param rdpEnabled resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.rdpEnabled?
param installScripts resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.installScripts?
param planDefaultIdentity resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.planDefaultIdentity?
param registryAdapters resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.registryAdapters?
param storageMounts resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.properties.storageMounts?

import { managedIdentityOnlySysAssignedType } from '../shared/avm-common-types.bicep'
param managedIdentities managedIdentityOnlySysAssignedType?

import { lockType } from '../shared/avm-common-types.bicep'
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
import { builtInRoleNames } from '../shared/role-definitions.bicep'
param roleAssignments roleAssignmentType[]?
param tags resourceInput<'Microsoft.Web/serverfarms@2025-03-01'>.tags?

import { diagnosticSettingMetricsOnlyType } from '../shared/avm-common-types.bicep'
param diagnosticSettings diagnosticSettingMetricsOnlyType[]?
var resourceAbbreviation = 'asp'
var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take('${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}', 40)
var resolvedName = derivedName
var diagnosticSettingsDerivedName = replace(resolvedName, '${resourceAbbreviation}-', 'dgs${resourceAbbreviation}-')
var hasSystemAssignedIdentity = managedIdentities.?systemAssigned ?? false
var isLinux = servicePlanOsFamily =~ 'linux'
var isWindowsContainer = contains(workloadKind, 'container') && contains(workloadKind, 'windows')
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

// App Service Plan `kind` is intentionally omitted.
// Microsoft states the ASP `kind` value is meaningless at this time and that
// `reserved` is what distinguishes Linux from Windows plans:
// https://azure.github.io/AppService/2021/08/31/Kind-property-overview.html

#disable-next-line use-recent-api-versions // The diagnostic settings API version used is the most recent available at the time of development.
resource appServicePlan_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
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
