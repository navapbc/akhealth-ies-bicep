metadata name = 'CDN Profiles'
metadata description = 'This module deploys a CDN Profile.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'
import { regionAbbreviations } from '../shared/region-abbreviations.bicep'
import { frontDoorConfigType } from '../shared/shared.types.bicep'

param systemAbbreviation string
param environmentAbbreviation string
param instanceNumber string
param workloadDescription string = ''
param config frontDoorConfigType
param workloadOriginHostName string
param workloadOriginResourceId string
param workloadOriginLocation string
param tags resourceInput<'Microsoft.Cdn/profiles@2025-06-01'>.tags?
var resourceAbbreviation = 'afd'
var endpointResourceAbbreviation = 'fde'
var resourceLocation = 'global'
var regionAbbreviation = regionAbbreviations[resourceLocation]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take(
  '${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}',
  260
)
var resolvedName = derivedName
var diagnosticSettingsDerivedName = replace(resolvedName, '${resourceAbbreviation}-', 'dgs${resourceAbbreviation}-')
var resolvedOriginGroups = [
  for originGroup in config.originGroups: {
    name: originGroup.name
    authentication: originGroup.?authentication
    healthProbeSettings: originGroup.?healthProbeSettings
    loadBalancingSettings: originGroup.loadBalancingSettings
    sessionAffinityState: originGroup.sessionAffinityState
    trafficRestorationTimeToHealedOrNewEndpointsInMinutes: originGroup.trafficRestorationTimeToHealedOrNewEndpointsInMinutes
    origins: map(originGroup.origins, origin => {
        name: origin.name
        hostName: workloadOriginHostName
        httpPort: origin.httpPort
        httpsPort: origin.httpsPort
        priority: origin.priority
        weight: origin.weight
        enabledState: origin.enabledState
        enforceCertificateNameCheck: origin.enforceCertificateNameCheck
        originHostHeader: workloadOriginHostName
        sharedPrivateLinkResource: origin.?sharedPrivateLink != null
          ? {
              privateLink: {
                id: workloadOriginResourceId
              }
              privateLinkLocation: workloadOriginLocation
              requestMessage: origin.?sharedPrivateLink.?requestMessage
              groupId: origin.?sharedPrivateLink.?groupId
            }
          : null
      })
  }
]
var resolvedAfdEndpoints = [
  for afdEndpoint in config.afdEndpoints: union(afdEndpoint, {
    resolvedName: take(
      '${endpointResourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${afdEndpoint.name}-${instanceNumber}',
      260
    )
  })
]
var roleAssignmentsToApply = config.roleAssignments
var hasSystemAssignedIdentity = config.managedIdentities.?systemAssigned ?? false
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
  location: resourceLocation
  identity: identity
  sku: {
    name: config.sku
  }
  properties: {
    originResponseTimeoutSeconds: config.originResponseTimeoutSeconds
  }
  tags: tags
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
  for (diagnosticSetting, index) in (config.diagnosticSettings ?? []): {
    name: diagnosticSetting.?name ?? (length(config.diagnosticSettings ?? []) > 1 ? '${diagnosticSettingsDerivedName}-${index + 1}' : diagnosticSettingsDerivedName)
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

module profile_secrets './front-door-secret.bicep' = [
  for (secret, index) in (config.secrets ?? []): {
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
  for (customDomain, index) in (config.customDomains ?? []): {
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
  for (ruleSet, index) in (config.ruleSets ?? []): {
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
      profileName: profile.name
      autoGeneratedDomainNameLabelScope: afdEndpoint.autoGeneratedDomainNameLabelScope
      enabledState: afdEndpoint.enabledState
      routes: afdEndpoint.?routes
      tags: afdEndpoint.?tags ?? tags
    }
  }
]
output name string = profile.name
output resourceId string = profile.id
output resourceGroupName string = resourceGroup().name
output profileType string = profile.type
output location string = profile.location
output systemAssignedMIPrincipalId string? = profile.?identity.?principalId
output dnsValidation dnsValidationOutputType[] = [
  for (customDomain, index) in (config.customDomains ?? []): profile_customDomains[index].outputs.dnsValidation
]
output frontDoorEndpointHostNames string[] = [
  for (afdEndpoint, index) in resolvedAfdEndpoints: profile_afdEndpoints[index].outputs.frontDoorEndpointHostName
]
output afdEndpointResourceIds string[] = [
  for (afdEndpoint, index) in resolvedAfdEndpoints: profile_afdEndpoints[index].outputs.resourceId
]
var afdEndpointsWithDefaultDomainLinks = [
  for afdEndpoint in resolvedAfdEndpoints: contains(
    map((afdEndpoint.routes ?? []), route => route.linkToDefaultDomain),
    'Enabled'
  )
]
var afdDefaultLinkedSecurityPolicyDomainIndexes = filter(
  range(0, length(resolvedAfdEndpoints)),
  index => afdEndpointsWithDefaultDomainLinks[index]
)

output customDomainResourceIds string[] = [
  for (customDomain, index) in (config.customDomains ?? []): profile_customDomains[index].outputs.resourceId
]
output customDomainSecurityPolicyDomains array = [
  for (customDomain, index) in (config.customDomains ?? []): {
    id: profile_customDomains[index].outputs.resourceId
  }
]
output afdDefaultLinkedSecurityPolicyDomains array = [
  for index in afdDefaultLinkedSecurityPolicyDomainIndexes: {
    id: profile_afdEndpoints[index].outputs.resourceId
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
type originGroupType = {
  name: string
  authentication: resourceInput<'Microsoft.Cdn/profiles/originGroups@2025-06-01'>.properties.authentication?
  healthProbeSettings: resourceInput<'Microsoft.Cdn/profiles/originGroups@2025-06-01'>.properties.healthProbeSettings?
  loadBalancingSettings: resourceInput<'Microsoft.Cdn/profiles/originGroups@2025-06-01'>.properties.loadBalancingSettings
  sessionAffinityState: 'Enabled' | 'Disabled'
  trafficRestorationTimeToHealedOrNewEndpointsInMinutes: int
  origins: originType[]
}

@export()
type ruleSetType = {
  name: string
  rules: ruleType[]?
}

@export()
type afdEndpointType = {
  name: string
  routes: routeType[]?
  tags: resourceInput<'Microsoft.Cdn/profiles/afdEndpoints@2025-06-01'>.tags?
  autoGeneratedDomainNameLabelScope: 'NoReuse' | 'ResourceGroupReuse' | 'SubscriptionReuse' | 'TenantReuse'
  enabledState: 'Enabled' | 'Disabled'
}

@export()
type customDomainType = {
  name: string
  hostName: string
  certificateType: 'AzureFirstPartyManagedCertificate' | 'CustomerCertificate' | 'ManagedCertificate'
  azureDnsZoneResourceId: string?
  preValidatedCustomDomainResourceId: string?
  secretName: string?
  minimumTlsVersion: 'TLS10' | 'TLS12' | 'TLS13' | null
  extendedProperties: resourceInput<'Microsoft.Cdn/profiles/customDomains@2025-06-01'>.properties.extendedProperties?
  cipherSuiteSetType: string?
  customizedCipherSuiteSet: resourceInput<'Microsoft.Cdn/profiles/customDomains@2025-06-01'>.properties.tlsSettings.customizedCipherSuiteSet?
}

@export()
type secretType = {
  name: string
  type: ('AzureFirstPartyManagedCertificate' | 'CustomerCertificate' | 'ManagedCertificate' | 'UrlSigningKey')?

  #disable-next-line secure-secrets-in-params
  secretSourceResourceId: string?
  secretVersion: string?
  subjectAlternativeNames: string[]?
  useLatestVersion: bool?
}

resource profile_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(config.?lock ?? {}) && config.?lock.?kind != 'None') {
  name: config.?lock.?name ?? 'lock-${resolvedName}'
  properties: {
    level: config.?lock.?kind ?? ''
    notes: config.?lock.?notes ?? (config.?lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: profile
}
