metadata name = 'CDN Profiles'
metadata description = 'This module deploys a CDN Profile.'

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

@allowed([
  'Premium_AzureFrontDoor'
  'Standard_AzureFrontDoor'
  'Standard_Microsoft'
])
@description('Required. The pricing tier (defines a CDN provider, feature list and rate) of the CDN profile.')
param sku string

@description('Optional. Send and receive timeout on forwarding request to the origin.')
param originResponseTimeoutSeconds int = 60

@description('Optional. Endpoint properties (see [ref](https://learn.microsoft.com/en-us/azure/templates/microsoft.cdn/profiles/endpoints?pivots=deployment-language-bicep#endpointproperties) for details).')
param endpoint endpointType?

@description('Optional. Array of secret objects.')
param secrets secretType[]?

@description('Optional. Array of custom domain objects.')
param customDomains customDomainType[]?

@description('Conditional. Array of origin group objects. Required if the afdEndpoints is specified.')
param originGroups originGroupType[]?

@description('Optional. Array of rule set objects.')
param ruleSets ruleSetType[]?

@description('Optional. Array of AFD endpoint objects.')
param afdEndpoints afdEndpointType[]?

@description('Optional. Endpoint tags.')
param tags resourceInput<'Microsoft.Cdn/profiles@2025-06-01'>.tags?

import { managedIdentityOnlySysAssignedType } from '../shared/avm-common-types.bicep'
@description('Optional. The managed identity definition for this resource.')
param managedIdentities managedIdentityOnlySysAssignedType?

import { lockType } from '../shared/avm-common-types.bicep'
@description('Optional. The lock settings of the service.')
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?


import { diagnosticSettingFullType } from '../shared/avm-common-types.bicep'
@description('Optional. The diagnostic settings of the service.')
param diagnosticSettings diagnosticSettingFullType[]?

var resourceAbbreviation = 'afd'
var endpointResourceAbbreviation = 'fde'
var regionAbbreviation = regionAbbreviations[?location] ?? location
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take(
  '${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}',
  260
)
var resolvedName = derivedName
var resolvedOriginGroups = originGroups ?? []
var resolvedAfdEndpoints = [
  for afdEndpoint in (afdEndpoints ?? []): union(afdEndpoint, {
    resolvedName: take(
      '${endpointResourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${afdEndpoint.name}-${instanceNumber}',
      260
    )
  })
]

var builtInRoleNames = {
  'CDN Endpoint Contributor': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '426e0c7f-0c7e-4658-b36f-ff54d6c29b45'
  )
  'CDN Endpoint Reader': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '871e35f6-b5c1-49cc-a043-bde969a0f2cd'
  )
  'CDN Profile Contributor': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'ec156ff8-a8d1-4d15-830c-5b80698ca432'
  )
  'CDN Profile Reader': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '8f96442b-4075-438f-813d-ad51ab4019af'
  )
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

var roleAssignmentsToApply = roleAssignments ?? []
var hasSystemAssignedIdentity = managedIdentities.?systemAssigned ?? false
var formattedRoleAssignments = [
  for (roleAssignment, index) in roleAssignmentsToApply: union(roleAssignment, {
    roleDefinitionId: builtInRoleNames[?roleAssignment.roleDefinitionIdOrName] ?? (contains(
        roleAssignment.roleDefinitionIdOrName,
        '/providers/Microsoft.Authorization/roleDefinitions/'
      )
      ? roleAssignment.roleDefinitionIdOrName
      : subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionIdOrName))
  })
]
var identity = hasSystemAssignedIdentity
  ? {
      type: 'SystemAssigned'
    }
  : null


resource profile 'Microsoft.Cdn/profiles@2025-06-01' = {
  name: resolvedName
  location: location
  identity: identity
  sku: {
    name: sku
  }
  properties: {
    originResponseTimeoutSeconds: originResponseTimeoutSeconds
  }
  tags: tags
}

resource profile_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${resolvedName}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?notes ?? (lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: profile
}

resource profile_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(profile.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: profile
  }
]

resource profile_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
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
    scope: profile
  }
]

module profile_endpoint './front-door-endpoint.bicep' = if (!empty(endpoint)) {
  name: '${uniqueString(deployment().name, location)}-Profile-Endpoint'
  params: {
    profileName: profile.name
    name: endpoint.?name ?? '${profile.name}-endpoint'
    properties: endpoint!.properties
    location: location
    tags: endpoint.?tags ?? tags
  }
}

module profile_secrets './front-door-secret.bicep' = [
  for (secret, index) in (secrets ?? []): {
    name: '${uniqueString(deployment().name)}-Profile-Secret-${index}'
    params: {
      name: secret.name
      profileName: profile.name
      type: secret.type
      secretSourceResourceId: secret.secretSourceResourceId
      subjectAlternativeNames: secret.?subjectAlternativeNames
      useLatestVersion: secret.?useLatestVersion
      secretVersion: secret.?secretVersion
    }
  }
]

module profile_customDomains './front-door-custom-domain.bicep' = [
  for (customDomain, index) in (customDomains ?? []): {
    name: '${uniqueString(deployment().name)}-CustomDomain-${index}'
    dependsOn: [
      profile_secrets
    ]
    params: {
      name: customDomain.name
      profileName: profile.name
      hostName: customDomain.hostName
      azureDnsZoneResourceId: customDomain.?azureDnsZoneResourceId
      extendedProperties: customDomain.?extendedProperties
      certificateType: customDomain.certificateType
      minimumTlsVersion: customDomain.?minimumTlsVersion
      preValidatedCustomDomainResourceId: customDomain.?preValidatedCustomDomainResourceId
      secretName: customDomain.?secretName
      cipherSuiteSetType: customDomain.?cipherSuiteSetType
      customizedCipherSuiteSet: customDomain.?customizedCipherSuiteSet
    }
  }
]

module profile_originGroups './front-door-origin-group.bicep' = [
  for (origingroup, index) in resolvedOriginGroups: {
    name: '${uniqueString(deployment().name)}-Profile-OriginGroup-${index}'
    params: {
      name: origingroup.name
      profileName: profile.name
      authentication: origingroup.?authentication
      loadBalancingSettings: origingroup.loadBalancingSettings
      healthProbeSettings: origingroup.?healthProbeSettings
      sessionAffinityState: origingroup.sessionAffinityState
      trafficRestorationTimeToHealedOrNewEndpointsInMinutes: origingroup.trafficRestorationTimeToHealedOrNewEndpointsInMinutes
      origins: origingroup.origins
    }
  }
]

module profile_ruleSets './front-door-rule-set.bicep' = [
  for (ruleSet, index) in (ruleSets ?? []): {
    name: '${uniqueString(deployment().name)}-Profile-RuleSet-${index}'
    dependsOn: [
      profile_originGroups
    ]
    params: {
      name: ruleSet.name
      profileName: profile.name
      rules: ruleSet.?rules
    }
  }
]

module profile_afdEndpoints './front-door-afd-endpoint.bicep' = [
  for (afdEndpoint, index) in resolvedAfdEndpoints: {
    name: '${uniqueString(deployment().name)}-Profile-AfdEndpoint-${index}'
    dependsOn: [
      profile_originGroups
      profile_customDomains
      profile_ruleSets
    ]
    params: {
      name: afdEndpoint.resolvedName
      location: location
      profileName: profile.name
      autoGeneratedDomainNameLabelScope: afdEndpoint.autoGeneratedDomainNameLabelScope
      enabledState: afdEndpoint.enabledState
      routes: afdEndpoint.?routes
      tags: afdEndpoint.?tags ?? tags
    }
  }
]

@description('The name of the CDN profile.')
output name string = profile.name

@description('The resource ID of the CDN profile.')
output resourceId string = profile.id

@description('The resource group where the CDN profile is deployed.')
output resourceGroupName string = resourceGroup().name

@description('The type of the CDN profile.')
output profileType string = profile.type

@description('The location the resource was deployed into.')
output location string = profile.location

@description('The name of the CDN profile endpoint.')
output endpointName string? = profile_endpoint.?outputs.?name

@description('The resource ID of the CDN profile endpoint.')
output endpointId string? = profile_endpoint.?outputs.?resourceId

@description('The uri of the CDN profile endpoint.')
output uri string? = profile_endpoint.?outputs.?uri

@description('The principal ID of the system assigned identity.')
output systemAssignedMIPrincipalId string? = profile.?identity.?principalId

@description('The list of records required for custom domains validation.')
output dnsValidation dnsValidationOutputType[] = [
  for (customDomain, index) in (customDomains ?? []): profile_customDomains[index].outputs.dnsValidation
]

@description('The list of AFD endpoint host names.')
output frontDoorEndpointHostNames string[] = [
  for (afdEndpoint, index) in resolvedAfdEndpoints: profile_afdEndpoints[index].outputs.frontDoorEndpointHostName
]

@description('The list of AFD endpoint resource IDs.')
output afdEndpointResourceIds string[] = [
  for (afdEndpoint, index) in resolvedAfdEndpoints: profile_afdEndpoints[index].outputs.resourceId
]

@description('The list of AFD endpoint domain associations for Front Door security policy.')
output afdEndpointSecurityPolicyDomains array = [
  for (afdEndpoint, index) in resolvedAfdEndpoints: {
    id: profile_afdEndpoints[index].outputs.resourceId
  }
]

@description('The list of custom domain resource IDs.')
output customDomainResourceIds string[] = [
  for (customDomain, index) in (customDomains ?? []): profile_customDomains[index].outputs.resourceId
]

@description('The list of custom domain associations for Front Door security policy.')
output customDomainSecurityPolicyDomains array = [
  for (customDomain, index) in (customDomains ?? []): {
    id: profile_customDomains[index].outputs.resourceId
  }
]

// =============== //
//   Definitions   //
// =============== //

import { routeType } from './front-door-afd-endpoint.bicep'
import { dnsValidationOutputType } from './front-door-custom-domain.bicep'
import { originType } from './front-door-origin-group.bicep'
import { ruleType } from './front-door-rule-set.bicep'

@export()
@description('The type of the origin group.')
type originGroupType = {
  @description('Required. The name of the origin group.')
  name: string

  @description('Optional. Settings for Origin Authentication.')
  authentication: resourceInput<'Microsoft.Cdn/profiles/originGroups@2025-06-01'>.properties.authentication?

  @description('Optional. Health probe settings to the origin that is used to determine the health of the origin.')
  healthProbeSettings: resourceInput<'Microsoft.Cdn/profiles/originGroups@2025-06-01'>.properties.healthProbeSettings?

  @description('Required. Load balancing settings for a backend pool.')
  loadBalancingSettings: resourceInput<'Microsoft.Cdn/profiles/originGroups@2025-06-01'>.properties.loadBalancingSettings

  @description('Optional. Whether to allow session affinity on this host.')
  sessionAffinityState: 'Enabled' | 'Disabled'

  @description('Optional. Time in minutes to shift the traffic to the endpoint gradually when an unhealthy endpoint comes healthy or a new endpoint is added. Default is 10 mins.')
  trafficRestorationTimeToHealedOrNewEndpointsInMinutes: int

  @description('Required. The list of origins within the origin group.')
  origins: originType[]
}

@export()
@description('The type of the rule set.')
type ruleSetType = {
  @description('Required. Name of the rule set.')
  name: string

  @description('Optional. Array of rules.')
  rules: ruleType[]?
}

@export()
@description('The type of the AFD Endpoint.')
type afdEndpointType = {
  @description('Required. Local endpoint descriptor used to derive the final AFD endpoint resource name.')
  name: string

  @description('Optional. The list of routes for this AFD Endpoint.')
  routes: routeType[]?

  @description('Optional. The tags for the AFD Endpoint.')
  tags: resourceInput<'Microsoft.Cdn/profiles/endpoints@2025-06-01'>.tags?

  @description('Optional. The scope of the auto-generated domain name label.')
  autoGeneratedDomainNameLabelScope: 'NoReuse' | 'ResourceGroupReuse' | 'SubscriptionReuse' | 'TenantReuse'

  @description('Optional. The state of the AFD Endpoint.')
  enabledState: 'Enabled' | 'Disabled'
}

@export()
@description('The type of the custom domain.')
type customDomainType = {
  @description('Required. The name of the custom domain.')
  name: string

  @description('Required. The host name of the custom domain.')
  hostName: string

  @description('Required. The type of the certificate.')
  certificateType: 'AzureFirstPartyManagedCertificate' | 'CustomerCertificate' | 'ManagedCertificate'

  @description('Optional. The resource ID of the Azure DNS zone.')
  azureDnsZoneResourceId: string?

  @description('Optional. The resource ID of the pre-validated custom domain.')
  preValidatedCustomDomainResourceId: string?

  @description('Optional. The name of the secret.')
  secretName: string?

  @description('Optional. The minimum TLS version.')
  minimumTlsVersion: 'TLS10' | 'TLS12' | 'TLS13' | null

  @description('Optional. Extended properties.')
  extendedProperties: resourceInput<'Microsoft.Cdn/profiles/customDomains@2025-06-01'>.properties.extendedProperties?

  @description('Optional. The cipher suite set type that will be used for Https.')
  cipherSuiteSetType: string?

  @description('Optional. The customized cipher suite set that will be used for Https.')
  customizedCipherSuiteSet: resourceInput<'Microsoft.Cdn/profiles/customDomains@2025-06-01'>.properties.tlsSettings.customizedCipherSuiteSet?
}

@export()
@description('The type of and endpoint.')
type endpointType = {
  @description('Required. Name of the endpoint under the profile which is unique globally.')
  name: string

  @description('Required. Endpoint properties (see https://learn.microsoft.com/en-us/azure/templates/microsoft.cdn/profiles/endpoints?pivots=deployment-language-bicep#endpointproperties for details).')
  properties: resourceInput<'microsoft.cdn/profiles/endpoints@2025-04-15'>.properties

  @description('Optional. Endpoint tags.')
  tags: resourceInput<'microsoft.cdn/profiles/endpoints@2025-04-15'>.tags?
}

@export()
@description('The type of a secret.')
type secretType = {
  @description('Required. The name of the secret.')
  name: string

  @description('Optional. The type of the secret.')
  type: ('AzureFirstPartyManagedCertificate' | 'CustomerCertificate' | 'ManagedCertificate' | 'UrlSigningKey')?

  @description('Conditional. The resource ID of the secret source. Required if the `type` is "CustomerCertificate".')
  #disable-next-line secure-secrets-in-params
  secretSourceResourceId: string?

  @description('Optional. The version of the secret.')
  secretVersion: string?

  @description('Optional. The subject alternative names of the secret.')
  subjectAlternativeNames: string[]?

  @description('Optional. Indicates whether to use the latest version of the secret.')
  useLatestVersion: bool?
}
