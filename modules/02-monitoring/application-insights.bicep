metadata name = 'Application Insights'
metadata description = 'This component deploys an Application Insights instance.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'
import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

@description('Required. System abbreviation used for resource naming.')
param systemAbbreviation string

@description('Required. Environment abbreviation used for resource naming.')
param environmentAbbreviation string

@description('Required. Instance number used for resource naming.')
param instanceNumber string

@description('Optional. Workload description segment used for resource naming.')
param workloadDescription string = ''

@description('Optional. Application type.')
@allowed([
  'web'
  'other'
])
param applicationType string

@description('Required. Resource ID of the log analytics workspace which the data will be ingested to. This property is required to create an application with this API version. Applications from older versions will not have this property.')
param workspaceResourceId string

@description('Optional. Disable IP masking. Default value is set to true.')
param disableIpMasking bool

@description('Optional. Disable Non-AAD based Auth. Default value is set to false.')
param disableLocalAuth bool

@description('Optional. Force users to create their own storage account for profiler and debugger.')
param forceCustomerStorageForProfiler bool

@description('Optional. Linked storage account resource ID.')
param linkedStorageAccountResourceId string?

@description('Optional. The network access type for accessing Application Insights ingestion. - Enabled or Disabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccessForIngestion string

@description('Optional. The network access type for accessing Application Insights query. - Enabled or Disabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccessForQuery string

@description('Optional. Retention period in days.')
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

@description('Optional. Percentage of the data produced by the application being monitored that is being sampled for Application Insights telemetry.')
@minValue(0)
@maxValue(100)
param samplingPercentage int

@description('Optional. Used by the Application Insights system to determine what kind of flow this component was created by. This is to be set to \'Bluefield\' when creating/updating a component via the REST API.')
param flowType string?

@description('Optional. Describes what tool created this Application Insights component. Customers using this API should set this to the default \'rest\'.')
param requestSource string?

@description('Optional. The kind of application that this component refers to, used to customize UI. This value is a freeform string, values should typically be one of the following: web, ios, other, store, java, phone.')
param kind string

@description('Optional. Purge data immediately after 30 days.')
param immediatePurgeDataOn30Days bool?

@description('Optional. Indicates the flow of the ingestion.')
@allowed([
  'ApplicationInsights'
  'ApplicationInsightsWithDiagnosticSettings'
  'LogAnalytics'
])
param ingestionMode string?

@description('Optional. Disable Azure\'s default smart-detection role email notifications that otherwise create an unmanaged "Application Insights Smart Detection" action group.')
param disableDefaultSmartDetectionRoleEmails bool = true

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

import { lockType } from '../shared/avm-common-types.bicep'
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

param tags resourceInput<'Microsoft.Insights/components@2020-02-02'>.tags?


import { diagnosticSettingFullType } from '../shared/avm-common-types.bicep'
@description('Optional. The diagnostic settings of the service.')
param diagnosticSettings diagnosticSettingFullType[]?

var resourceAbbreviation = 'appi'
var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take(
  '${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}',
  260
)
var resolvedName = derivedName

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
var emailNotificationProactiveDetectionRuleNames = [
  'slowpageloadtime'
  'slowserverresponsetime'
  'longdependencyduration'
  'degradationinserverresponsetime'
  'degradationindependencyduration'
  'digestMailConfiguration'
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

// Azure still provisions new Application Insights components with legacy
// smart detection defaults. These child resources explicitly suppress that
// default role-email behavior so Azure doesn't create an unmanaged
// "Application Insights Smart Detection" action group.
resource appInsights_proactiveDetectionConfigs 'Microsoft.Insights/components/ProactiveDetectionConfigs@2015-05-01' = [
  for ruleName in emailNotificationProactiveDetectionRuleNames: if (disableDefaultSmartDetectionRoleEmails) {
    name: ruleName
    parent: appInsights
    customEmails: []
    enabled: true
    sendEmailsToSubscriptionOwners: false
  }
]

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
    name: diagnosticSetting.?name ?? '${resolvedName}-diagnosticSettings'
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

@description('The application ID of the application insights component.')
output applicationId string = appInsights.properties.AppId

output location string = appInsights.location

@description('Application Insights Instrumentation key. A read-only value that applications can use to identify the destination for all telemetry sent to Azure Application Insights. This value will be supplied upon construction of each new Application Insights component.')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('Application Insights Connection String.')
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
