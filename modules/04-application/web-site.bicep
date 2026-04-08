metadata name = 'Web/Function Apps'
metadata description = 'This module deploys a Web or Function App.'

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

@description('Required. Abbreviation for the owning system.')
param systemAbbreviation string

@description('Required. Abbreviation for the lifecycle environment.')
param environmentAbbreviation string

@description('Required. Instance number used for deterministic naming.')
param instanceNumber string

@description('Optional. Workload descriptor to include in names when it adds value. When empty, the segment is omitted.')
param workloadDescription string = ''

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

@description('Required. Type of site to deploy.')
@allowed([
  'functionapp' // function app windows os
  'functionapp,linux' // function app linux os
  'functionapp,workflowapp' // logic app workflow
  'functionapp,workflowapp,linux' // logic app docker container
  'functionapp,linux,container' // function app linux container
  'functionapp,linux,container,azurecontainerapps' // function app linux container azure container apps
  'app,linux' // linux web app
  'app' // windows web app
  'linux,api' // linux api app
  'api' // windows api app
  'app,linux,container' // linux container app
  'app,container,windows' // windows container app
])
param kind string

@description('Required. The resource ID of the app service plan to use for the site. Set as empty string when using a managed environment id for container apps.')
param serverFarmResourceId string

@description('Optional. Azure Resource Manager ID of the customers selected Managed Environment on which to host this app.')
param managedEnvironmentResourceId string?

@description('Optional. Configures a site to accept only HTTPS requests. Issues redirect for HTTP requests.')
param httpsOnly bool

@description('Optional. If client affinity is enabled.')
param clientAffinityEnabled bool

@description('Optional. To enable client affinity; false to stop sending session affinity cookies, which route client requests in the same session to the same instance. Default is true.')
param clientAffinityProxyEnabled bool

@description('Optional. To enable client affinity partitioning using CHIPS cookies, this will add the partitioned property to the affinity cookies; false to stop sending partitioned affinity cookies. Default is false.')
param clientAffinityPartitioningEnabled bool

@description('Optional. The resource ID of the app service environment to use for this resource.')
param appServiceEnvironmentResourceId string?

import { managedIdentityOnlySysAssignedType } from '../shared/avm-common-types.bicep'
@description('Optional. The managed identity definition for this resource.')
param managedIdentities managedIdentityOnlySysAssignedType?

@description('Optional. The resource ID of the assigned identity to be used to access a key vault with.')
param keyVaultAccessIdentityResourceId string?

@description('Optional. Checks if Customer provided storage account is required.')
param storageAccountRequired bool

@description('Optional. Azure Resource Manager ID of the Virtual network and subnet to be joined by Regional VNET Integration. This must be of the form /subscriptions/{subscriptionName}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}.')
param virtualNetworkSubnetResourceId string?

@description('Optional. Stop SCM (KUDU) site when the app is stopped.')
param scmSiteAlsoStopped bool

@description('Optional. The site config object.')
param siteConfig resourceInput<'Microsoft.Web/sites@2025-03-01'>.properties.siteConfig

@description('Optional. The outbound VNET routing configuration for the site.')
param outboundVnetRouting resourceInput<'Microsoft.Web/sites@2025-03-01'>.properties.outboundVnetRouting?

@description('Optional. The web site config.')
param configs configType[]?

@description('Optional. The Function App configuration object.')
param functionAppConfig resourceInput<'Microsoft.Web/sites@2025-03-01'>.properties.functionAppConfig?

@description('Optional. The extensions configuration.')
param extensions extensionType[]?

import {
  lockType
} from '../shared/avm-common-types.bicep'
@description('Optional. The lock settings of the service.')
param lock lockType?
import { virtualNetworkLinkType } from '../shared/shared.types.bicep'

@description('Optional. When true, the module creates the standard private endpoint wiring for the site.')
param enableDefaultPrivateEndpoint bool = false

@description('Optional. Subnet resource ID for the module-owned default private endpoint.')
param defaultPrivateEndpointSubnetResourceId string = ''

@description('Optional. Private DNS zone name for the module-owned default private endpoint.')
param defaultPrivateDnsZoneName string = 'privatelink.azurewebsites.net'

@description('Optional. Virtual network links for the module-owned default private DNS zone.')
param defaultPrivateDnsZoneVirtualNetworkLinks virtualNetworkLinkType[] = []

@description('Optional. Configuration for deployment slots for an app.')
param slots slotType[]?

@description('Optional. Solution-managed Application Insights component used when app settings request the solution deployment path.')
param solutionApplicationInsightsComponent {
  @description('Required. Name of the Application Insights component.')
  name: string

  @description('Required. Resource group name of the Application Insights component.')
  resourceGroupName: string
}?

@description('Optional. Tags of the resource.')
param tags resourceInput<'Microsoft.Web/sites@2025-03-01'>.tags?


import { roleAssignmentType } from '../shared/avm-common-types.bicep'
import { builtInRoleNames } from '../shared/role-definitions.bicep'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

import { diagnosticSettingFullType } from '../shared/avm-common-types.bicep'
@description('Optional. The diagnostic settings of the service.')
param diagnosticSettings diagnosticSettingFullType[]?

@description('Optional. To enable client certificate authentication (TLS mutual authentication).')
param clientCertEnabled bool

@description('Optional. Client certificate authentication comma-separated exclusion paths.')
param clientCertExclusionPaths string?

@description('''
Optional. This composes with ClientCertEnabled setting.
- ClientCertEnabled=false means ClientCert is ignored.
- ClientCertEnabled=true and ClientCertMode=Required means ClientCert is required.
- ClientCertEnabled=true and ClientCertMode=Optional means ClientCert is optional or accepted.
''')
param clientCertMode resourceInput<'Microsoft.Web/sites@2025-03-01'>.properties.clientCertMode?

@description('Optional. If specified during app creation, the app is cloned from a source app.')
param cloningInfo resourceInput<'Microsoft.Web/sites@2025-03-01'>.properties.cloningInfo?

@description('Optional. Size of the function container.')
param containerSize int?

@description('Optional. Maximum allowed daily memory-time quota (applicable on dynamic apps only).')
param dailyMemoryTimeQuota int?

@description('Optional. Setting this value to false disables the app (takes the app offline).')
param enabled bool

@description('Optional. Hostname SSL states are used to manage the SSL bindings for app\'s hostnames.')
param hostNameSslStates resourceInput<'Microsoft.Web/sites@2025-03-01'>.properties.hostNameSslStates?

@description('Optional. Hyper-V sandbox.')
param hyperV bool = false

@description('Optional. Site redundancy mode.')
param redundancyMode resourceInput<'Microsoft.Web/sites@2025-03-01'>.properties.redundancyMode

@description('Optional. The site publishing credential policy names which are associated with the sites.')
param basicPublishingCredentialsPolicies basicPublishingCredentialsPolicyType[]?

@description('Optional. Whether or not public network access is allowed for this resource. For security reasons it should be disabled. If not specified, it will be disabled by default if private endpoints are set.')
param publicNetworkAccess resourceInput<'Microsoft.Web/sites@2025-03-01'>.properties.publicNetworkAccess?

@description('Optional. End to End Encryption Setting.')
param e2eEncryptionEnabled bool?

@description('Optional. Property to configure various DNS related settings for a site.')
param dnsConfiguration resourceInput<'Microsoft.Web/sites@2025-03-01'>.properties.dnsConfiguration?

@description('Optional. Specifies the scope of uniqueness for the default hostname during resource creation.')
param autoGeneratedDomainNameLabelScope resourceInput<'Microsoft.Web/sites@2025-03-01'>.properties.autoGeneratedDomainNameLabelScope?

@description('Optional. Whether to enable SSH access.')
param sshEnabled bool?

@description('Optional. Dapr configuration of the app.')
param daprConfig resourceInput<'Microsoft.Web/sites@2025-03-01'>.properties.daprConfig?

@description('Optional. Specifies the IP mode of the app.')
param ipMode resourceInput<'Microsoft.Web/sites@2025-03-01'>.properties.ipMode?

@description('Optional. Function app resource requirements.')
param resourceConfig resourceInput<'Microsoft.Web/sites@2025-03-01'>.properties.resourceConfig?

@description('Optional. Workload profile name for function app to execute on.')
param workloadProfileName string?

@description('Optional. True to disable the public hostnames of the app; otherwise, false. If true, the app is only accessible via API management process.')
param hostNamesDisabled bool?

@description('Optional. True if reserved (Linux); otherwise, false (Windows).')
param reserved bool?

@description('Optional. Extended location of the resource.')
param extendedLocation resourceInput<'Microsoft.Web/sites@2025-03-01'>.extendedLocation?


// List of site kinds that support managed environment
var managedEnvironmentSupportedKinds = [
  'functionapp,linux,container,azurecontainerapps'
]

var hasSystemAssignedIdentity = managedIdentities.?systemAssigned ?? false
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

var resourceAbbreviation = 'app'
var regionAbbreviation = regionAbbreviations[?location] ?? location
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take('${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}', 60)
var resolvedName = derivedName
var supportsServerFarmSettings = !empty(serverFarmResourceId)
var resolvedServerFarmId = contains(managedEnvironmentSupportedKinds, kind) && !empty(managedEnvironmentResourceId)
  ? null
  : serverFarmResourceId
var resolvedHostingEnvironmentProfile = !empty(appServiceEnvironmentResourceId)
  ? {
      id: appServiceEnvironmentResourceId
    }
  : null
var resolvedSitePublicNetworkAccess = supportsServerFarmSettings ? publicNetworkAccess : null
var shouldCreateDefaultPrivateEndpoint = enableDefaultPrivateEndpoint
var defaultPrivateDnsZoneResourceId = resourceId('Microsoft.Network/privateDnsZones', defaultPrivateDnsZoneName)
var defaultPrivateEndpointWorkloadDescription = 'appservice'
var defaultPrivateEndpointName = 'pep-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${defaultPrivateEndpointWorkloadDescription}-${instanceNumber}'
var defaultPrivateLinkServiceConnectionName = 'plsc-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${defaultPrivateEndpointWorkloadDescription}-${instanceNumber}'

resource app 'Microsoft.Web/sites@2025-03-01' = {
  name: resolvedName
  location: location
  kind: kind
  tags: tags
  identity: identity
  extendedLocation: extendedLocation
  properties: {
    managedEnvironmentId: managedEnvironmentResourceId
    serverFarmId: resolvedServerFarmId
    clientAffinityEnabled: supportsServerFarmSettings ? clientAffinityEnabled : null
    clientAffinityProxyEnabled: clientAffinityProxyEnabled
    clientAffinityPartitioningEnabled: clientAffinityPartitioningEnabled
    httpsOnly: httpsOnly
    hostingEnvironmentProfile: resolvedHostingEnvironmentProfile
    storageAccountRequired: storageAccountRequired
    keyVaultReferenceIdentity: keyVaultAccessIdentityResourceId
    virtualNetworkSubnetId: virtualNetworkSubnetResourceId
    siteConfig: siteConfig
    functionAppConfig: functionAppConfig
    clientCertEnabled: clientCertEnabled
    clientCertExclusionPaths: clientCertExclusionPaths
    clientCertMode: !empty(serverFarmResourceId) ? clientCertMode : null
    cloningInfo: cloningInfo
    containerSize: containerSize
    dailyMemoryTimeQuota: dailyMemoryTimeQuota
    enabled: enabled
    hostNameSslStates: hostNameSslStates
    hyperV: hyperV
    redundancyMode: redundancyMode
    publicNetworkAccess: resolvedSitePublicNetworkAccess
    scmSiteAlsoStopped: scmSiteAlsoStopped
    endToEndEncryptionEnabled: e2eEncryptionEnabled
    dnsConfiguration: dnsConfiguration
    autoGeneratedDomainNameLabelScope: autoGeneratedDomainNameLabelScope
    outboundVnetRouting: outboundVnetRouting
    sshEnabled: sshEnabled
    daprConfig: daprConfig
    ipMode: ipMode
    resourceConfig: resourceConfig
    workloadProfileName: workloadProfileName
    hostNamesDisabled: hostNamesDisabled
    reserved: reserved
  }
}

module app_config './web-site-config.bicep' = [
  for (config, index) in (configs ?? []): {
      name: '${uniqueString(deployment().name, location)}-Site-Config-${index}'
      params: {
        appName: app.name
        name: config.name
        functionHostStorageAccount: config.?existingFunctionHostStorageAccount
        applicationInsightsComponent: (config.?useSolutionApplicationInsights ?? false) && (config.?applicationInsights != null)
          ? fail('An appsettings config cannot declare both useSolutionApplicationInsights and applicationInsights. Choose one Application Insights source.')
          : ((config.?useSolutionApplicationInsights ?? false) && (solutionApplicationInsightsComponent == null)
              ? fail('An appsettings config with useSolutionApplicationInsights requires solutionApplicationInsightsComponent to be provided to the site module.')
              : ((config.?useSolutionApplicationInsights ?? false)
                  ? solutionApplicationInsightsComponent
                  : config.?applicationInsights))
        properties: config.?properties
      }
  }
]

module app_extensions './web-site-extension.bicep' = [
  for (extension, index) in (extensions ?? []): {
    name: '${uniqueString(deployment().name, location)}-Site-Extension-${index}'
    params: {
      appName: app.name
      properties: extension.properties
    }
  }
]

var resolvedSlotServerFarmResourceId = contains(managedEnvironmentSupportedKinds, kind) && !empty(managedEnvironmentResourceId)
  ? null
  : serverFarmResourceId

var resolvedSlots = [
  for slot in (slots ?? []): {
    name: slot.name
    appName: app.name
    location: location
    kind: kind
    serverFarmResourceId: resolvedSlotServerFarmResourceId
    managedEnvironmentResourceId: slot.?managedEnvironmentResourceId ?? managedEnvironmentResourceId
    httpsOnly: slot.?httpsOnly ?? httpsOnly
    appServiceEnvironmentResourceId: appServiceEnvironmentResourceId
    clientAffinityEnabled: slot.?clientAffinityEnabled ?? clientAffinityEnabled
    clientAffinityProxyEnabled: slot.?clientAffinityProxyEnabled ?? clientAffinityProxyEnabled
    clientAffinityPartitioningEnabled: slot.?clientAffinityPartitioningEnabled ?? clientAffinityPartitioningEnabled
    managedIdentities: slot.?managedIdentities ?? managedIdentities
    keyVaultAccessIdentityResourceId: slot.?keyVaultAccessIdentityResourceId ?? keyVaultAccessIdentityResourceId
    storageAccountRequired: slot.?storageAccountRequired ?? storageAccountRequired
    virtualNetworkSubnetResourceId: slot.?virtualNetworkSubnetResourceId ?? virtualNetworkSubnetResourceId
    siteConfig: slot.?siteConfig ?? siteConfig
    functionAppConfig: slot.?functionAppConfig ?? functionAppConfig
    configs: slot.?configs ?? configs
    extensions: slot.?extensions ?? extensions
    diagnosticSettings: slot.?diagnosticSettings
    roleAssignments: slot.?roleAssignments
    basicPublishingCredentialsPolicies: slot.?basicPublishingCredentialsPolicies ?? basicPublishingCredentialsPolicies
    lock: slot.?lock ?? lock
    enableDefaultPrivateEndpoint: shouldCreateDefaultPrivateEndpoint
    defaultPrivateEndpointSubnetResourceId: defaultPrivateEndpointSubnetResourceId
    defaultPrivateDnsZoneName: defaultPrivateDnsZoneName
    tags: slot.?tags ?? tags
    clientCertEnabled: slot.?clientCertEnabled
    clientCertExclusionPaths: slot.?clientCertExclusionPaths
    clientCertMode: slot.?clientCertMode
    cloningInfo: slot.?cloningInfo
    containerSize: slot.?containerSize
    customDomainVerificationId: slot.?customDomainVerificationId
    dailyMemoryTimeQuota: slot.?dailyMemoryTimeQuota
    enabled: slot.?enabled
    hostNameSslStates: slot.?hostNameSslStates
    hyperV: slot.?hyperV
    publicNetworkAccess: slot.?publicNetworkAccess
    redundancyMode: slot.?redundancyMode
    dnsConfiguration: slot.?dnsConfiguration
    autoGeneratedDomainNameLabelScope: slot.?autoGeneratedDomainNameLabelScope
    outboundVnetRouting: slot.?outboundVnetRouting ?? outboundVnetRouting
    sshEnabled: slot.?sshEnabled
    daprConfig: slot.?daprConfig
    ipMode: slot.?ipMode
    resourceConfig: slot.?resourceConfig
    workloadProfileName: slot.?workloadProfileName
    hostNamesDisabled: slot.?hostNamesDisabled
    reserved: slot.?reserved
    scmSiteAlsoStopped: slot.?scmSiteAlsoStopped ?? scmSiteAlsoStopped
    e2eEncryptionEnabled: slot.?e2eEncryptionEnabled
  }
]

@batchSize(1)
module app_slots './web-site-slot.bicep' = [
  for (slot, index) in resolvedSlots: {
    name: '${uniqueString(deployment().name, location)}-Slot-${slot.name}'
    dependsOn: shouldCreateDefaultPrivateEndpoint ? [app_defaultPrivateDnsZone] : []
    params: {
      name: slot.name
      appName: slot.appName
      location: slot.location
      kind: slot.kind
      serverFarmResourceId: slot.serverFarmResourceId
      managedEnvironmentResourceId: slot.managedEnvironmentResourceId
      httpsOnly: slot.httpsOnly
      appServiceEnvironmentResourceId: slot.appServiceEnvironmentResourceId
      clientAffinityEnabled: slot.clientAffinityEnabled
      clientAffinityProxyEnabled: slot.clientAffinityProxyEnabled
      clientAffinityPartitioningEnabled: slot.clientAffinityPartitioningEnabled
    managedIdentities: slot.managedIdentities
    keyVaultAccessIdentityResourceId: slot.keyVaultAccessIdentityResourceId
    storageAccountRequired: slot.storageAccountRequired
    solutionApplicationInsightsComponent: solutionApplicationInsightsComponent
    virtualNetworkSubnetResourceId: slot.virtualNetworkSubnetResourceId
    siteConfig: slot.siteConfig
    functionAppConfig: slot.functionAppConfig
    configs: slot.configs
      extensions: slot.extensions
      diagnosticSettings: slot.diagnosticSettings
      roleAssignments: slot.roleAssignments
      basicPublishingCredentialsPolicies: slot.basicPublishingCredentialsPolicies
      lock: slot.lock
      enableDefaultPrivateEndpoint: slot.enableDefaultPrivateEndpoint
      defaultPrivateEndpointSubnetResourceId: slot.defaultPrivateEndpointSubnetResourceId
      defaultPrivateDnsZoneName: slot.defaultPrivateDnsZoneName
      tags: slot.tags
      clientCertEnabled: slot.clientCertEnabled
      clientCertExclusionPaths: slot.clientCertExclusionPaths
      clientCertMode: slot.clientCertMode
      cloningInfo: slot.cloningInfo
      containerSize: slot.containerSize
      customDomainVerificationId: slot.customDomainVerificationId
      dailyMemoryTimeQuota: slot.dailyMemoryTimeQuota
      enabled: slot.enabled
      hostNameSslStates: slot.hostNameSslStates
      hyperV: slot.hyperV
      publicNetworkAccess: slot.publicNetworkAccess
      redundancyMode: slot.redundancyMode
      dnsConfiguration: slot.dnsConfiguration
      autoGeneratedDomainNameLabelScope: slot.autoGeneratedDomainNameLabelScope
      outboundVnetRouting: slot.outboundVnetRouting
      sshEnabled: slot.sshEnabled
      daprConfig: slot.daprConfig
      ipMode: slot.ipMode
      resourceConfig: slot.resourceConfig
      workloadProfileName: slot.workloadProfileName
      hostNamesDisabled: slot.hostNamesDisabled
      reserved: slot.reserved
      scmSiteAlsoStopped: slot.scmSiteAlsoStopped
      e2eEncryptionEnabled: slot.e2eEncryptionEnabled
    }
  }
]

module app_basicPublishingCredentialsPolicies './web-site-basic-publishing-credentials-policy.bicep' = [
  for (basicPublishingCredentialsPolicy, index) in (basicPublishingCredentialsPolicies ?? []): {
    name: '${uniqueString(deployment().name, location)}-Site-Publish-Cred-${index}'
    params: {
      webAppName: app.name
      name: basicPublishingCredentialsPolicy.name
      allow: basicPublishingCredentialsPolicy.?allow
      location: location
    }
  }
]

resource app_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${resolvedName}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?notes ?? (lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: app
}

#disable-next-line use-recent-api-versions // This is the latest API version for this resource as of the time of development.
resource app_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
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
    scope: app
  }
]

resource app_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(app.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: app
  }
]

var moduleOwnedPrivateEndpoints = shouldCreateDefaultPrivateEndpoint
  ? [
      {
        resourceGroupName: resourceGroup().name
        resourceGroupSubscriptionId: subscription().subscriptionId
        name: defaultPrivateEndpointName
        location: location
        privateLinkServiceConnectionName: defaultPrivateLinkServiceConnectionName
        service: 'sites'
        subnetResourceId: defaultPrivateEndpointSubnetResourceId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              name: defaultPrivateDnsZoneName
              privateDnsZoneResourceId: defaultPrivateDnsZoneResourceId
            }
          ]
        }
      }
    ]
  : []

module app_defaultPrivateDnsZone '../01-network/private-dns-zone.bicep' = if (shouldCreateDefaultPrivateEndpoint) {
  name: '${uniqueString(deployment().name, location)}-Site-DefaultPrivateDnsZone'
  params: {
    name: defaultPrivateDnsZoneName
    location: 'global'
    virtualNetworkLinks: defaultPrivateDnsZoneVirtualNetworkLinks
    tags: tags
  }
}

var resolvedPrivateEndpoints = [
  for (privateEndpoint, index) in moduleOwnedPrivateEndpoints: {
    resourceGroupName: privateEndpoint.resourceGroupName
    resourceGroupSubscriptionId: privateEndpoint.resourceGroupSubscriptionId
    name: privateEndpoint.name
    service: privateEndpoint.service
    isManualConnection: privateEndpoint.?isManualConnection == true
    privateLinkServiceConnectionName: privateEndpoint.privateLinkServiceConnectionName
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

module app_privateEndpoints '../01-network/private-endpoint.bicep' = [
  for (privateEndpoint, index) in resolvedPrivateEndpoints: {
    name: '${uniqueString(deployment().name, location)}-app-PrivateEndpoint-${index}'
    dependsOn: shouldCreateDefaultPrivateEndpoint ? [app_defaultPrivateDnsZone] : []
    scope: resourceGroup(privateEndpoint.resourceGroupSubscriptionId, privateEndpoint.resourceGroupName)
    params: {
      name: privateEndpoint.name
      privateLinkServiceConnections: !privateEndpoint.isManualConnection
        ? [
            {
              name: privateEndpoint.privateLinkServiceConnectionName
              properties: {
                privateLinkServiceId: app.id
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
                privateLinkServiceId: app.id
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

@description('The name of the site.')
output name string = app.name

@description('The resource ID of the site.')
output resourceId string = app.id

@description('The resource group the site was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The principal ID of the system assigned identity. Returns an empty string when no system-assigned identity is present.')
output systemAssignedMIPrincipalId string = app.?identity.?principalId ?? ''

@description('The location the resource was deployed into.')
output location string = app.location

@description('Default hostname of the app.')
output defaultHostname string = app.properties.defaultHostName

@description('Unique identifier that verifies the custom domains assigned to the app. Customer will add this ID to a txt record for verification.')
output customDomainVerificationId string? = app.properties.customDomainVerificationId

@description('The outbound IP addresses of the app.')
output outboundIpAddresses string = app.properties.outboundIpAddresses

@description('The private endpoints of the site.')
output privateEndpoints privateEndpointOutputType[] = [
  for (item, index) in resolvedPrivateEndpoints: {
    name: app_privateEndpoints[index].outputs.name
    resourceId: app_privateEndpoints[index].outputs.resourceId
    groupId: app_privateEndpoints[index].outputs.?groupId!
    customDnsConfigs: app_privateEndpoints[index].outputs.customDnsConfigs
    networkInterfaceResourceIds: app_privateEndpoints[index].outputs.networkInterfaceResourceIds
  }
]

@description('The slots of the site.')
output slots {
  @description('The name of the slot.')
  name: string

  @description('The resource ID of the slot.')
  resourceId: string

  @description('The principal ID of the system assigned identity of the slot.')
  systemAssignedMIPrincipalId: string?

  @description('The private endpoints of the slot.')
  privateEndpoints: privateEndpointOutputType[]
}[] = [
  #disable-next-line outputs-should-not-contain-secrets // false-positive. The key is not returned
  for (slot, index) in (slots ?? []): {
    name: app_slots[index].name
    resourceId: app_slots[index].outputs.resourceId
    systemAssignedMIPrincipalId: app_slots[index].outputs.?systemAssignedMIPrincipalId ?? ''
    privateEndpoints: app_slots[index].outputs.privateEndpoints
  }
]

// ================ //
// Definitions      //
// ================ //
@export()
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

import {
  appSettingsConfigType
  authSettingsConfigType
  authSettingsV2ConfigType
  azureStorageAccountConfigType
  backupConfigType
  connectionStringsConfigType
  logsConfigType
  metadataConfigType
  pushSettingsConfigType
  webConfigType
} from './web-site-slot.bicep'

@export()
@description('The type of a site configuration.')
@discriminator('name')
type configType =
  | appSettingsConfigType
  | authSettingsConfigType
  | authSettingsV2ConfigType
  | azureStorageAccountConfigType
  | backupConfigType
  | connectionStringsConfigType
  | logsConfigType
  | metadataConfigType
  | pushSettingsConfigType
  | slotConfigNamesConfigType
  | webConfigType

// Not available flor slots
@export()
@description('The type of a slotConfigNames configuration.')
type slotConfigNamesConfigType = {
  @description('Required. The type of config.')
  name: 'slotConfigNames'

  @description('Required. The config settings.')
  properties: {
    @description('Optional. List of application settings names.')
    appSettingNames: string[]?

    @description('Optional. List of external Azure storage account identifiers.')
    azureStorageConfigNames: string[]?

    @description('Optional. List of connection string names.')
    connectionStringNames: string[]?
  }
}

@export()
@description('The type of a slot.')
type slotType = {
  @description('Required. Name of the slot.')
  name: string

  @description('Optional. Location for all Resources.')
  location: string?

  @description('Optional. The resource ID of the app service plan to use for the slot.')
  serverFarmResourceId: string?

  @description('Optional. Azure Resource Manager ID of the customers selected Managed Environment on which to host this app.')
  managedEnvironmentResourceId: string?

  @description('Optional. Configures a slot to accept only HTTPS requests. Issues redirect for HTTP requests.')
  httpsOnly: bool?

  @description('Optional. If client affinity is enabled.')
  clientAffinityEnabled: bool?

  @description('Optional. To enable client affinity; false to stop sending session affinity cookies, which route client requests in the same session to the same instance.')
  clientAffinityProxyEnabled: bool?

  @description('Optional. To enable client affinity partitioning using CHIPS cookies.')
  clientAffinityPartitioningEnabled: bool?

  @description('Optional. The resource ID of the app service environment to use for this resource.')
  appServiceEnvironmentResourceId: string?

  @description('Optional. The managed identity definition for this resource.')
  managedIdentities: managedIdentityOnlySysAssignedType?

  @description('Optional. The resource ID of the assigned identity to be used to access a key vault with.')
  keyVaultAccessIdentityResourceId: string?

  @description('Optional. Checks if Customer provided storage account is required.')
  storageAccountRequired: bool?

  @description('Optional. Azure Resource Manager ID of the Virtual network and subnet to be joined by Regional VNET Integration. This must be of the form /subscriptions/{subscriptionName}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}.')
  virtualNetworkSubnetResourceId: string?

  @description('Optional. The site config object.')
  siteConfig: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.siteConfig?

  @description('Optional. The Function App config object.')
  functionAppConfig: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.functionAppConfig?

  @description('Optional. The web site config.')
  configs: configType[]?

  @description('Optional. The extensions configuration.')
  extensions: resourceInput<'Microsoft.Web/sites/extensions@2025-03-01'>.properties[]?

  @description('Optional. The lock settings of the service.')
  lock: lockType?

  @description('Optional. When true, the module creates the standard private endpoint wiring for the slot.')
  enableDefaultPrivateEndpoint: bool?

  @description('Optional. Subnet resource ID for the module-owned default private endpoint.')
  defaultPrivateEndpointSubnetResourceId: string?

  @description('Optional. Private DNS zone name for the module-owned default private endpoint.')
  defaultPrivateDnsZoneName: string?

  @description('Optional. Tags of the resource.')
  tags: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.tags?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType[]?

  @description('Optional. The diagnostic settings of the service.')
  diagnosticSettings: diagnosticSettingFullType[]?

  @description('Optional. To enable client certificate authentication (TLS mutual authentication).')
  clientCertEnabled: bool?

  @description('Optional. Client certificate authentication comma-separated exclusion paths.')
  clientCertExclusionPaths: string?

  @description('Optional. This composes with ClientCertEnabled setting.</p>- ClientCertEnabled: false means ClientCert is ignored.</p>- ClientCertEnabled: true and ClientCertMode: Required means ClientCert is required.</p>- ClientCertEnabled: true and ClientCertMode: Optional means ClientCert is optional or accepted.')
  clientCertMode: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.clientCertMode?

  @description('Optional. If specified during app creation, the app is cloned from a source app.')
  cloningInfo: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.cloningInfo?

  @description('Optional. Size of the function container.')
  containerSize: int?

  @description('Optional. Unique identifier that verifies the custom domains assigned to the app. Customer will add this ID to a txt record for verification.')
  customDomainVerificationId: string?

  @description('Optional. Maximum allowed daily memory-time quota (applicable on dynamic apps only).')
  dailyMemoryTimeQuota: int?

  @description('Optional. Setting this value to false disables the app (takes the app offline).')
  enabled: bool?

  @description('Optional. Hostname SSL states are used to manage the SSL bindings for app\'s hostnames.')
  hostNameSslStates: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.hostNameSslStates?

  @description('Optional. Hyper-V sandbox.')
  hyperV: bool?

  @description('Optional. Allow or block all public traffic.')
  publicNetworkAccess: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.publicNetworkAccess?

  @description('Optional. Site redundancy mode.')
  redundancyMode: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.redundancyMode?

  @description('Optional. The site publishing credential policy names which are associated with the site slot.')
  basicPublishingCredentialsPolicies: basicPublishingCredentialsPolicyType[]?

  @description('Optional. The outbound VNET routing configuration for the slot.')
  outboundVnetRouting: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.outboundVnetRouting?

  @description('Optional. Property to configure various DNS related settings for a site.')
  dnsConfiguration: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.dnsConfiguration?

  @description('Optional. Specifies the scope of uniqueness for the default hostname during resource creation.')
  autoGeneratedDomainNameLabelScope: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.autoGeneratedDomainNameLabelScope?

  @description('Optional. Whether to enable SSH access.')
  sshEnabled: bool?

  @description('Optional. Dapr configuration of the app.')
  daprConfig: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.daprConfig?

  @description('Optional. Specifies the IP mode of the app.')
  ipMode: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.ipMode?

  @description('Optional. Function app resource requirements.')
  resourceConfig: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.resourceConfig?

  @description('Optional. Workload profile name for function app to execute on.')
  workloadProfileName: string?

  @description('Optional. True to disable the public hostnames of the app; otherwise, false. If true, the app is only accessible via API management process.')
  hostNamesDisabled: bool?

  @description('Optional. True if reserved (Linux); otherwise, false (Windows).')
  reserved: bool?

  @description('Optional. Stop SCM (KUDU) site when the app is stopped.')
  scmSiteAlsoStopped: bool?

  @description('Optional. End to End Encryption Setting.')
  e2eEncryptionEnabled: bool?
}

type extensionType = {
  @description('Optional. Sets the properties.')
  properties: resourceInput<'Microsoft.Web/sites/extensions@2025-03-01'>.properties?
}

@export()
@description('The type of a basic publishing credential policy.')
type basicPublishingCredentialsPolicyType = {
  @description('Required. The name of the resource.')
  name: ('scm' | 'ftp')

  @description('Optional. Set to true to enable or false to disable a publishing method.')
  allow: bool?

  @description('Optional. Location for all Resources.')
  location: string?
}
