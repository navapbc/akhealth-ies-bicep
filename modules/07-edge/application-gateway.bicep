metadata name = 'Network Application Gateways'
metadata description = 'This module deploys a Network Application Gateway.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'
import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

param systemAbbreviation string
param environmentAbbreviation string
param instanceNumber string
param workloadDescription string = ''
param location string = resourceGroup().location

import { managedIdentityOnlySysAssignedType } from '../shared/avm-common-types.bicep'
param managedIdentities managedIdentityOnlySysAssignedType?
param authenticationCertificates resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.authenticationCertificates = []
param autoscaleMaxCapacity int
param autoscaleMinCapacity int
param backendAddressPools resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.backendAddressPools = []
param backendHttpSettingsCollection resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.backendHttpSettingsCollection = []
param customErrorConfigurations resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.customErrorConfigurations = []
param enableFips bool
param enableHttp2 bool
param firewallPolicyResourceId string?
param frontendIPConfigurations resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.frontendIPConfigurations = []
param frontendPorts resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.frontendPorts = []
param gatewayIPConfigurations resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.gatewayIPConfigurations = []
param enableRequestBuffering bool
param enableResponseBuffering bool
param entraJWTValidationConfigs resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.entraJWTValidationConfigs = []
param httpListeners resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.httpListeners = []
param loadDistributionPolicies resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.loadDistributionPolicies = []

import { privateEndpointMultiServiceType } from '../shared/avm-common-types.bicep'
param privateEndpoints privateEndpointMultiServiceType[]?
param privateLinkConfigurations resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.privateLinkConfigurations = []
param probes resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.probes = []
param redirectConfigurations resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.redirectConfigurations = []
param requestRoutingRules resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.requestRoutingRules = []
param rewriteRuleSets resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.rewriteRuleSets = []
@allowed([
  'Basic'
  'Standard_v2'
  'WAF_v2'
])
param sku string
@minValue(0)
@maxValue(125)
param capacity int
param sslCertificates resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.sslCertificates = []
param sslPolicyCipherSuites resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.sslPolicy.cipherSuites = [
  'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384'
  'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'
]

@allowed([
  'TLSv1_0'
  'TLSv1_1'
  'TLSv1_2'
  'TLSv1_3'
])
param sslPolicyMinProtocolVersion string
@allowed([
  'AppGwSslPolicy20150501'
  'AppGwSslPolicy20170401'
  'AppGwSslPolicy20170401S'
  'AppGwSslPolicy20220101'
  'AppGwSslPolicy20220101S'
  ''
])
param sslPolicyName string
@allowed([
  'Custom'
  'CustomV2'
  'Predefined'
])
param sslPolicyType string
param sslProfiles resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.sslProfiles = []
param trustedClientCertificates resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.trustedClientCertificates = []
param trustedRootCertificates resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.trustedRootCertificates = []
param urlPathMaps resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.urlPathMaps = []
@allowed([
  1
  2
  3
])
param availabilityZones int[]

import { diagnosticSettingFullType } from '../shared/avm-common-types.bicep'
param diagnosticSettings diagnosticSettingFullType[]?
var hasSystemAssignedIdentity = managedIdentities.?systemAssigned ?? false
var identity = hasSystemAssignedIdentity
  ? {
      type: 'SystemAssigned'
    }
  : null

import { lockType } from '../shared/avm-common-types.bicep'
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
param roleAssignments roleAssignmentType[]?
param tags resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.tags?
param backendSettingsCollection resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.backendSettingsCollection = []
param listeners resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.listeners = []
param routingRules resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.routingRules = []
var resourceAbbreviation = 'agw'
var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take(
  '${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}',
  80
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

resource applicationGateway 'Microsoft.Network/applicationGateways@2025-05-01' = {
  name: resolvedName
  location: location
  tags: tags
  identity: identity
  properties: union(
    {
      authenticationCertificates: authenticationCertificates
      autoscaleConfiguration: autoscaleMaxCapacity > 0 && autoscaleMinCapacity >= 0
        ? {
            maxCapacity: autoscaleMaxCapacity
            minCapacity: autoscaleMinCapacity
          }
        : null
      backendAddressPools: backendAddressPools
      backendHttpSettingsCollection: backendHttpSettingsCollection
      backendSettingsCollection: backendSettingsCollection
      customErrorConfigurations: customErrorConfigurations
      enableHttp2: enableHttp2
      entraJWTValidationConfigs: entraJWTValidationConfigs
      firewallPolicy: sku == 'WAF_v2' && !empty(firewallPolicyResourceId)
        ? {
            id: firewallPolicyResourceId
          }
        : null
      forceFirewallPolicyAssociation: sku == 'WAF_v2' && !empty(firewallPolicyResourceId)
      frontendIPConfigurations: frontendIPConfigurations
      frontendPorts: frontendPorts
      gatewayIPConfigurations: gatewayIPConfigurations
      globalConfiguration: endsWith(sku, 'v2')
        ? {
            enableRequestBuffering: enableRequestBuffering
            enableResponseBuffering: enableResponseBuffering
          }
        : null
      httpListeners: httpListeners
      loadDistributionPolicies: loadDistributionPolicies
      listeners: listeners
      privateLinkConfigurations: privateLinkConfigurations
      probes: probes
      redirectConfigurations: redirectConfigurations
      requestRoutingRules: requestRoutingRules
      routingRules: routingRules
      rewriteRuleSets: rewriteRuleSets
      sku: {
        name: sku
        tier: sku
        capacity: autoscaleMaxCapacity > 0 && autoscaleMinCapacity >= 0 ? null : capacity
      }
      sslCertificates: sslCertificates
      sslPolicy: sslPolicyType != 'Predefined'
        ? {
            cipherSuites: sslPolicyCipherSuites
            minProtocolVersion: sslPolicyMinProtocolVersion
            policyName: empty(sslPolicyName) ? null : sslPolicyName
            policyType: sslPolicyType
          }
        : {
            policyName: empty(sslPolicyName) ? null : sslPolicyName
            policyType: sslPolicyType
          }
      sslProfiles: sslProfiles
      trustedClientCertificates: trustedClientCertificates
      trustedRootCertificates: trustedRootCertificates
      urlPathMaps: urlPathMaps
    },
    (enableFips
      ? {
          enableFips: enableFips
        }
      : {})
  )
  zones: map(availabilityZones, zone => '${zone}')
}

resource applicationGateway_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
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
    scope: applicationGateway
  }
]
var resolvedApplicationGatewayPrivateEndpoints = [
  for (privateEndpoint, index) in (privateEndpoints ?? []): {
    resourceGroupName: privateEndpoint.resourceGroupName
    resourceGroupSubscriptionId: privateEndpoint.resourceGroupSubscriptionId
    name: privateEndpoint.name
    privateLinkServiceConnectionName: privateEndpoint.privateLinkServiceConnectionName
    isManualConnection: privateEndpoint.?isManualConnection == true
    service: privateEndpoint.service
    subnetResourceId: privateEndpoint.subnetResourceId
    location: privateEndpoint.location
    lock: privateEndpoint.?lock ?? lock
    privateDnsZoneGroup: privateEndpoint.?privateDnsZoneGroup
    roleAssignments: privateEndpoint.?roleAssignments
    tags: privateEndpoint.?tags ?? tags
    customDnsConfigs: privateEndpoint.?customDnsConfigs
    ipConfigurations: privateEndpoint.?ipConfigurations
    applicationSecurityGroupResourceIds: privateEndpoint.?applicationSecurityGroupResourceIds
    customNetworkInterfaceName: privateEndpoint.?customNetworkInterfaceName
    manualConnectionRequestMessage: privateEndpoint.?manualConnectionRequestMessage
  }
]

module applicationGateway_privateEndpoints '../01-network/private-endpoint.bicep' = [
  for (privateEndpoint, index) in resolvedApplicationGatewayPrivateEndpoints: {
    name: '${uniqueString(deployment().name, location)}-applicationGateway-PrEndpoint-${index}'
    scope: resourceGroup(privateEndpoint.resourceGroupSubscriptionId, privateEndpoint.resourceGroupName)
    params: {
      name: privateEndpoint.name
      privateLinkServiceConnections: !privateEndpoint.isManualConnection
        ? [
            {
              name: privateEndpoint.privateLinkServiceConnectionName
              properties: {
                privateLinkServiceId: applicationGateway.id
                groupIds: [
                  privateEndpoint.service
                ]
              }
            }
          ]
        : null
      manualPrivateLinkServiceConnections: privateEndpoint.isManualConnection
        ? [
            {
              name: privateEndpoint.privateLinkServiceConnectionName
              properties: {
                privateLinkServiceId: applicationGateway.id
                groupIds: [
                  privateEndpoint.service
                ]
                requestMessage: privateEndpoint.manualConnectionRequestMessage
              }
            }
          ]
        : null
      subnetResourceId: privateEndpoint.subnetResourceId
      location: privateEndpoint.location
      lock: privateEndpoint.lock
      privateDnsZoneGroup: privateEndpoint.privateDnsZoneGroup
      roleAssignments: privateEndpoint.roleAssignments
      tags: privateEndpoint.tags
      customDnsConfigs: privateEndpoint.customDnsConfigs
      ipConfigurations: privateEndpoint.ipConfigurations
      applicationSecurityGroupResourceIds: privateEndpoint.applicationSecurityGroupResourceIds
      customNetworkInterfaceName: privateEndpoint.customNetworkInterfaceName
    }
  }
]

resource applicationGateway_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(
      applicationGateway.id,
      roleAssignment.principalId,
      roleAssignment.roleDefinitionId
    )
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: applicationGateway
  }
]
output name string = applicationGateway.name
output resourceId string = applicationGateway.id
output resourceGroupName string = resourceGroup().name
output location string = applicationGateway.location
output privateEndpoints privateEndpointOutputType[] = [
  for (pe, index) in resolvedApplicationGatewayPrivateEndpoints: {
    name: applicationGateway_privateEndpoints[index].outputs.name
    resourceId: applicationGateway_privateEndpoints[index].outputs.resourceId
    groupId: applicationGateway_privateEndpoints[index].outputs.?groupId!
    customDnsConfigs: applicationGateway_privateEndpoints[index].outputs.customDnsConfigs
    networkInterfaceResourceIds: applicationGateway_privateEndpoints[index].outputs.networkInterfaceResourceIds
  }
]

// =============== //
//   Definitions   //
// =============== //

@export()
type privateEndpointOutputType = {
  name: string
  resourceId: string
  groupId: string?
  customDnsConfigs: {
    fqdn: string?
    ipAddresses: string[]
  }[]

  networkInterfaceResourceIds: string[]
}

resource applicationGateway_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${resolvedName}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?notes ?? (lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: applicationGateway
}
