targetScope = 'subscription'

import { regionAbbreviations } from 'modules/shared/region-abbreviations.bicep'
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
  resourceGroupDefinitionType
} from 'modules/shared/shared.types.bicep'

// ================ //
// Parameters       //
// ================ //

@maxLength(10)
param workloadName string = 'appsvc${take(uniqueString(subscription().id), 4)}'
param location string = deployment().location
@maxLength(8)
param environmentName string = 'test'
param systemAbbreviation string = workloadName
param environmentAbbreviation string = environmentName
param instanceNumber string = '001'
param workloadDescription string
param deployAseV3 bool = false
param tags object = {}
param resourceGroupDefinitions resourceGroupDefinitionType[]
param existingLogAnalyticsID string?
param logAnalyticsConfig logAnalyticsConfigType

// ======================== //
// Domain Configuration     //
// ======================== //

param spokeNetworkConfig spokeNetworkConfigType
param servicePlanConfig servicePlanConfigType
param appServiceConfig appServiceConfigType
param keyVaultConfig keyVaultConfigType
param appInsightsConfig appInsightsConfigType
param appGatewayConfig appGatewayConfigType
param frontDoorConfig frontDoorConfigType
param deployPrivateNetworking bool = true
param aseConfig aseConfigType
param deployPostgreSql bool = false
param postgresqlAdminGroupConfig entraGroupConfigType
param postgresqlConfig postgresqlConfigType

// ================ //
// Variables        //
// ================ //

// Networking Decisions
var networkingOption = spokeNetworkConfig.ingressOption
var privateNetworkingEnabled = deployPrivateNetworking && !empty(spokeNetworkConfig.privateEndpointSubnetAddressSpace)
var webAppPrivateNetworkingEnabled = privateNetworkingEnabled && !deployAseV3
var postgreSqlEnabled = deployPostgreSql
var postgreSqlPrivateNetworkingEnabled = postgreSqlEnabled && deployPrivateNetworking
var postgreSqlPrivateAccessEnabled = postgreSqlEnabled && postgresqlConfig.privateAccessMode == 'delegatedSubnet'
var hubPeeringConfig = spokeNetworkConfig.?hubPeeringConfig
var enableEgressLockdown = spokeNetworkConfig.enableEgressLockdown
var regionAbbreviation = regionAbbreviations[location]

// ======================== //
// Shared Network Links     //
// ======================== //

var resourceGroupDefinitionKeys = [for resourceGroupDefinition in resourceGroupDefinitions: resourceGroupDefinition.key]
var networkResourceGroupDefinition = resourceGroupDefinitions[indexOf(resourceGroupDefinitionKeys, 'network')]
var networkEdgeResourceGroupDefinition = resourceGroupDefinitions[indexOf(resourceGroupDefinitionKeys, 'networkEdge')]
var hostingResourceGroupDefinition = resourceGroupDefinitions[indexOf(resourceGroupDefinitionKeys, 'hosting')]
var dataResourceGroupDefinition = resourceGroupDefinitions[indexOf(resourceGroupDefinitionKeys, 'data')]
var operationsResourceGroupDefinition = resourceGroupDefinitions[indexOf(resourceGroupDefinitionKeys, 'operations')]
var resourceGroupNameMap = {
  network: take('rg-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${networkResourceGroupDefinition.workloadDescription}${empty(networkResourceGroupDefinition.?subWorkloadDescription ?? '') ? '' : '-${networkResourceGroupDefinition.subWorkloadDescription!}'}-${instanceNumber}', 90)
  networkEdge: take('rg-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${networkEdgeResourceGroupDefinition.workloadDescription}${empty(networkEdgeResourceGroupDefinition.?subWorkloadDescription ?? '') ? '' : '-${networkEdgeResourceGroupDefinition.subWorkloadDescription!}'}-${instanceNumber}', 90)
  hosting: take('rg-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${hostingResourceGroupDefinition.workloadDescription}${empty(hostingResourceGroupDefinition.?subWorkloadDescription ?? '') ? '' : '-${hostingResourceGroupDefinition.subWorkloadDescription!}'}-${instanceNumber}', 90)
  data: take('rg-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${dataResourceGroupDefinition.workloadDescription}${empty(dataResourceGroupDefinition.?subWorkloadDescription ?? '') ? '' : '-${dataResourceGroupDefinition.subWorkloadDescription!}'}-${instanceNumber}', 90)
  operations: take('rg-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${operationsResourceGroupDefinition.workloadDescription}${empty(operationsResourceGroupDefinition.?subWorkloadDescription ?? '') ? '' : '-${operationsResourceGroupDefinition.subWorkloadDescription!}'}-${instanceNumber}', 90)
}
var spokePrivateDnsZoneLinks = [
  {
    name: networking.outputs.vnetSpokeName
    virtualNetworkResourceId: networking.outputs.vnetSpokeResourceId
    registrationEnabled: false
  }
]
var optionalHubPrivateDnsZoneLink = hubPeeringConfig != null
  ? {
      name: hubPeeringConfig!.virtualNetworkName
      virtualNetworkResourceId: hubPeeringConfig!.virtualNetworkResourceId
      registrationEnabled: false
    }
  : null
var postgreSqlPrivateDnsZoneLinks = concat(
  spokePrivateDnsZoneLinks,
  optionalHubPrivateDnsZoneLink != null
      ? [
          optionalHubPrivateDnsZoneLink
        ]
    : []
)

// ================ //
// Resources        //
// ================ //

module resourceGroups 'modules/shared/resource-group.bicep' = [
  for resourceGroupDefinition in resourceGroupDefinitions: {
    name: '${uniqueString(deployment().name, location, resourceGroupDefinition.key)}-rg'
    params: {
      systemAbbreviation: systemAbbreviation
      environmentAbbreviation: environmentAbbreviation
      instanceNumber: instanceNumber
      workloadDescription: resourceGroupDefinition.workloadDescription
      subWorkloadDescription: resourceGroupDefinition.?subWorkloadDescription ?? ''
      location: location
      tags: tags
    }
  }
]

module logAnalyticsWorkspace 'modules/02-monitoring/log-analytics-workspace.bicep' = if (existingLogAnalyticsID == null) {
  name: '${uniqueString(deployment().name, location, systemAbbreviation, environmentAbbreviation, instanceNumber, 'law')}-law'
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.operations)
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    tags: tags
    sku: logAnalyticsConfig.sku
    retentionInDays: logAnalyticsConfig.retentionInDays
    enableLogAccessUsingOnlyResourcePermissions: logAnalyticsConfig.enableLogAccessUsingOnlyResourcePermissions
    disableLocalAuth: logAnalyticsConfig.disableLocalAuth
    publicNetworkAccessForIngestion: logAnalyticsConfig.publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: logAnalyticsConfig.publicNetworkAccessForQuery
    lock: logAnalyticsConfig.?lock
    roleAssignments: logAnalyticsConfig.roleAssignments
    diagnosticSettings: logAnalyticsConfig.diagnosticSettings
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
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.network)
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    deployAseV3: deployAseV3
    deployPrivateNetworking: privateNetworkingEnabled
    enableEgressLockdown: enableEgressLockdown
    vnetSpokeAddressSpace: spokeNetworkConfig.vnetAddressSpace
    subnetSpokeAppSvcAddressSpace: spokeNetworkConfig.appSvcSubnetAddressSpace
    subnetSpokePrivateEndpointAddressSpace: spokeNetworkConfig.privateEndpointSubnetAddressSpace
    applicationGatewayConfig: spokeNetworkConfig.?applicationGatewayConfig
    postgreSqlPrivateAccessConfig: spokeNetworkConfig.?postgreSqlPrivateAccessConfig
    egressFirewallConfig: spokeNetworkConfig.?egressFirewallConfig
    hubPeeringConfig: hubPeeringConfig
    networkingOption: networkingOption
    deployPostgreSqlPrivateAccess: postgreSqlPrivateNetworkingEnabled
    logAnalyticsWorkspaceId: resolvedLogAnalyticsWorkspaceResourceId
    dnsServers: spokeNetworkConfig.dnsServers
    ddosProtectionPlanResourceId: spokeNetworkConfig.?ddosProtectionPlanResourceId
    vnetDiagnosticSettings: spokeNetworkConfig.diagnosticSettings
    vnetLock: spokeNetworkConfig.?lock
    disableBgpRoutePropagation: spokeNetworkConfig.disableBgpRoutePropagation
    vnetRoleAssignments: spokeNetworkConfig.roleAssignments
    vnetEncryption: spokeNetworkConfig.encryption
    vnetEncryptionEnforcement: spokeNetworkConfig.encryptionEnforcement
    flowTimeoutInMinutes: spokeNetworkConfig.flowTimeoutInMinutes
    enableVmProtection: spokeNetworkConfig.enableVmProtection
    enablePrivateEndpointVNetPolicies: spokeNetworkConfig.enablePrivateEndpointVNetPolicies
    virtualNetworkBgpCommunity: spokeNetworkConfig.?bgpCommunity
    tags: tags
  }
}

// ======================== //
// App Service Variables    //
// ======================== //

var existingAppServicePlanId = servicePlanConfig.existingPlanId
var useExistingAppServicePlan = !empty(existingAppServicePlanId)
var deployPlan = !useExistingAppServicePlan
var appServicePlanResourceId = useExistingAppServicePlan
  ? existingAppServicePlanId
  : appServicePlan!.outputs.resourceId
var useSolutionWebAppSubnetIntegration = !deployAseV3 && !servicePlanConfig.isCustomMode
var webAppVirtualNetworkSubnetResourceId = useSolutionWebAppSubnetIntegration
  ? networking.outputs.snetAppSvcResourceId
  : null

// ======================== //
// ASE                      //
// ======================== //

module aseEnvironment 'modules/03-app-hosting/hosting-environment.bicep' = if (deployAseV3) {
  name: '${uniqueString(deployment().name, location)}-ase-avm'
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.hosting)
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    tags: tags
    subnetResourceId: networking.outputs.snetAppSvcResourceId
    subnetName: networking.outputs.snetAppSvcName
    clusterSettings: aseConfig.clusterSettings
    dedicatedHostCount: aseConfig.dedicatedHostCount
    frontEndScaleFactor: aseConfig.frontEndScaleFactor
    internalLoadBalancingMode: aseConfig.internalLoadBalancingMode
    zoneRedundant: aseConfig.zoneRedundant
    networkConfiguration: {
      properties: {
        allowNewPrivateEndpointConnections: aseConfig.allowNewPrivateEndpointConnections
        ftpEnabled: aseConfig.ftpEnabled
        inboundIpAddressOverride: aseConfig.inboundIpAddressOverride
        remoteDebugEnabled: aseConfig.remoteDebugEnabled
      }
    }
    customDnsSuffixCertificateUrl: aseConfig.customDnsSuffixCertificateUrl
    customDnsSuffix: aseConfig.customDnsSuffix
    dnsSuffix: aseConfig.dnsSuffix
    upgradePreference: aseConfig.upgradePreference
    ipsslAddressCount: aseConfig.ipsslAddressCount
    multiSize: aseConfig.multiSize
    diagnosticSettings: aseConfig.diagnosticSettings
    lock: aseConfig.?lock
    roleAssignments: aseConfig.?roleAssignments
  }
}

// Lookup ASE properties via a resource-group-scoped module to avoid ARM reference() validation issues
// in subscription-scoped templates with conditional existing resources.
module aseLookup 'modules/01-network/ase-lookup.bicep' = if (deployAseV3) {
  name: '${uniqueString(deployment().name, location)}-ase-lookup'
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.hosting)
  params: {
    aseName: aseEnvironment!.outputs.name
  }
}

module asePrivateDnsZone 'modules/01-network/private-dns-zone.bicep' = if (deployAseV3) {
  name: '${uniqueString(deployment().name, location)}-ase-dnszone'
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.network)
  params: {
    name: '${aseEnvironment!.outputs.name}.appserviceenvironment.net'
    virtualNetworkLinks: spokePrivateDnsZoneLinks
    tags: tags
    a: [
      {
        name: '*'
        aRecords: [
          {
            ipv4Address: aseLookup!.outputs.internalInboundIpAddress
          }
        ]
        ttl: 3600
      }
      {
        name: '*.scm'
        aRecords: [
          {
            ipv4Address: aseLookup!.outputs.internalInboundIpAddress
          }
        ]
        ttl: 3600
      }
      {
        name: '@'
        aRecords: [
          {
            ipv4Address: aseLookup!.outputs.internalInboundIpAddress
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

module appInsights 'modules/02-monitoring/application-insights.bicep' = {
  name: '${uniqueString(deployment().name, location)}-appInsights'
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.operations)
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    tags: tags
    workspaceResourceId: resolvedLogAnalyticsWorkspaceResourceId
    applicationType: appInsightsConfig.applicationType
    publicNetworkAccessForIngestion: appInsightsConfig.publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: appInsightsConfig.publicNetworkAccessForQuery
    retentionInDays: appInsightsConfig.retentionInDays
    samplingPercentage: appInsightsConfig.samplingPercentage
    disableLocalAuth: appInsightsConfig.disableLocalAuth
    disableIpMasking: appInsightsConfig.disableIpMasking
    forceCustomerStorageForProfiler: appInsightsConfig.forceCustomerStorageForProfiler
    linkedStorageAccountResourceId: appInsightsConfig.?linkedStorageAccountResourceId
    flowType: appInsightsConfig.?flowType
    requestSource: appInsightsConfig.?requestSource
    kind: appInsightsConfig.kind
    immediatePurgeDataOn30Days: appInsightsConfig.?immediatePurgeDataOn30Days
    ingestionMode: appInsightsConfig.?ingestionMode
    lock: appInsightsConfig.?lock
    roleAssignments: appInsightsConfig.roleAssignments
    diagnosticSettings: appInsightsConfig.diagnosticSettings
  }
}

// ======================== //
// App Service Plan         //
// ======================== //

module appServicePlan 'modules/03-app-hosting/serverfarm.bicep' = if (deployPlan) {
  name: '${uniqueString(deployment().name, location, 'webapp')}-plan'
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.hosting)
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    tags: tags
    skuName: servicePlanConfig.sku
    skuCapacity: servicePlanConfig.skuCapacity
    zoneRedundant: servicePlanConfig.zoneRedundant
    servicePlanOsFamily: servicePlanConfig.osFamily
    workloadKind: appServiceConfig.kind
    perSiteScaling: servicePlanConfig.perSiteScaling
    maximumElasticWorkerCount: servicePlanConfig.maximumElasticWorkerCount
    elasticScaleEnabled: servicePlanConfig.elasticScaleEnabled
    targetWorkerCount: servicePlanConfig.targetWorkerCount
    targetWorkerSize: servicePlanConfig.targetWorkerSize
    workerTierName: servicePlanConfig.?workerTierName
    appServiceEnvironmentResourceId: aseEnvironment.?outputs.?resourceId ?? null
    virtualNetworkSubnetId: servicePlanConfig.isCustomMode ? networking.outputs.snetAppSvcResourceId : servicePlanConfig.?virtualNetworkSubnetId
    isCustomMode: servicePlanConfig.isCustomMode
    rdpEnabled: servicePlanConfig.rdpEnabled
    installScripts: servicePlanConfig.installScripts
    registryAdapters: servicePlanConfig.registryAdapters
    storageMounts: servicePlanConfig.storageMounts
    managedIdentities: servicePlanConfig.managedIdentities
    diagnosticSettings: servicePlanConfig.diagnosticSettings
    lock: servicePlanConfig.?lock
    roleAssignments: servicePlanConfig.roleAssignments
  }
}

// ======================== //
// Web App                  //
// ======================== //

module webAppSite 'modules/04-application/web-site.bicep' = {
  name: '${uniqueString(deployment().name, location)}-webapp'
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.hosting)
  params: {
    kind: appServiceConfig.kind
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    serverFarmResourceId: appServicePlanResourceId
    siteConfig: appServiceConfig.siteConfig
    httpsOnly: appServiceConfig.httpsOnly
    clientAffinityEnabled: appServiceConfig.clientAffinityEnabled
    clientAffinityProxyEnabled: appServiceConfig.clientAffinityProxyEnabled
    clientAffinityPartitioningEnabled: appServiceConfig.clientAffinityPartitioningEnabled
    clientCertEnabled: appServiceConfig.clientCertEnabled
    clientCertMode: appServiceConfig.?clientCertMode
    clientCertExclusionPaths: appServiceConfig.?clientCertExclusionPaths
    publicNetworkAccess: appServiceConfig.publicNetworkAccess
    redundancyMode: appServiceConfig.redundancyMode
    scmSiteAlsoStopped: appServiceConfig.scmSiteAlsoStopped
    functionAppConfig: appServiceConfig.?functionAppConfig
    managedEnvironmentResourceId: appServiceConfig.?managedEnvironmentResourceId
    outboundVnetRouting: appServiceConfig.?outboundVnetRouting
    hostNameSslStates: appServiceConfig.?hostNameSslStates
    hyperV: appServiceConfig.hyperV
    e2eEncryptionEnabled: appServiceConfig.?e2eEncryptionEnabled
    keyVaultAccessIdentityResourceId: appServiceConfig.?keyVaultAccessIdentityResourceId
    extensions: appServiceConfig.?extensions
    enabled: appServiceConfig.enabled
    cloningInfo: appServiceConfig.?cloningInfo
    containerSize: appServiceConfig.?containerSize
    dailyMemoryTimeQuota: appServiceConfig.?dailyMemoryTimeQuota
    storageAccountRequired: appServiceConfig.storageAccountRequired
    dnsConfiguration: appServiceConfig.?dnsConfiguration
    autoGeneratedDomainNameLabelScope: appServiceConfig.?autoGeneratedDomainNameLabelScope
    sshEnabled: appServiceConfig.?sshEnabled
    daprConfig: appServiceConfig.?daprConfig
    ipMode: appServiceConfig.?ipMode
    resourceConfig: appServiceConfig.?resourceConfig
    workloadProfileName: appServiceConfig.?workloadProfileName
    hostNamesDisabled: appServiceConfig.?hostNamesDisabled
    reserved: appServiceConfig.reserved
    extendedLocation: appServiceConfig.?extendedLocation
    disableBasicPublishingCredentials: appServiceConfig.disableBasicPublishingCredentials
    diagnosticSettings: appServiceConfig.diagnosticSettings
    lock: appServiceConfig.?lock
    roleAssignments: appServiceConfig.?roleAssignments
    virtualNetworkSubnetResourceId: webAppVirtualNetworkSubnetResourceId
    managedIdentities: appServiceConfig.managedIdentities
    solutionApplicationInsightsComponent: {
      name: appInsights.outputs.name
      resourceGroupName: appInsights.outputs.resourceGroupName
    }
    configs: appServiceConfig.configs
    slots: appServiceConfig.slots
    enableDefaultPrivateEndpoint: webAppPrivateNetworkingEnabled
    defaultPrivateEndpointSubnetResourceId: networking.outputs.?snetPeResourceId
    defaultPrivateNetworkingResourceGroupName: resourceGroupNameMap.network
    defaultPrivateDnsZoneVirtualNetworkLinks: spokePrivateDnsZoneLinks
    tags: tags
  }
}

// ======================== //
// Front Door               //
// ======================== //

var useFrontDoorIngress = spokeNetworkConfig.ingressOption == 'frontDoor'
var autoApproveAfdPrivateEndpoint = frontDoorConfig.autoApprovePrivateEndpoint
var afdPeAutoApproverIsolationScope = frontDoorConfig.afdPeAutoApproverIsolationScope

module frontDoorWaf 'modules/07-edge/front-door-waf-policy.bicep' = if (useFrontDoorIngress) {
  name: '${uniqueString(deployment().name, location)}-afd-waf'
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.networkEdge)
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    config: frontDoorConfig
    tags: tags
  }
}

module afd 'modules/07-edge/front-door-profile.bicep' = if (useFrontDoorIngress) {
  name: '${uniqueString(deployment().name, location)}-afd'
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.networkEdge)
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    config: frontDoorConfig
    workloadOriginHostName: webAppSite.outputs.defaultHostname
    workloadOriginResourceId: webAppSite.outputs.resourceId
    workloadOriginLocation: webAppSite.outputs.location
    tags: tags
  }
}

module frontDoorSecurityPolicy 'modules/07-edge/front-door-security-policy.bicep' = if (useFrontDoorIngress) {
  name: '${uniqueString(deployment().name, location)}-afd-security-policy'
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.networkEdge)
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    profileName: afd!.outputs.name
    wafPolicyResourceId: frontDoorWaf!.outputs.resourceId
    associations: [
      {
        domains: concat(
          afd!.outputs.customDomainSecurityPolicyDomains,
          afd!.outputs.afdDefaultLinkedSecurityPolicyDomains
        )
        patternsToMatch: frontDoorConfig.securityPatternsToMatch
      }
    ]
  }
}

module afdPeAutoApproverIdentity 'modules/05-identity/user-assigned-identity.bicep' = if (autoApproveAfdPrivateEndpoint && useFrontDoorIngress && webAppPrivateNetworkingEnabled) {
  name: '${uniqueString(deployment().name, location)}-afd-uami'
  scope: resourceGroup(resourceGroupNameMap.operations)
  dependsOn: [
    resourceGroups
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

module afdPeAutoApproverRoleAssignment 'modules/shared/resource-group-role-assignments.bicep' = if (autoApproveAfdPrivateEndpoint && useFrontDoorIngress && webAppPrivateNetworkingEnabled) {
  name: '${uniqueString(deployment().name, location)}-afd-uami-rbac'
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.hosting)
  params: {
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Contributor'
        principalId: afdPeAutoApproverIdentity!.outputs.principalId
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

module autoApproveAfdPe 'modules/shared/deployment-script.bicep' = if (autoApproveAfdPrivateEndpoint && useFrontDoorIngress && webAppPrivateNetworkingEnabled) {
  name: '${uniqueString(deployment().name, location)}-autoApproveAfdPe'
  dependsOn: [
    resourceGroups
    afd
    afdPeAutoApproverRoleAssignment
  ]
  scope: resourceGroup(resourceGroupNameMap.operations)
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: 'afdapproval'
    location: location
    tags: tags
    kind: 'AzureCLI'
    managedIdentities: {
      userAssignedResourceIds: [afdPeAutoApproverIdentity!.outputs.resourceId]
    }
    azCliVersion: '2.67.0'
    timeout: 'PT30M'
    environmentVariables: [
      {
        name: 'ResourceGroupName'
        value: resourceGroupNameMap.hosting
      }
    ]
    scriptContent: '''
      rg_name="$ResourceGroupName"; webapp_ids=$(az webapp list -g $rg_name --query "[].id" -o tsv); for webapp_id in $webapp_ids; do fd_conn_ids=$(az network private-endpoint-connection list --id $webapp_id --query "[?properties.provisioningState == 'Pending'].id" -o tsv); for fd_conn_id in $fd_conn_ids; do az network private-endpoint-connection approve --id "$fd_conn_id" --description "ApprovedByCli"; done; done
      '''
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

// ======================== //
// Application Gateway      //
// ======================== //

var useApplicationGatewayIngress = networkingOption == 'applicationGateway'

module appGwWafPolicy 'modules/07-edge/application-gateway-waf-policy.bicep' = if (useApplicationGatewayIngress) {
  name: '${uniqueString(deployment().name, location)}-appgw-waf'
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.networkEdge)
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    tags: tags
    managedRules: {
      managedRuleSets: appGatewayConfig.wafManagedRuleSets
    }
    policySettings: appGatewayConfig.wafPolicySettings
  }
}

module appGw 'modules/07-edge/application-gateway.bicep' = if (useApplicationGatewayIngress) {
  name: '${uniqueString(deployment().name, location)}-appGw'
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.networkEdge)
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    tags: tags
    sku: appGatewayConfig.sku
    capacity: appGatewayConfig.capacity
    autoscaleMinCapacity: appGatewayConfig.autoscaleMinCapacity
    autoscaleMaxCapacity: appGatewayConfig.autoscaleMaxCapacity
    enableHttp2: appGatewayConfig.enableHttp2
    enableFips: appGatewayConfig.enableFips
    enableRequestBuffering: appGatewayConfig.enableRequestBuffering
    enableResponseBuffering: appGatewayConfig.enableResponseBuffering
    availabilityZones: appGatewayConfig.availabilityZones
    firewallPolicyResourceId: appGwWafPolicy!.outputs.resourceId
    diagnosticSettings: appGatewayConfig.diagnosticSettings
    lock: appGatewayConfig.?lock
    roleAssignments: appGatewayConfig.roleAssignments
    managedIdentities: appGatewayConfig.managedIdentities
    sslCertificates: appGatewayConfig.sslCertificates
    trustedRootCertificates: appGatewayConfig.trustedRootCertificates
    sslPolicyType: appGatewayConfig.sslPolicyType
    sslPolicyName: appGatewayConfig.sslPolicyName
    sslPolicyMinProtocolVersion: appGatewayConfig.sslPolicyMinProtocolVersion
    sslPolicyCipherSuites: appGatewayConfig.sslPolicyCipherSuites
    authenticationCertificates: appGatewayConfig.authenticationCertificates
    customErrorConfigurations: appGatewayConfig.customErrorConfigurations
    loadDistributionPolicies: appGatewayConfig.loadDistributionPolicies
    gatewayIPConfigurations: appGatewayConfig.gatewayIPConfigurations
    frontendIPConfigurations: appGatewayConfig.frontendIPConfigurations
    frontendPorts: appGatewayConfig.frontendPorts
    backendAddressPools: appGatewayConfig.backendAddressPools
    backendHttpSettingsCollection: appGatewayConfig.backendHttpSettingsCollection
    probes: appGatewayConfig.probes
    httpListeners: appGatewayConfig.httpListeners
    privateEndpoints: appGatewayConfig.privateEndpoints
    privateLinkConfigurations: appGatewayConfig.privateLinkConfigurations
    redirectConfigurations: appGatewayConfig.redirectConfigurations
    rewriteRuleSets: appGatewayConfig.rewriteRuleSets
    sslProfiles: appGatewayConfig.sslProfiles
    trustedClientCertificates: appGatewayConfig.trustedClientCertificates
    urlPathMaps: appGatewayConfig.urlPathMaps
    backendSettingsCollection: appGatewayConfig.backendSettingsCollection
    listeners: appGatewayConfig.listeners
    routingRules: appGatewayConfig.routingRules
    requestRoutingRules: appGatewayConfig.requestRoutingRules
  }
}

// ======================== //
// Supporting Services      //
// ======================== //

module keyVault 'modules/06-secrets/key-vault.bicep' = {
  name: '${uniqueString(deployment().name, location)}-keyVault'
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.operations)
  params: {
    systemAbbreviation: systemAbbreviation
    environmentAbbreviation: environmentAbbreviation
    instanceNumber: instanceNumber
    workloadDescription: workloadDescription
    location: location
    tags: tags
    sku: keyVaultConfig.sku
    networkAcls: keyVaultConfig.networkAcls
    softDeleteRetentionInDays: keyVaultConfig.softDeleteRetentionInDays
    enablePurgeProtection: keyVaultConfig.enablePurgeProtection
    publicNetworkAccess: keyVaultConfig.publicNetworkAccess
    enableVaultForDeployment: keyVaultConfig.enableVaultForDeployment
    enableVaultForTemplateDeployment: keyVaultConfig.enableVaultForTemplateDeployment
    enableVaultForDiskEncryption: keyVaultConfig.enableVaultForDiskEncryption
    createMode: keyVaultConfig.createMode
    secrets: keyVaultConfig.?secrets
    keys: keyVaultConfig.?keys
    enableDefaultPrivateEndpoint: privateNetworkingEnabled
    defaultPrivateEndpointSubnetResourceId: networking.outputs.?snetPeResourceId
    defaultPrivateNetworkingResourceGroupName: resourceGroupNameMap.network
    defaultPrivateDnsZoneVirtualNetworkLinks: postgreSqlPrivateDnsZoneLinks
    diagnosticSettings: keyVaultConfig.diagnosticSettings
    lock: keyVaultConfig.?lock
    roleAssignments: keyVaultConfig.roleAssignments
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
          principalId: appServiceConfig.managedIdentities.?systemAssigned ?? false
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
  dependsOn: [
    resourceGroups
  ]
  scope: resourceGroup(resourceGroupNameMap.data)
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
    delegatedSubnetResourceId: postgreSqlPrivateAccessEnabled ? networking.outputs.?snetPostgreSqlResourceId : null
    privateDnsZoneVirtualNetworkLinks: postgreSqlPrivateDnsZoneLinks
    privateDnsZoneResourceGroupName: resourceGroupNameMap.network
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

output networkResourceGroupName string = resourceGroupNameMap.network
output networkEdgeResourceGroupName string = resourceGroupNameMap.networkEdge
output hostingResourceGroupName string = resourceGroupNameMap.hosting
output dataResourceGroupName string = resourceGroupNameMap.data
output operationsResourceGroupName string = resourceGroupNameMap.operations
output spokeVNetResourceId string = networking.outputs.vnetSpokeResourceId
output spokeVnetName string = networking.outputs.vnetSpokeName
output keyVaultResourceId string = keyVault.outputs.resourceId
output keyVaultName string = keyVault.outputs.name
output webAppName string = webAppSite.outputs.name
output webAppHostName string = webAppSite.outputs.defaultHostname
output webAppResourceId string = webAppSite.outputs.resourceId
output webAppLocation string = webAppSite.outputs.location
output webAppManagedIdentityPrincipalId string = webAppSite.outputs.systemAssignedMIPrincipalId
output appServicePlanResourceId string = appServicePlanResourceId
output internalInboundIpAddress string? = aseLookup.?outputs.?internalInboundIpAddress
output aseName string? = aseEnvironment.?outputs.?name
output logAnalyticsWorkspaceUsedResourceId string = resolvedLogAnalyticsWorkspaceResourceId
output logAnalyticsWorkspaceCreatedName string? = logAnalyticsWorkspace.?outputs.?name
output postgreSqlAdminGroupObjectId string? = deployPostgreSql ? postgresqlAdminGroupConfig.objectId : null
output postgreSqlAdminGroupName string? = deployPostgreSql ? postgresqlAdminGroupConfig.displayName : null
output postgreSqlServerName string? = postgreSql.?outputs.?name
output postgreSqlServerResourceId string? = deployPostgreSql ? postgreSql!.outputs.resourceId : null
output postgreSqlServerFqdn string? = deployPostgreSql ? postgreSql!.outputs.fqdn : null
output postgreSqlPrivateDnsZoneName string? = postgreSqlPrivateAccessEnabled ? postgreSql!.outputs.privateDnsZoneName! : null
