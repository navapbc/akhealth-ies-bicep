metadata name = 'App Service Environments'
metadata description = 'This module deploys an App Service Environment.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'
import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

param systemAbbreviation string
param environmentAbbreviation string
param instanceNumber string
param workloadDescription string = ''
param location string = resourceGroup().location
param tags resourceInput<'Microsoft.Web/hostingEnvironments@2025-03-01'>.tags?

import { lockType } from '../shared/avm-common-types.bicep'
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
param roleAssignments roleAssignmentType[]?
@allowed([
  'ASEv3'
])
param kind string = 'ASEv3'
param clusterSettings resourceInput<'Microsoft.Web/hostingEnvironments@2025-03-01'>.properties.clusterSettings
param customDnsSuffix string?
param customDnsSuffixCertificateUrl string?
param dedicatedHostCount int?
param dnsSuffix string?
param frontEndScaleFactor int
param internalLoadBalancingMode resourceInput<'Microsoft.Web/hostingEnvironments@2025-03-01'>.properties.internalLoadBalancingMode
param networkConfiguration resourceInput<'Microsoft.Web/hostingEnvironments@2025-03-01'>.properties.networkingConfiguration?
param upgradePreference resourceInput<'Microsoft.Web/hostingEnvironments@2025-03-01'>.properties.upgradePreference
param subnetResourceId string
param subnetName string
param zoneRedundant bool
param ipsslAddressCount int?
param multiSize string?

import { diagnosticSettingLogsOnlyType } from '../shared/avm-common-types.bicep'
param diagnosticSettings diagnosticSettingLogsOnlyType[]?
var resourceAbbreviation = 'ase'
var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take(
  '${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}',
  60
)
var resolvedName = derivedName
var diagnosticSettingsDerivedName = replace(resolvedName, '${resourceAbbreviation}-', 'dgs${resourceAbbreviation}-')
var resolvedDedicatedHostCount = dedicatedHostCount != 0 ? dedicatedHostCount : null
var resolvedDnsSuffix = !empty(dnsSuffix) ? dnsSuffix : null
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

// ============== //
// Resources      //
// ============== //

resource appServiceEnvironment 'Microsoft.Web/hostingEnvironments@2025-03-01' = {
  name: resolvedName
  kind: kind
  location: location
  tags: tags
  properties: {
    clusterSettings: clusterSettings
    dedicatedHostCount: resolvedDedicatedHostCount
    dnsSuffix: resolvedDnsSuffix
    frontEndScaleFactor: frontEndScaleFactor
    internalLoadBalancingMode: internalLoadBalancingMode
    ipsslAddressCount: ipsslAddressCount
    multiSize: multiSize
    upgradePreference: upgradePreference
    networkingConfiguration: networkConfiguration
    virtualNetwork: {
      id: subnetResourceId
      subnet: subnetName
    }
    zoneRedundant: zoneRedundant
  }
}

module appServiceEnvironment_configurations_customDnsSuffix './hosting-environment-custom-dns-suffix.bicep' = if (!empty(customDnsSuffix ?? '')) {
  name: '${uniqueString(deployment().name, location)}-AppServiceEnv-Configurations-CustomDnsSuffix'
  params: {
    hostingEnvironmentName: appServiceEnvironment.name
    certificateUrl: !empty(customDnsSuffixCertificateUrl ?? '')
      ? customDnsSuffixCertificateUrl!
      : fail('When customDnsSuffix is set, customDnsSuffixCertificateUrl is required.')
    dnsSuffix: customDnsSuffix!
  }
}

#disable-next-line use-recent-api-versions // This is the most recent API version at the time of development.
resource appServiceEnvironment_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
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
    scope: appServiceEnvironment
  }
]

resource appServiceEnvironment_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(
      appServiceEnvironment.id,
      roleAssignment.principalId,
      roleAssignment.roleDefinitionId
    )
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condition is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: appServiceEnvironment
  }
]
// ============ //
// Outputs      //
// ============ //

output resourceId string = appServiceEnvironment.id
output resourceGroupName string = resourceGroup().name
output name string = appServiceEnvironment.name
output location string = appServiceEnvironment.location

resource appServiceEnvironment_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${resolvedName}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?notes ?? (lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: appServiceEnvironment
}
