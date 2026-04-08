targetScope = 'subscription'

metadata name = 'App Service Landing Zone Accelerator'
metadata description = 'This Azure App Service pattern module represents an Azure App Service deployment aligned with the cloud adoption framework'

import { regionAbbreviations } from 'modules/shared/region-abbreviations.bicep'

// ================ //
// Parameters       //
// ================ //

import {
  spokeNetworkConfigType
  servicePlanConfigType
  appServiceConfigType
  keyVaultConfigType
  appInsightsConfigType
  logAnalyticsConfigType
  appGatewayConfigType
  frontDoorConfigType
  aseConfigType
  entraGroupConfigType
  postgresqlConfigType
} from 'modules/shared/shared.types.bicep'

@maxLength(10)
@description('Optional. suffix (max 10 characters long) that will be used to name the resources in a pattern like <resourceAbbreviation>-<workloadName>.')
param workloadName string = 'appsvc${take(uniqueString(subscription().id), 4)}'

@description('Optional. Azure region where the resources will be deployed in.')
param location string = deployment().location

@description('Optional. The name of the environmentName (e.g. "dev", "test", "prod", "preprod", "staging", "uat", "dr", "qa"). Up to 8 characters long.')
@maxLength(8)
param environmentName string = 'test'

@description('Optional. Abbreviation for the owning system. This is the shared naming input passed to modules that derive resource names locally.')
param systemAbbreviation string = workloadName

@description('Optional. Abbreviation for the lifecycle environment. This is the shared naming input passed to modules that derive resource names locally.')
param environmentAbbreviation string = environmentName

@description('Optional. Instance number used for deterministic naming. Example: "001".')
param instanceNumber string = '001'

@description('Required. Additional workload descriptor to include in names when it adds value. Use an empty string to omit the segment.')
param workloadDescription string

@description('Optional. Default is false. Set to true if you want to deploy ASE v3 instead of Multitenant App Service Plan.')
param deployAseV3 bool = false

@description('Optional. Tags to apply to all resources.')
param tags object = {}


@description('Required. The resource ID of an existing Log Analytics workspace, or null to create one in the spoke resource group.')
param existingLogAnalyticsID string?

@description('Required. Configuration for the Log Analytics workspace when this template creates one.')
param logAnalyticsConfig logAnalyticsConfigType

// ======================== //
// Domain Configuration     //
// ======================== //

@description('Required. Configuration for the spoke virtual network and ingress networking.')
param spokeNetworkConfig spokeNetworkConfigType

@description('Required. Configuration for the App Service Plan.')
param servicePlanConfig servicePlanConfigType

@description('Required. Configuration for the Web App.')
param appServiceConfig appServiceConfigType

@description('Required. Configuration for the Key Vault.')
param keyVaultConfig keyVaultConfigType

@description('Required. Configuration for Application Insights.')
param appInsightsConfig appInsightsConfigType

@description('Required. Configuration for the Application Gateway. Declare the intended state explicitly even when this ingress path is not selected.')
param appGatewayConfig appGatewayConfigType

@description('Required. Configuration for Azure Front Door. Declare the intended state explicitly even when this ingress path is not selected.')
param frontDoorConfig frontDoorConfigType

@description('Optional. Controls whether private endpoint subnets, private DNS zones, private endpoints, and related private-link helpers are deployed. Set to false for a simpler public-only deployment.')
param deployPrivateNetworking bool = true

@description('Required. Configuration for the App Service Environment v3. Declare the intended state explicitly even when deployAseV3 is false.')
param aseConfig aseConfigType

@description('Optional. Controls whether PostgreSQL Flexible Server resources are deployed.')
param deployPostgreSql bool = false

@description('Required. Configuration for the existing Microsoft Entra security group used as the PostgreSQL administrator. Declare the intended state explicitly even when deployPostgreSql is false.')
param postgresqlAdminGroupConfig entraGroupConfigType

@description('Required. Configuration for Azure Database for PostgreSQL Flexible Server. Declare the intended state explicitly even when deployPostgreSql is false.')
param postgresqlConfig postgresqlConfigType

// ================ //
// Variables        //
// ================ //

// ======================== //
// Resolved Configuration   //
// ======================== //

// Spoke Network
var vnetSpokeAddressSpace = spokeNetworkConfig.vnetAddressSpace
var subnetSpokeAppSvcAddressSpace = spokeNetworkConfig.appSvcSubnetAddressSpace
var subnetSpokePrivateEndpointAddressSpace = spokeNetworkConfig.privateEndpointSubnetAddressSpace
var networkingOption = spokeNetworkConfig.ingressOption
var applicationGatewayConfig = spokeNetworkConfig.?applicationGatewayConfig
var privateNetworkingEnabled = deployPrivateNetworking && !empty(subnetSpokePrivateEndpointAddressSpace)
var webAppPrivateNetworkingEnabled = privateNetworkingEnabled && !deployAseV3
var postgreSqlEnabled = deployPostgreSql
var postgreSqlPrivateNetworkingEnabled = postgreSqlEnabled && deployPrivateNetworking
var postgreSqlPrivateAccessEnabled = postgreSqlEnabled && postgresqlConfig.privateAccessMode == 'delegatedSubnet'
var postgreSqlPrivateAccessConfig = spokeNetworkConfig.?postgreSqlPrivateAccessConfig
var hubPeeringConfig = spokeNetworkConfig.?hubPeeringConfig
var enableEgressLockdown = spokeNetworkConfig.enableEgressLockdown
var egressFirewallConfig = spokeNetworkConfig.?egressFirewallConfig
var dnsServers = spokeNetworkConfig.dnsServers
var ddosProtectionPlanResourceId = spokeNetworkConfig.?ddosProtectionPlanResourceId
var disableBgpRoutePropagation = spokeNetworkConfig.disableBgpRoutePropagation
var vnetEncryption = spokeNetworkConfig.encryption
var vnetEncryptionEnforcement = spokeNetworkConfig.encryptionEnforcement
var flowTimeoutInMinutes = spokeNetworkConfig.flowTimeoutInMinutes
var enableVmProtection = spokeNetworkConfig.enableVmProtection
var enablePrivateEndpointVNetPolicies = spokeNetworkConfig.enablePrivateEndpointVNetPolicies
var virtualNetworkBgpCommunity = spokeNetworkConfig.?bgpCommunity
var vnetLock = spokeNetworkConfig.?lock
var vnetRoleAssignments = spokeNetworkConfig.roleAssignments
var vnetDiagnosticSettings = spokeNetworkConfig.diagnosticSettings

// Log Analytics
var logAnalyticsWorkspaceSku = logAnalyticsConfig.sku
var logAnalyticsWorkspaceRetentionInDays = logAnalyticsConfig.retentionInDays
var logAnalyticsWorkspaceEnableLogAccessUsingOnlyResourcePermissions = logAnalyticsConfig.enableLogAccessUsingOnlyResourcePermissions
var logAnalyticsWorkspaceDisableLocalAuth = logAnalyticsConfig.disableLocalAuth
var logAnalyticsWorkspacePublicNetworkAccessForIngestion = logAnalyticsConfig.publicNetworkAccessForIngestion
var logAnalyticsWorkspacePublicNetworkAccessForQuery = logAnalyticsConfig.publicNetworkAccessForQuery
var logAnalyticsWorkspaceLock = logAnalyticsConfig.?lock
var logAnalyticsWorkspaceRoleAssignments = logAnalyticsConfig.roleAssignments
var logAnalyticsWorkspaceDiagnosticSettings = logAnalyticsConfig.diagnosticSettings

// ======================== //
// Naming & Resource Names  //
// ======================== //

var regionAbbreviation = regionAbbreviations[?location] ?? location
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var resourceGroupName = take('rg-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}', 90)

var virtualNetworkLinks = [
  {
    name: networking.outputs.vnetSpokeName
    virtualNetworkResourceId: networking.outputs.vnetSpokeResourceId
    registrationEnabled: false
  }
]
var hubVirtualNetworkLink = hubPeeringConfig != null
  ? {
      name: hubPeeringConfig!.virtualNetworkName
      virtualNetworkResourceId: hubPeeringConfig!.virtualNetworkResourceId
      registrationEnabled: false
    }
  : null
var postgreSqlPrivateDnsZoneVirtualNetworkLinks = concat(
  virtualNetworkLinks,
  hubVirtualNetworkLink != null
      ? [
          hubVirtualNetworkLink
        ]
    : []
)

// ================ //
// Resources        //
// ================ //

resource spokeResourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
  properties: {}
}

module logAnalyticsWorkspace 'modules/02-monitoring/log-analytics-workspace.bicep' = if (existingLogAnalyticsID == null) {
  name: '${uniqueString(deployment().name, location, systemAbbreviation, environmentAbbreviation, instanceNumber, 'law')}-law'
  scope: spokeResourceGroup
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    tags: tags
    sku: logAnalyticsWorkspaceSku
    retentionInDays: logAnalyticsWorkspaceRetentionInDays
    enableLogAccessUsingOnlyResourcePermissions: logAnalyticsWorkspaceEnableLogAccessUsingOnlyResourcePermissions
    disableLocalAuth: logAnalyticsWorkspaceDisableLocalAuth
    publicNetworkAccessForIngestion: logAnalyticsWorkspacePublicNetworkAccessForIngestion
    publicNetworkAccessForQuery: logAnalyticsWorkspacePublicNetworkAccessForQuery
    lock: logAnalyticsWorkspaceLock
    roleAssignments: logAnalyticsWorkspaceRoleAssignments
    diagnosticSettings: logAnalyticsWorkspaceDiagnosticSettings
  }
}

var resolvedLogAnalyticsWorkspaceResourceId = existingLogAnalyticsID != null
  ? existingLogAnalyticsID!
  : logAnalyticsWorkspace!.outputs.resourceId

// ======================== //
// Networking               //
// ======================== //

module networking 'modules/01-network/network.bicep' = {
  name: '${uniqueString(deployment().name, location)}-networking'
  scope: spokeResourceGroup
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    deployAseV3: deployAseV3
    deployPrivateNetworking: privateNetworkingEnabled
    enableEgressLockdown: enableEgressLockdown
    vnetSpokeAddressSpace: vnetSpokeAddressSpace
    subnetSpokeAppSvcAddressSpace: subnetSpokeAppSvcAddressSpace
    subnetSpokePrivateEndpointAddressSpace: subnetSpokePrivateEndpointAddressSpace
    applicationGatewayConfig: applicationGatewayConfig
    postgreSqlPrivateAccessConfig: postgreSqlPrivateAccessConfig
    egressFirewallConfig: egressFirewallConfig
    hubPeeringConfig: hubPeeringConfig
    networkingOption: networkingOption
    deployPostgreSqlPrivateAccess: postgreSqlPrivateNetworkingEnabled
    logAnalyticsWorkspaceId: resolvedLogAnalyticsWorkspaceResourceId
    dnsServers: dnsServers
    ddosProtectionPlanResourceId: ddosProtectionPlanResourceId
    vnetDiagnosticSettings: vnetDiagnosticSettings
    vnetLock: vnetLock
    disableBgpRoutePropagation: disableBgpRoutePropagation
    vnetRoleAssignments: vnetRoleAssignments
    vnetEncryption: vnetEncryption
    vnetEncryptionEnforcement: vnetEncryptionEnforcement
    flowTimeoutInMinutes: flowTimeoutInMinutes
    enableVmProtection: enableVmProtection
    enablePrivateEndpointVNetPolicies: enablePrivateEndpointVNetPolicies
    virtualNetworkBgpCommunity: virtualNetworkBgpCommunity
    tags: tags
  }
}

// ======================== //
// App Service Variables    //
// ======================== //

// Service Plan
var webAppPlanSku = servicePlanConfig.sku
var zoneRedundant = servicePlanConfig.zoneRedundant
var webAppBaseOs = servicePlanConfig.kind
var existingAppServicePlanId = servicePlanConfig.existingPlanId
var skuCapacity = servicePlanConfig.skuCapacity
var workerTierName = servicePlanConfig.workerTierName
var elasticScaleEnabled = servicePlanConfig.elasticScaleEnabled
var maximumElasticWorkerCount = servicePlanConfig.maximumElasticWorkerCount
var perSiteScaling = servicePlanConfig.perSiteScaling
var targetWorkerCount = servicePlanConfig.targetWorkerCount
var targetWorkerSize = servicePlanConfig.targetWorkerSize
var appServicePlanVirtualNetworkSubnetId = servicePlanConfig.virtualNetworkSubnetId
var isCustomMode = servicePlanConfig.isCustomMode
var rdpEnabled = servicePlanConfig.rdpEnabled
var installScripts = servicePlanConfig.installScripts
var registryAdapters = servicePlanConfig.registryAdapters
var storageMounts = servicePlanConfig.storageMounts
var appServicePlanManagedIdentities = servicePlanConfig.managedIdentities
var appServicePlanLock = servicePlanConfig.?lock
var appServicePlanRoleAssignments = servicePlanConfig.roleAssignments
var servicePlanDiagnosticSettings = servicePlanConfig.diagnosticSettings

// Web App
var webAppKind = appServiceConfig.kind
var httpsOnly = appServiceConfig.httpsOnly
var clientCertEnabled = appServiceConfig.clientCertEnabled
var clientCertMode = appServiceConfig.?clientCertMode
var clientCertExclusionPaths = appServiceConfig.?clientCertExclusionPaths
var disableBasicPublishingCredentials = appServiceConfig.disableBasicPublishingCredentials
var resolvedWebAppPublicNetworkAccess = appServiceConfig.publicNetworkAccess
var redundancyMode = appServiceConfig.redundancyMode
var scmSiteAlsoStopped = appServiceConfig.scmSiteAlsoStopped
var siteConfig = appServiceConfig.siteConfig
var functionAppConfig = appServiceConfig.?functionAppConfig
var managedEnvironmentResourceId = appServiceConfig.?managedEnvironmentResourceId
var outboundVnetRouting = appServiceConfig.?outboundVnetRouting
var hostNameSslStates = appServiceConfig.?hostNameSslStates
var e2eEncryptionEnabled = appServiceConfig.?e2eEncryptionEnabled
var keyVaultAccessIdentityResourceId = appServiceConfig.?keyVaultAccessIdentityResourceId
var appServiceManagedIdentities = appServiceConfig.managedIdentities
var appServiceSystemAssignedIdentityEnabled = appServiceManagedIdentities.?systemAssigned ?? false
var webAppExtensions = appServiceConfig.?extensions
var webAppEnabled = appServiceConfig.enabled
var cloningInfo = appServiceConfig.?cloningInfo
var containerSize = appServiceConfig.?containerSize
var dailyMemoryTimeQuota = appServiceConfig.?dailyMemoryTimeQuota
var storageAccountRequired = appServiceConfig.storageAccountRequired
var dnsConfiguration = appServiceConfig.?dnsConfiguration
var autoGeneratedDomainNameLabelScope = appServiceConfig.?autoGeneratedDomainNameLabelScope
var sshEnabled = appServiceConfig.?sshEnabled
var daprConfig = appServiceConfig.?daprConfig
var ipMode = appServiceConfig.?ipMode
var resourceConfig = appServiceConfig.?resourceConfig
var workloadProfileName = appServiceConfig.?workloadProfileName
var hostNamesDisabled = appServiceConfig.?hostNamesDisabled
var webAppReserved = appServiceConfig.reserved
var extendedLocation = appServiceConfig.?extendedLocation
var clientAffinityEnabled = appServiceConfig.clientAffinityEnabled
var clientAffinityProxyEnabled = appServiceConfig.clientAffinityProxyEnabled
var clientAffinityPartitioningEnabled = appServiceConfig.clientAffinityPartitioningEnabled
var webAppLock = appServiceConfig.?lock
var webAppRoleAssignments = appServiceConfig.?roleAssignments
var appserviceDiagnosticSettings = appServiceConfig.diagnosticSettings
var configuredAppSlots = appServiceConfig.slots
var appServiceConfigs = appServiceConfig.configs

var webAppDnsZoneName = 'privatelink.azurewebsites.net'
var keyVaultPrivateDnsZoneName = 'privatelink.vaultcore.azure.net'

var deployPlan = empty(existingAppServicePlanId)
var resolvedServerFarmResourceId = appServicePlan.?outputs.?resourceId ?? existingAppServicePlanId
var isLinux = webAppBaseOs =~ 'linux'
var isWindowsContainer = contains(webAppKind, 'container') && contains(webAppKind, 'windows')
var webAppHyperV = appServiceConfig.hyperV
var containerSiteConfig = siteConfig
var resolvedAppServiceDiagnosticSettings = appserviceDiagnosticSettings
var resolvedServicePlanDiagnosticSettings = servicePlanDiagnosticSettings
var resolvedAseDiagnosticSettings = aseDiagnosticSettings
var resolvedWebAppClientCertMode = clientCertEnabled ? clientCertMode : null
var webAppPublishingCredentialPolicies = disableBasicPublishingCredentials
  ? [
      {
        name: 'ftp'
        allow: false
      }
      {
        name: 'scm'
        allow: false
      }
    ]
  : null
var webAppVirtualNetworkSubnetResourceId = !deployAseV3 && !isCustomMode
  ? networking.outputs.snetAppSvcResourceId
  : null
// ======================== //
// ASE                      //
// ======================== //

var aseClusterSettings = aseConfig.clusterSettings
var aseCustomDnsSuffix = aseConfig.customDnsSuffix
var aseIpsslAddressCount = aseConfig.ipsslAddressCount
var aseMultiSize = aseConfig.multiSize
var aseCustomDnsSuffixCertificateUrl = aseConfig.customDnsSuffixCertificateUrl
var aseDedicatedHostCount = aseConfig.dedicatedHostCount
var aseDnsSuffix = aseConfig.dnsSuffix
var aseFrontEndScaleFactor = aseConfig.frontEndScaleFactor
var aseInternalLoadBalancingMode = aseConfig.internalLoadBalancingMode
var aseZoneRedundant = aseConfig.zoneRedundant
var aseAllowNewPrivateEndpointConnections = aseConfig.allowNewPrivateEndpointConnections
var aseFtpEnabled = aseConfig.ftpEnabled
var aseInboundIpAddressOverride = aseConfig.inboundIpAddressOverride
var aseRemoteDebugEnabled = aseConfig.remoteDebugEnabled
var aseUpgradePreference = aseConfig.upgradePreference
var aseLock = aseConfig.?lock
var aseRoleAssignments = aseConfig.?roleAssignments
var aseDiagnosticSettings = aseConfig.diagnosticSettings

module aseEnvironment 'modules/03-app-hosting/hosting-environment.bicep' = if (deployAseV3) {
  name: '${uniqueString(deployment().name, location)}-ase-avm'
  scope: spokeResourceGroup
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    tags: tags
    subnetResourceId: networking.outputs.snetAppSvcResourceId
    subnetName: networking.outputs.snetAppSvcName
    clusterSettings: aseClusterSettings
    dedicatedHostCount: aseDedicatedHostCount != 0 ? aseDedicatedHostCount : null
    frontEndScaleFactor: aseFrontEndScaleFactor
    internalLoadBalancingMode: aseInternalLoadBalancingMode
    zoneRedundant: aseZoneRedundant
    networkConfiguration: {
      properties: {
        allowNewPrivateEndpointConnections: aseAllowNewPrivateEndpointConnections
        ftpEnabled: aseFtpEnabled
        inboundIpAddressOverride: aseInboundIpAddressOverride
        remoteDebugEnabled: aseRemoteDebugEnabled
      }
    }
    customDnsSuffixCertificateUrl: aseCustomDnsSuffixCertificateUrl
    customDnsSuffix: aseCustomDnsSuffix
    dnsSuffix: !empty(aseDnsSuffix) ? aseDnsSuffix : null
    upgradePreference: aseUpgradePreference
    ipsslAddressCount: aseIpsslAddressCount
    multiSize: aseMultiSize
    diagnosticSettings: resolvedAseDiagnosticSettings
    lock: aseLock
    roleAssignments: aseRoleAssignments
  }
}


// Lookup ASE properties via a resource-group-scoped module to avoid ARM reference() validation issues
// in subscription-scoped templates with conditional existing resources.
module aseLookup 'modules/01-network/ase-lookup.bicep' = if (deployAseV3) {
  name: '${uniqueString(deployment().name, location)}-ase-lookup'
  scope: spokeResourceGroup
  params: {
    aseName: aseEnvironment.outputs.name
  }
}

#disable-next-line BCP318
module asePrivateDnsZone 'modules/01-network/private-dns-zone.bicep' = if (deployAseV3) {
  name: '${uniqueString(deployment().name, location)}-ase-dnszone'
  scope: spokeResourceGroup
  params: {
    name: '${aseEnvironment.outputs.name}.appserviceenvironment.net'
    virtualNetworkLinks: virtualNetworkLinks
    tags: tags
    a: [
      {
        name: '*'
        aRecords: [
          {
            ipv4Address: aseLookup.outputs.internalInboundIpAddress
          }
        ]
        ttl: 3600
      }
      {
        name: '*.scm'
        aRecords: [
          {
            ipv4Address: aseLookup.outputs.internalInboundIpAddress
          }
        ]
        ttl: 3600
      }
      {
        name: '@'
        aRecords: [
          {
            ipv4Address: aseLookup.outputs.internalInboundIpAddress
          }
        ]
        ttl: 3600
      }
    ]
  }
}

// ======================== //
// App Insights             //
// ======================== //

var appInsightsPublicNetworkAccessForIngestion = appInsightsConfig.publicNetworkAccessForIngestion
var appInsightsPublicNetworkAccessForQuery = appInsightsConfig.publicNetworkAccessForQuery
var appInsightsApplicationType = appInsightsConfig.applicationType
var appInsightsRetentionInDays = appInsightsConfig.retentionInDays
var appInsightsSamplingPercentage = appInsightsConfig.samplingPercentage
var appInsightsDisableLocalAuth = appInsightsConfig.disableLocalAuth
var appInsightsDisableIpMasking = appInsightsConfig.disableIpMasking
var appInsightsForceCustomerStorageForProfiler = appInsightsConfig.forceCustomerStorageForProfiler
var appInsightsLinkedStorageAccountResourceId = appInsightsConfig.?linkedStorageAccountResourceId
var appInsightsFlowType = appInsightsConfig.?flowType
var appInsightsRequestSource = appInsightsConfig.?requestSource
var appInsightsKind = appInsightsConfig.kind
var appInsightsImmediatePurgeDataOn30Days = appInsightsConfig.?immediatePurgeDataOn30Days
var appInsightsIngestionMode = appInsightsConfig.?ingestionMode
var appInsightsLock = appInsightsConfig.?lock
var appInsightsRoleAssignments = appInsightsConfig.roleAssignments
var appInsightsDiagnosticSettings = appInsightsConfig.diagnosticSettings

module appInsights 'modules/02-monitoring/application-insights.bicep' = {
  name: '${uniqueString(deployment().name, location)}-appInsights'
  scope: spokeResourceGroup
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    tags: tags
    workspaceResourceId: resolvedLogAnalyticsWorkspaceResourceId
    applicationType: appInsightsApplicationType
    publicNetworkAccessForIngestion: appInsightsPublicNetworkAccessForIngestion
    publicNetworkAccessForQuery: appInsightsPublicNetworkAccessForQuery
    retentionInDays: appInsightsRetentionInDays
    samplingPercentage: appInsightsSamplingPercentage
    disableLocalAuth: appInsightsDisableLocalAuth
    disableIpMasking: appInsightsDisableIpMasking
    forceCustomerStorageForProfiler: appInsightsForceCustomerStorageForProfiler
    linkedStorageAccountResourceId: appInsightsLinkedStorageAccountResourceId
    flowType: appInsightsFlowType
    requestSource: appInsightsRequestSource
    kind: appInsightsKind
    immediatePurgeDataOn30Days: appInsightsImmediatePurgeDataOn30Days
    ingestionMode: appInsightsIngestionMode
    lock: appInsightsLock
    roleAssignments: appInsightsRoleAssignments
    diagnosticSettings: appInsightsDiagnosticSettings
  }
}

// ======================== //
// App Service Plan         //
// ======================== //

module appServicePlan 'modules/03-app-hosting/serverfarm.bicep' = if (deployPlan) {
  name: '${uniqueString(deployment().name, location, 'webapp')}-plan'
  scope: spokeResourceGroup
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    tags: tags
    skuName: webAppPlanSku
    skuCapacity: skuCapacity
    zoneRedundant: zoneRedundant
    kind: isLinux ? 'Linux' : 'Windows'
    perSiteScaling: perSiteScaling
    maximumElasticWorkerCount: maximumElasticWorkerCount
    elasticScaleEnabled: elasticScaleEnabled
    reserved: isLinux
    targetWorkerCount: targetWorkerCount
    targetWorkerSize: targetWorkerSize
    workerTierName: workerTierName
    hyperV: isWindowsContainer
    appServiceEnvironmentResourceId: aseEnvironment.?outputs.?resourceId ?? null
    virtualNetworkSubnetId: isCustomMode ? networking.outputs.snetAppSvcResourceId : appServicePlanVirtualNetworkSubnetId
    isCustomMode: isCustomMode
    rdpEnabled: rdpEnabled
    installScripts: installScripts
    registryAdapters: registryAdapters
    storageMounts: storageMounts
    managedIdentities: appServicePlanManagedIdentities
    diagnosticSettings: resolvedServicePlanDiagnosticSettings
    lock: appServicePlanLock
    roleAssignments: appServicePlanRoleAssignments
  }
}

// ======================== //
// Web App                  //
// ======================== //

module webAppSite 'modules/04-application/web-site.bicep' = {
  name: '${uniqueString(deployment().name, location)}-webapp'
  scope: spokeResourceGroup
  params: {
    kind: webAppKind
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    serverFarmResourceId: resolvedServerFarmResourceId
    siteConfig: containerSiteConfig
    httpsOnly: httpsOnly
    clientAffinityEnabled: clientAffinityEnabled
    clientAffinityProxyEnabled: clientAffinityProxyEnabled
    clientAffinityPartitioningEnabled: clientAffinityPartitioningEnabled
    clientCertEnabled: clientCertEnabled
    clientCertMode: resolvedWebAppClientCertMode
    clientCertExclusionPaths: clientCertExclusionPaths
    publicNetworkAccess: resolvedWebAppPublicNetworkAccess
    redundancyMode: redundancyMode
    scmSiteAlsoStopped: scmSiteAlsoStopped
    functionAppConfig: functionAppConfig
    managedEnvironmentResourceId: managedEnvironmentResourceId
    outboundVnetRouting: outboundVnetRouting
    hostNameSslStates: hostNameSslStates
    hyperV: webAppHyperV
    e2eEncryptionEnabled: e2eEncryptionEnabled
    keyVaultAccessIdentityResourceId: keyVaultAccessIdentityResourceId
    extensions: webAppExtensions
    enabled: webAppEnabled
    cloningInfo: cloningInfo
    containerSize: containerSize
    dailyMemoryTimeQuota: dailyMemoryTimeQuota
    storageAccountRequired: storageAccountRequired
    dnsConfiguration: dnsConfiguration
    autoGeneratedDomainNameLabelScope: autoGeneratedDomainNameLabelScope
    sshEnabled: sshEnabled
    daprConfig: daprConfig
    ipMode: ipMode
    resourceConfig: resourceConfig
    workloadProfileName: workloadProfileName
    hostNamesDisabled: hostNamesDisabled
    reserved: webAppReserved
    extendedLocation: extendedLocation
    basicPublishingCredentialsPolicies: webAppPublishingCredentialPolicies
    diagnosticSettings: resolvedAppServiceDiagnosticSettings
    lock: webAppLock
    roleAssignments: webAppRoleAssignments
    virtualNetworkSubnetResourceId: webAppVirtualNetworkSubnetResourceId
    managedIdentities: appServiceManagedIdentities
    solutionApplicationInsightsComponent: {
      name: appInsights.outputs.name
      resourceGroupName: appInsights.outputs.resourceGroupName
    }
    configs: appServiceConfigs
    slots: configuredAppSlots
    enableDefaultPrivateEndpoint: webAppPrivateNetworkingEnabled
    defaultPrivateEndpointSubnetResourceId: networking.outputs.snetPeResourceId
    defaultPrivateDnsZoneName: webAppDnsZoneName
    defaultPrivateDnsZoneVirtualNetworkLinks: virtualNetworkLinks
    tags: tags
  }
}

// ======================== //
// Front Door               //
// ======================== //

var frontDoorSelected = networkingOption == 'frontDoor'
var shouldDeployFrontDoor = frontDoorSelected
var frontDoorSettings = frontDoorConfig
var autoApproveAfdPrivateEndpoint = frontDoorSettings.autoApprovePrivateEndpoint
var afdPeAutoApproverIsolationScope = frontDoorSettings.afdPeAutoApproverIsolationScope
var frontDoorWafCustomRules = frontDoorSettings.enableDefaultWafMethodBlock
  ? {
      rules: [
        {
          name: 'BlockMethod'
          enabledState: 'Enabled'
          action: 'Block'
          ruleType: 'MatchRule'
          priority: 10
          rateLimitDurationInMinutes: 1
          rateLimitThreshold: 100
          matchConditions: [
            {
              matchVariable: 'RequestMethod'
              operator: 'Equal'
              negateCondition: true
              matchValue: [
                'GET'
                'OPTIONS'
                'HEAD'
              ]
            }
          ]
        }
      ]
    }
  : frontDoorSettings.wafCustomRules

module frontDoorWaf 'modules/07-edge/front-door-waf-policy.bicep' = if (shouldDeployFrontDoor) {
  name: '${uniqueString(deployment().name, location)}-afd-waf'
  scope: spokeResourceGroup
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: 'global'
    tags: tags
    sku: any(frontDoorSettings.sku)
    policySettings: frontDoorSettings.wafPolicySettings
    customRules: frontDoorWafCustomRules
    managedRules: {
      managedRuleSets: frontDoorSettings.wafManagedRuleSets
    }
  }
}

module afd 'modules/07-edge/front-door-profile.bicep' = if (shouldDeployFrontDoor) {
  name: '${uniqueString(deployment().name, location)}-afd'
  scope: spokeResourceGroup
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    sku: any(frontDoorSettings.sku)
    location: 'global'
    originResponseTimeoutSeconds: frontDoorSettings.originResponseTimeoutSeconds
    managedIdentities: frontDoorSettings.managedIdentities
    diagnosticSettings: frontDoorSettings.diagnosticSettings
    lock: frontDoorSettings.?lock
    roleAssignments: frontDoorSettings.roleAssignments
    customDomains: frontDoorSettings.customDomains
    ruleSets: frontDoorSettings.ruleSets
    secrets: frontDoorSettings.secrets
    originGroups: [
      for originGroup in frontDoorSettings.originGroups: {
        name: originGroup.name
        authentication: originGroup.?authentication
        healthProbeSettings: originGroup.?healthProbeSettings
        loadBalancingSettings: originGroup.loadBalancingSettings
        sessionAffinityState: any(originGroup.sessionAffinityState)
        trafficRestorationTimeToHealedOrNewEndpointsInMinutes: originGroup.trafficRestorationTimeToHealedOrNewEndpointsInMinutes
        origins: map(originGroup.origins, origin => {
            name: origin.name
            hostName: webAppSite.outputs.defaultHostname
            httpPort: origin.httpPort
            httpsPort: origin.httpsPort
            priority: origin.priority
            weight: origin.weight
            enabledState: any(origin.enabledState)
            enforceCertificateNameCheck: origin.enforceCertificateNameCheck
            originHostHeader: webAppSite.outputs.defaultHostname
            sharedPrivateLinkResource: origin.?sharedPrivateLink != null
              ? {
                  privateLink: {
                    id: webAppSite.outputs.resourceId
                  }
                  privateLinkLocation: webAppSite.outputs.location
                  requestMessage: origin.?sharedPrivateLink.?requestMessage
                  groupId: origin.?sharedPrivateLink.?groupId
                }
              : null
          })
      }
    ]
    afdEndpoints: frontDoorSettings.afdEndpoints
    tags: tags
  }
}

#disable-next-line BCP318
var frontDoorSecurityPolicyDomains = !empty(frontDoorSettings.customDomains)
  ? afd.outputs.customDomainSecurityPolicyDomains
  : afd.outputs.afdEndpointSecurityPolicyDomains

module frontDoorSecurityPolicy 'modules/07-edge/front-door-security-policy.bicep' = if (shouldDeployFrontDoor) {
  name: '${uniqueString(deployment().name, location)}-afd-security-policy'
  scope: spokeResourceGroup
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    profileName: afd.outputs.name
    wafPolicyResourceId: frontDoorWaf.outputs.resourceId
    associations: [
      {
        domains: frontDoorSecurityPolicyDomains
        patternsToMatch: frontDoorSettings.securityPatternsToMatch
      }
    ]
  }
}

module afdPeAutoApproverIdentity 'modules/05-identity/user-assigned-identity.bicep' = if (autoApproveAfdPrivateEndpoint && shouldDeployFrontDoor && webAppPrivateNetworkingEnabled) {
  name: '${uniqueString(deployment().name, location)}-afd-uami'
  scope: spokeResourceGroup
  dependsOn: [
    spokeResourceGroup
    afd
  ]
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: 'afdprivateendpointapprover'
    location: location
    tags: tags
    isolationScope: afdPeAutoApproverIsolationScope
  }
}

module afdPeAutoApproverRoleAssignment 'modules/shared/resource-group-role-assignments.bicep' = if (autoApproveAfdPrivateEndpoint && shouldDeployFrontDoor && webAppPrivateNetworkingEnabled) {
  name: '${uniqueString(deployment().name, location)}-afd-uami-rbac'
  scope: spokeResourceGroup
  params: {
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Contributor'
        principalId: afdPeAutoApproverIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

module autoApproveAfdPe 'modules/shared/deployment-script.bicep' = if (autoApproveAfdPrivateEndpoint && shouldDeployFrontDoor && webAppPrivateNetworkingEnabled) {
  name: '${uniqueString(deployment().name, location)}-autoApproveAfdPe'
  scope: spokeResourceGroup
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: 'afdapproval'
    location: location
    tags: tags
    kind: 'AzureCLI'
    managedIdentities: {
      userAssignedResourceIds: [afdPeAutoApproverIdentity.outputs.resourceId]
    }
    azCliVersion: '2.67.0'
    timeout: 'PT30M'
    environmentVariables: [
      {
        name: 'ResourceGroupName'
        value: resourceGroupName
      }
    ]
    scriptContent: '''
      rg_name="$ResourceGroupName"; webapp_ids=$(az webapp list -g $rg_name --query "[].id" -o tsv); for webapp_id in $webapp_ids; do fd_conn_ids=$(az network private-endpoint-connection list --id $webapp_id --query "[?properties.provisioningState == 'Pending'].id" -o tsv); for fd_conn_id in $fd_conn_ids; do az network private-endpoint-connection approve --id "$fd_conn_id" --description "ApprovedByCli"; done; done
      '''
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    afd
    afdPeAutoApproverRoleAssignment
  ]
}

// ======================== //
// Application Gateway      //
// ======================== //

var appGatewaySettings = appGatewayConfig
var appGatewaySslCertificates = appGatewaySettings.sslCertificates
var appGatewayManagedIdentities = appGatewaySettings.managedIdentities
var appGatewayTrustedRootCertificates = appGatewaySettings.trustedRootCertificates
var appGatewaySku = appGatewaySettings.sku
var appGatewayCapacity = appGatewaySettings.capacity
var appGatewayAutoscaleMinCapacity = appGatewaySettings.autoscaleMinCapacity
var appGatewayAutoscaleMaxCapacity = appGatewaySettings.autoscaleMaxCapacity
var appGatewayAvailabilityZones = appGatewaySettings.availabilityZones
var appGatewaySslPolicyType = appGatewaySettings.sslPolicyType
var appGatewaySslPolicyName = appGatewayConfig.sslPolicyName
var appGatewaySslPolicyMinProtocolVersion = appGatewaySettings.sslPolicyMinProtocolVersion
var appGatewaySslPolicyCipherSuites = appGatewaySettings.sslPolicyCipherSuites
var appGatewayRoleAssignments = appGatewaySettings.roleAssignments
var appGatewayAuthenticationCertificates = appGatewaySettings.authenticationCertificates
var appGatewayCustomErrorConfigurations = appGatewaySettings.customErrorConfigurations
var appGatewayEnableFips = appGatewaySettings.enableFips
var appGatewayEnableHttp2 = appGatewaySettings.enableHttp2
var appGatewayEnableRequestBuffering = appGatewaySettings.enableRequestBuffering
var appGatewayEnableResponseBuffering = appGatewaySettings.enableResponseBuffering
var appGatewayLoadDistributionPolicies = appGatewaySettings.loadDistributionPolicies
var appGatewayPrivateEndpoints = appGatewaySettings.privateEndpoints
var appGatewayPrivateLinkConfigurations = appGatewaySettings.privateLinkConfigurations
var appGatewayRedirectConfigurations = appGatewaySettings.redirectConfigurations
var appGatewayRewriteRuleSets = appGatewaySettings.rewriteRuleSets
var appGatewayGatewayIPConfigurations = appGatewaySettings.gatewayIPConfigurations
var appGatewayFrontendIPConfigurations = appGatewaySettings.frontendIPConfigurations
var appGatewayFrontendPorts = appGatewaySettings.frontendPorts
var appGatewayBackendAddressPools = appGatewaySettings.backendAddressPools
var appGatewayBackendHttpSettingsCollection = appGatewaySettings.backendHttpSettingsCollection
var appGatewayProbes = appGatewaySettings.probes
var appGatewayHttpListeners = appGatewaySettings.httpListeners
var appGatewaySslProfiles = appGatewaySettings.sslProfiles
var appGatewayTrustedClientCertificates = appGatewaySettings.trustedClientCertificates
var appGatewayUrlPathMaps = appGatewaySettings.urlPathMaps
var appGatewayBackendSettingsCollection = appGatewaySettings.backendSettingsCollection
var appGatewayListeners = appGatewaySettings.listeners
var appGatewayRoutingRules = appGatewaySettings.routingRules
var appGatewayRequestRoutingRules = appGatewaySettings.requestRoutingRules
var appGatewayLock = appGatewaySettings.?lock
var appGatewayDiagnosticSettings = appGatewaySettings.diagnosticSettings
var appGatewayWafPolicySettings = appGatewaySettings.wafPolicySettings
var appGatewayWafManagedRuleSets = appGatewaySettings.wafManagedRuleSets

module appGwWafPolicy 'modules/07-edge/application-gateway-waf-policy.bicep' = if (networkingOption == 'applicationGateway') {
  name: '${uniqueString(deployment().name, location)}-appgw-waf'
  scope: spokeResourceGroup
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    tags: tags
    managedRules: {
      managedRuleSets: appGatewayWafManagedRuleSets
    }
    policySettings: appGatewayWafPolicySettings
  }
}

module appGw 'modules/07-edge/application-gateway.bicep' = if (networkingOption == 'applicationGateway') {
  name: '${uniqueString(deployment().name, location)}-appGw'
  scope: spokeResourceGroup
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    tags: tags
    sku: appGatewaySku
    capacity: appGatewayCapacity
    autoscaleMinCapacity: appGatewayAutoscaleMinCapacity
    autoscaleMaxCapacity: appGatewayAutoscaleMaxCapacity
    enableHttp2: appGatewayEnableHttp2
    enableFips: appGatewayEnableFips
    enableRequestBuffering: appGatewayEnableRequestBuffering
    enableResponseBuffering: appGatewayEnableResponseBuffering
    availabilityZones: appGatewayAvailabilityZones
    firewallPolicyResourceId: appGwWafPolicy.outputs.resourceId
    diagnosticSettings: appGatewayDiagnosticSettings
    lock: appGatewayLock
    roleAssignments: appGatewayRoleAssignments
    managedIdentities: appGatewayManagedIdentities
    sslCertificates: appGatewaySslCertificates
    trustedRootCertificates: appGatewayTrustedRootCertificates
    sslPolicyType: appGatewaySslPolicyType
    sslPolicyName: any(appGatewaySslPolicyName)
    sslPolicyMinProtocolVersion: appGatewaySslPolicyMinProtocolVersion
    sslPolicyCipherSuites: appGatewaySslPolicyCipherSuites
    authenticationCertificates: appGatewayAuthenticationCertificates
    customErrorConfigurations: appGatewayCustomErrorConfigurations
    loadDistributionPolicies: appGatewayLoadDistributionPolicies
    gatewayIPConfigurations: appGatewayGatewayIPConfigurations
    frontendIPConfigurations: appGatewayFrontendIPConfigurations
    frontendPorts: appGatewayFrontendPorts
    backendAddressPools: appGatewayBackendAddressPools
    backendHttpSettingsCollection: appGatewayBackendHttpSettingsCollection
    probes: appGatewayProbes
    httpListeners: appGatewayHttpListeners
    privateEndpoints: appGatewayPrivateEndpoints
    privateLinkConfigurations: appGatewayPrivateLinkConfigurations
    redirectConfigurations: appGatewayRedirectConfigurations
    rewriteRuleSets: appGatewayRewriteRuleSets
    sslProfiles: appGatewaySslProfiles
    trustedClientCertificates: appGatewayTrustedClientCertificates
    urlPathMaps: appGatewayUrlPathMaps
    backendSettingsCollection: appGatewayBackendSettingsCollection
    listeners: appGatewayListeners
    routingRules: appGatewayRoutingRules
    requestRoutingRules: appGatewayRequestRoutingRules
  }
}

// ======================== //
// Supporting Services      //
// ======================== //

var keyVaultEnablePurgeProtection = keyVaultConfig.enablePurgeProtection
var keyVaultSoftDeleteRetentionInDays = keyVaultConfig.softDeleteRetentionInDays
var keyVaultSecrets = keyVaultConfig.?secrets
var keyVaultKeys = keyVaultConfig.?keys
var keyVaultEnableVaultForTemplateDeployment = keyVaultConfig.enableVaultForTemplateDeployment
var keyVaultEnableVaultForDiskEncryption = keyVaultConfig.enableVaultForDiskEncryption
var keyVaultCreateMode = keyVaultConfig.createMode
var keyVaultSku = keyVaultConfig.sku
var keyVaultEnableVaultForDeployment = keyVaultConfig.enableVaultForDeployment
var resolvedKeyVaultNetworkAcls = keyVaultConfig.networkAcls
var resolvedKeyVaultPublicNetworkAccess = keyVaultConfig.publicNetworkAccess
var keyVaultLock = keyVaultConfig.?lock
var keyVaultRoleAssignments = keyVaultConfig.roleAssignments
var keyVaultDiagnosticSettings = keyVaultConfig.diagnosticSettings

@description('Azure Key Vault used to hold items like TLS certs and application secrets that your workload will need.')
module keyVault 'modules/06-secrets/key-vault.bicep' = {
  name: '${uniqueString(deployment().name, location)}-keyVault'
  scope: spokeResourceGroup
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    tags: tags
    sku: keyVaultSku
    networkAcls: resolvedKeyVaultNetworkAcls
    softDeleteRetentionInDays: keyVaultSoftDeleteRetentionInDays
    enablePurgeProtection: keyVaultEnablePurgeProtection
    publicNetworkAccess: resolvedKeyVaultPublicNetworkAccess
    enableVaultForDeployment: keyVaultEnableVaultForDeployment
    enableVaultForTemplateDeployment: keyVaultEnableVaultForTemplateDeployment
    enableVaultForDiskEncryption: keyVaultEnableVaultForDiskEncryption
    createMode: keyVaultCreateMode
    secrets: keyVaultSecrets
    keys: keyVaultKeys
    enableDefaultPrivateEndpoint: privateNetworkingEnabled
    defaultPrivateEndpointSubnetResourceId: networking.outputs.snetPeResourceId
    defaultPrivateDnsZoneName: keyVaultPrivateDnsZoneName
    defaultPrivateDnsZoneVirtualNetworkLinks: concat(
      [
        {
          name: networking.outputs.vnetSpokeName
          virtualNetworkResourceId: networking.outputs.vnetSpokeResourceId
          registrationEnabled: false
        }
      ],
      hubVirtualNetworkLink != null
        ? [
            hubVirtualNetworkLink!
          ]
        : []
    )
    diagnosticSettings: keyVaultDiagnosticSettings
    lock: keyVaultLock
    roleAssignments: keyVaultRoleAssignments
  }
}

// ======================== //
// PostgreSQL               //
// ======================== //

var postgreSqlRoleAssignments = concat(
  postgresqlConfig.roleAssignments,
  postgresqlConfig.grantAppServiceIdentityReaderRole
    ? [
        {
          roleDefinitionIdOrName: 'Reader'
          principalId: appServiceSystemAssignedIdentityEnabled
            ? webAppSite.outputs.systemAssignedMIPrincipalId
            : fail('postgresqlConfig.grantAppServiceIdentityReaderRole requires appServiceConfig.managedIdentities.systemAssigned to be true.')
          principalType: 'ServicePrincipal'
          description: 'Allows the web app system-assigned identity to read PostgreSQL flexible server resource metadata.'
        }
      ]
    : []
)

module postgreSql 'modules/08-data/postgresql-flexible-server.bicep' = if (deployPostgreSql) {
  name: '${uniqueString(deployment().name, location)}-postgresql'
  scope: spokeResourceGroup
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: postgresqlConfig.workloadDescription
    location: location
    administratorGroupObjectId: postgresqlAdminGroupConfig.objectId
    administratorGroupDisplayName: postgresqlAdminGroupConfig.displayName
    skuName: postgresqlConfig.skuName
    tier: postgresqlConfig.tier
    availabilityZone: postgresqlConfig.availabilityZone
    highAvailabilityZone: postgresqlConfig.highAvailabilityZone
    highAvailability: postgresqlConfig.highAvailability
    backupRetentionDays: postgresqlConfig.backupRetentionDays
    geoRedundantBackup: postgresqlConfig.geoRedundantBackup
    storageSizeGB: postgresqlConfig.storageSizeGB
    autoGrow: postgresqlConfig.autoGrow
    version: postgresqlConfig.version
    deployPrivateNetworking: postgreSqlPrivateNetworkingEnabled
    publicNetworkAccess: postgresqlConfig.publicNetworkAccess
    privateAccessMode: postgresqlConfig.privateAccessMode
    delegatedSubnetResourceId: postgreSqlPrivateAccessEnabled ? networking.outputs.snetPostgreSqlResourceId : null
    privateDnsZoneVirtualNetworkLinks: postgreSqlPrivateDnsZoneVirtualNetworkLinks
    databases: postgresqlConfig.databases
    configurations: postgresqlConfig.configurations
    diagnosticSettings: postgresqlConfig.diagnosticSettings
    lock: postgresqlConfig.?lock
    roleAssignments: postgreSqlRoleAssignments
    tags: tags
  }
}

// ================ //
// Outputs          //
// ================ //

@description('The name of the Spoke resource group.')
output spokeResourceGroupName string = spokeResourceGroup.name

@description('The resource ID of the Spoke Virtual Network.')
output spokeVNetResourceId string = networking.outputs.vnetSpokeResourceId

@description('The name of the Spoke Virtual Network.')
output spokeVnetName string = networking.outputs.vnetSpokeName

@description('The resource ID of the key vault.')
output keyVaultResourceId string = keyVault.outputs.resourceId

@description('The name of the Azure key vault.')
output keyVaultName string = keyVault.outputs.name

@description('The name of the web app.')
output webAppName string = webAppSite.outputs.name

@description('The default hostname of the web app.')
output webAppHostName string = webAppSite.outputs.defaultHostname

@description('The resource ID of the web app.')
output webAppResourceId string = webAppSite.outputs.resourceId

@description('The location of the web app.')
output webAppLocation string = webAppSite.outputs.location

@description('The principal ID of the web app managed identity.')
output webAppManagedIdentityPrincipalId string = webAppSite.outputs.systemAssignedMIPrincipalId

@description('The resource ID of the App Service Plan used (either created or pre-existing).')
output appServicePlanResourceId string = resolvedServerFarmResourceId

@description('The Internal ingress IP of the ASE. Null when ASE is not deployed.')
output internalInboundIpAddress string? = aseLookup.?outputs.?internalInboundIpAddress

@description('The name of the ASE. Null when ASE is not deployed.')
output aseName string? = aseEnvironment.?outputs.?name

@description('The resource ID of the Log Analytics workspace used by this deployment.')
output logAnalyticsWorkspaceUsedResourceId string = resolvedLogAnalyticsWorkspaceResourceId

@description('The name of the Log Analytics workspace created by this deployment. Null when an existing workspace is used.')
output logAnalyticsWorkspaceCreatedName string? = logAnalyticsWorkspace.?outputs.?name

@description('The object ID of the Microsoft Entra security group used as the PostgreSQL administrator. Null when PostgreSQL is not deployed.')
output postgreSqlAdminGroupObjectId string? = deployPostgreSql ? postgresqlAdminGroupConfig.objectId : null

@description('The display name of the Microsoft Entra security group used as the PostgreSQL administrator. Null when PostgreSQL is not deployed.')
output postgreSqlAdminGroupName string? = deployPostgreSql ? postgresqlAdminGroupConfig.displayName : null

@description('The name of the PostgreSQL flexible server. Null when PostgreSQL is not deployed.')
output postgreSqlServerName string? = postgreSql.?outputs.?name

@description('The resource ID of the PostgreSQL flexible server. Null when PostgreSQL is not deployed.')
output postgreSqlServerResourceId string? = deployPostgreSql ? postgreSql!.outputs.resourceId : null

@description('The FQDN of the PostgreSQL flexible server. Null when PostgreSQL is not deployed.')
output postgreSqlServerFqdn string? = deployPostgreSql ? postgreSql!.outputs.fqdn : null

@description('The name of the PostgreSQL private DNS zone. Null when PostgreSQL private access is not enabled.')
output postgreSqlPrivateDnsZoneName string? = postgreSqlPrivateAccessEnabled ? postgreSql!.outputs.privateDnsZoneName! : null
