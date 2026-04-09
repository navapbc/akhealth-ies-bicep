metadata name = 'Network Application Gateways'
metadata description = 'This module deploys a Network Application Gateway.'

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

@description('Required. System abbreviation used for resource naming.')
param systemAbbreviation string

@description('Required. Environment abbreviation used for resource naming.')
param environmentAbbreviation string

@description('Required. Instance number used for resource naming.')
param instanceNumber string

@description('Optional. Workload description segment used for resource naming.')
param workloadDescription string = ''

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

import { managedIdentityOnlySysAssignedType } from '../shared/avm-common-types.bicep'
@description('Optional. The managed identity definition for this resource.')
param managedIdentities managedIdentityOnlySysAssignedType?

@description('Optional. Authentication certificates of the application gateway resource.')
param authenticationCertificates resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.authenticationCertificates = []

@description('Optional. Upper bound on number of Application Gateway capacity.')
param autoscaleMaxCapacity int

@description('Optional. Lower bound on number of Application Gateway capacity.')
param autoscaleMinCapacity int

@description('Optional. Backend address pool of the application gateway resource.')
param backendAddressPools resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.backendAddressPools = []

@description('Optional. Backend http settings of the application gateway resource.')
param backendHttpSettingsCollection resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.backendHttpSettingsCollection = []

@description('Optional. Custom error configurations of the application gateway resource.')
param customErrorConfigurations resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.customErrorConfigurations = []

@description('Optional. Whether FIPS is enabled on the application gateway resource.')
param enableFips bool

@description('Optional. Whether HTTP2 is enabled on the application gateway resource.')
param enableHttp2 bool

@description('Conditional. The resource ID of an associated firewall policy. Required if the SKU is \'WAF_v2\' and ignored if the SKU is \'Standard_v2\' or \'Basic\'.')
param firewallPolicyResourceId string?

@description('Optional. Frontend IP addresses of the application gateway resource.')
param frontendIPConfigurations resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.frontendIPConfigurations = []

@description('Optional. Frontend ports of the application gateway resource.')
param frontendPorts resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.frontendPorts = []

@description('Optional. Subnets of the application gateway resource.')
param gatewayIPConfigurations resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.gatewayIPConfigurations = []

@description('Optional. Enable request buffering.')
param enableRequestBuffering bool

@description('Optional. Enable response buffering.')
param enableResponseBuffering bool

@description('Optional. Entra JWT validation configurations.')
param entraJWTValidationConfigs resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.entraJWTValidationConfigs = []

@description('Optional. Http listeners of the application gateway resource.')
param httpListeners resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.httpListeners = []

@description('Optional. Load distribution policies of the application gateway resource.')
param loadDistributionPolicies resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.loadDistributionPolicies = []

import { privateEndpointMultiServiceType } from '../shared/avm-common-types.bicep'
@description('Optional. Configuration details for private endpoints. For security reasons, it is recommended to use private endpoints whenever possible.')
param privateEndpoints privateEndpointMultiServiceType[]?

@description('Optional. PrivateLink configurations on application gateway.')
param privateLinkConfigurations resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.privateLinkConfigurations = []

@description('Optional. Probes of the application gateway resource.')
param probes resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.probes = []

@description('Optional. Redirect configurations of the application gateway resource.')
param redirectConfigurations resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.redirectConfigurations = []

@description('Optional. Request routing rules of the application gateway resource.')
param requestRoutingRules resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.requestRoutingRules = []

@description('Optional. Rewrite rules for the application gateway resource.')
param rewriteRuleSets resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.rewriteRuleSets = []

@description('Optional. The name of the SKU for the Application Gateway.')
@allowed([
  'Basic'
  'Standard_v2'
  'WAF_v2'
])
param sku string

@description('Optional. The number of Application instances to be configured.')
@minValue(0)
@maxValue(125)
param capacity int

@description('Optional. SSL certificates of the application gateway resource.')
param sslCertificates resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.sslCertificates = []

@description('Optional. Ssl cipher suites to be enabled in the specified order to application gateway.')
param sslPolicyCipherSuites resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.sslPolicy.cipherSuites = [
  'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384'
  'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'
]

@description('Optional. Ssl protocol enums.')
@allowed([
  'TLSv1_0'
  'TLSv1_1'
  'TLSv1_2'
  'TLSv1_3'
])
param sslPolicyMinProtocolVersion string

@description('Optional. Ssl predefined policy name enums.')
@allowed([
  'AppGwSslPolicy20150501'
  'AppGwSslPolicy20170401'
  'AppGwSslPolicy20170401S'
  'AppGwSslPolicy20220101'
  'AppGwSslPolicy20220101S'
  ''
])
param sslPolicyName string

@description('Optional. Type of Ssl Policy.')
@allowed([
  'Custom'
  'CustomV2'
  'Predefined'
])
param sslPolicyType string

@description('Optional. SSL profiles of the application gateway resource.')
param sslProfiles resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.sslProfiles = []

@description('Optional. Trusted client certificates of the application gateway resource.')
param trustedClientCertificates resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.trustedClientCertificates = []

@description('Optional. Trusted Root certificates of the application gateway resource.')
param trustedRootCertificates resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.trustedRootCertificates = []

@description('Optional. URL path map of the application gateway resource.')
param urlPathMaps resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.urlPathMaps = []

@description('Optional. The list of Availability zones to use for the zone-redundant resources.')
@allowed([
  1
  2
  3
])
param availabilityZones int[]

import { diagnosticSettingFullType } from '../shared/avm-common-types.bicep'
@description('Optional. The diagnostic settings of the service.')
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
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

@description('Optional. Resource tags.')
param tags resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.tags?

@description('Optional. Backend settings of the application gateway resource. For default limits, see [Application Gateway limits](https://learn.microsoft.com/en-us/azure/azure-subscription-service-limits#application-gateway-limits).')
param backendSettingsCollection resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.backendSettingsCollection = []

@description('Optional. Listeners of the application gateway resource. For default limits, see [Application Gateway limits](https://learn.microsoft.com/en-us/azure/azure-subscription-service-limits#application-gateway-limits).')
param listeners resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.listeners = []

@description('Optional. Routing rules of the application gateway resource.')
param routingRules resourceInput<'Microsoft.Network/applicationGateways@2025-05-01'>.properties.routingRules = []

var resourceAbbreviation = 'agw'
var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take(
  '${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}',
  80
)
var resolvedName = derivedName

var builtInRoleNames = {
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Network Contributor': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '4d97b98b-1d4f-4787-a291-c67834d212e7'
  )
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

@description('The private endpoints of the resource.')
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
@description('The type for the private endpoint output.')
type privateEndpointOutputType = {
  @description('The name of the private endpoint.')
  name: string

  @description('The resource ID of the private endpoint.')
  resourceId: string

  @description('The group Id for the private endpoint Group.')
  groupId: string?

  @description('The custom DNS configurations of the private endpoint.')
  customDnsConfigs: {
    @description('FQDN that resolves to private endpoint IP address.')
    fqdn: string?

    @description('A list of private IP addresses of the private endpoint.')
    ipAddresses: string[]
  }[]

  @description('The IDs of the network interfaces associated with the private endpoint.')
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
