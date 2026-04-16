metadata name = 'Application Insights'
metadata description = 'This component deploys an Application Insights instance.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'
import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

param systemAbbreviation string
param environmentAbbreviation string
param instanceNumber string
param workloadDescription string = ''
@allowed([
  'web'
  'other'
])
param applicationType string
param workspaceResourceId string
param disableIpMasking bool
param disableLocalAuth bool
param forceCustomerStorageForProfiler bool
param linkedStorageAccountResourceId string?
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccessForIngestion string
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccessForQuery string
@allowed([
  30
  60
  90
  120
  180
  270
  365
  550
  730
])
param retentionInDays int
@minValue(0)
@maxValue(100)
param samplingPercentage int
param flowType string?
param requestSource string?
param kind string
param immediatePurgeDataOn30Days bool?
@allowed([
  'ApplicationInsights'
  'ApplicationInsightsWithDiagnosticSettings'
  'LogAnalytics'
])
param ingestionMode string?
param location string = resourceGroup().location

import { lockType } from '../shared/avm-common-types.bicep'
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
param roleAssignments roleAssignmentType[]?
param tags resourceInput<'Microsoft.Insights/components@2020-02-02'>.tags?

import { diagnosticSettingFullType } from '../shared/avm-common-types.bicep'
param diagnosticSettings diagnosticSettingFullType[]?
var resourceAbbreviation = 'appi'
var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take(
  '${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}',
  260
)
var resolvedName = derivedName
var diagnosticSettingsDerivedName = replace(resolvedName, '${resourceAbbreviation}-', 'dgs${resourceAbbreviation}-')
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
var linkedStorageAccountId = linkedStorageAccountResourceId ?? ''
var resolvedDiagnosticSettings = diagnosticSettings ?? []
var defaultMetricCategories = [
  {
    category: 'AllMetrics'
  }
]
var defaultLogCategoriesAndGroups = [
  {
    categoryGroup: 'allLogs'
  }
]

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: resolvedName
  location: location
  tags: tags
  kind: kind
  properties: {
    Application_Type: applicationType
    DisableIpMasking: disableIpMasking
    DisableLocalAuth: disableLocalAuth
    ForceCustomerStorageForProfiler: forceCustomerStorageForProfiler
    WorkspaceResourceId: workspaceResourceId
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
    RetentionInDays: retentionInDays
    SamplingPercentage: samplingPercentage
    Flow_Type: flowType
    Request_Source: requestSource
    ImmediatePurgeDataOn30Days: immediatePurgeDataOn30Days
    IngestionMode: ingestionMode
  }
}

module linkedStorageAccount './application-insights-linked-storage-account.bicep' = if (!empty(linkedStorageAccountId)) {
  name: '${uniqueString(deployment().name, location)}-appInsights-linkedStorageAccount'
  params: {
    appInsightsName: appInsights.name
    storageAccountResourceId: linkedStorageAccountId
  }
}

resource appInsights_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(appInsights.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: appInsights
  }
]

resource appInsights_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
  for (diagnosticSetting, index) in resolvedDiagnosticSettings: {
    name: diagnosticSetting.?name ?? (length(resolvedDiagnosticSettings) > 1 ? '${diagnosticSettingsDerivedName}-${index + 1}' : diagnosticSettingsDerivedName)
    properties: {
      storageAccountId: diagnosticSetting.?storageAccountResourceId
      workspaceId: diagnosticSetting.?workspaceResourceId
      eventHubAuthorizationRuleId: diagnosticSetting.?eventHubAuthorizationRuleResourceId
      eventHubName: diagnosticSetting.?eventHubName
      metrics: [
        for group in (diagnosticSetting.?metricCategories ?? defaultMetricCategories): {
          category: group.category
          enabled: group.?enabled ?? true
          timeGrain: null
        }
      ]
      logs: [
        for group in (diagnosticSetting.?logCategoriesAndGroups ?? defaultLogCategoriesAndGroups): {
          categoryGroup: group.?categoryGroup
          category: group.?category
          enabled: group.?enabled ?? true
        }
      ]
      marketplacePartnerId: diagnosticSetting.?marketplacePartnerResourceId
      logAnalyticsDestinationType: diagnosticSetting.?logAnalyticsDestinationType
    }
    scope: appInsights
  }
]
output name string = appInsights.name
output resourceId string = appInsights.id
output resourceGroupName string = resourceGroup().name
output applicationId string = appInsights.properties.AppId
output location string = appInsights.location
output instrumentationKey string = appInsights.properties.InstrumentationKey
output connectionString string = appInsights.properties.ConnectionString

resource appInsights_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${resolvedName}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?notes ?? (lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: appInsights
}
