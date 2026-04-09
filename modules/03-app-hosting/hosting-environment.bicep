metadata name = 'App Service Environments'
metadata description = 'This module deploys an App Service Environment.'

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

@description('Required. System abbreviation used for resource naming.')
param systemAbbreviation string

@description('Required. Environment abbreviation used for resource naming.')
param environmentAbbreviation string

@description('Required. Instance number used for resource naming.')
param instanceNumber string

@description('Optional. Workload description segment used for resource naming.')
param workloadDescription string = ''

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location


@description('Optional. Tags of the resource.')
param tags resourceInput<'Microsoft.Web/hostingEnvironments@2025-03-01'>.tags?

import { lockType } from '../shared/avm-common-types.bicep'
@description('Optional. The lock settings of the service.')
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

@allowed([
  'ASEv3'
])
@description('Optional. Kind of resource.')
param kind string = 'ASEv3'

@description('Optional. Custom settings for changing the behavior of the App Service Environment.')
param clusterSettings resourceInput<'Microsoft.Web/hostingEnvironments@2025-03-01'>.properties.clusterSettings

@description('Optional. Enable the default custom domain suffix to use for all sites deployed on the ASE. If provided, then customDnsSuffixCertificateUrl is required.')
param customDnsSuffix string?

@description('Optional. The URL referencing the Azure Key Vault certificate secret that should be used as the default SSL/TLS certificate for sites with the custom domain suffix. Required if customDnsSuffix is not empty.')
param customDnsSuffixCertificateUrl string?

@description('Optional. The Dedicated Host Count. If `zoneRedundant` is false, and you want physical hardware isolation enabled, set to 2. Otherwise 0.')
param dedicatedHostCount int?

@description('Optional. DNS suffix of the App Service Environment.')
param dnsSuffix string?

@description('Optional. Scale factor for frontends.')
param frontEndScaleFactor int

@description('Optional. Specifies which endpoints to serve internally in the Virtual Network for the App Service Environment. - None, Web, Publishing, Web,Publishing. "None" Exposes the ASE-hosted apps on an internet-accessible IP address.')
param internalLoadBalancingMode resourceInput<'Microsoft.Web/hostingEnvironments@2025-03-01'>.properties.internalLoadBalancingMode

@description('Optional. Properties to configure additional networking features.')
param networkConfiguration resourceInput<'Microsoft.Web/hostingEnvironments@2025-03-01'>.properties.networkingConfiguration?

@description('Optional. Specify preference for when and how the planned maintenance is applied.')
param upgradePreference resourceInput<'Microsoft.Web/hostingEnvironments@2025-03-01'>.properties.upgradePreference

@description('Required. ResourceId for the subnet.')
param subnetResourceId string

@description('Required. Name of the subnet.')
param subnetName string

@description('Optional. Switch to make the App Service Environment zone redundant. If enabled, the minimum App Service plan instance count will be three, otherwise 1. If enabled, the `dedicatedHostCount` must be set to `-1`.')
param zoneRedundant bool

@description('Optional. Number of IP SSL addresses reserved for the App Service Environment.')
param ipsslAddressCount int?

@description('Optional. Front-end VM size, e.g. "Medium", "Large".')
param multiSize string?

import { diagnosticSettingLogsOnlyType } from '../shared/avm-common-types.bicep'
@description('Optional. The diagnostic settings of the service.')
param diagnosticSettings diagnosticSettingLogsOnlyType[]?

var resourceAbbreviation = 'ase'
var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take(
  '${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}',
  60
)
var resolvedName = derivedName
var resolvedDedicatedHostCount = dedicatedHostCount != 0 ? dedicatedHostCount : null
var resolvedDnsSuffix = !empty(dnsSuffix) ? dnsSuffix : null

var builtInRoleNames = {
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Role Based Access Control Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'f58310d9-a9f6-439a-9e8d-f62e7b41a168'
  )
  'User Access Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
  )
}

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

#disable-next-line use-recent-api-versions // This is the most recent API version at the time of development.
resource appServiceEnvironment_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
  for (diagnosticSetting, index) in (diagnosticSettings ?? []): {
    name: diagnosticSetting.?name ?? '${resolvedName}-diagnosticSettings'
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

@description('The resource ID of the App Service Environment.')
output resourceId string = appServiceEnvironment.id

@description('The resource group the App Service Environment was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The name of the App Service Environment.')
output name string = appServiceEnvironment.name

@description('The location the resource was deployed into.')
output location string = appServiceEnvironment.location
