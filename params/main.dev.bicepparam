using '../main.bicep'

// Starter parameter file
// Add or override more configuration blocks here as needed.

param workloadName = '456ERT'
param location = 'eastus'
param environmentName = 'dev'
param systemAbbreviation = 'iep'
param environmentAbbreviation = 'dev'
param instanceNumber = '001'
param workloadDescription = ''

param deployPrivateNetworking = false
param deployFrontDoor = false
param deployPostgreSql = false

param tags = {
  environment: 'dev'
  workload: '456TRF'
  managedBy: 'bicepparam'
}

param spokeNetworkConfig = {
  ingressOption: 'frontDoor'
  vnetAddressSpace: '10.240.0.0/20'
  appSvcSubnetAddressSpace: '10.240.0.0/26'
  privateEndpointSubnetAddressSpace: '10.240.11.0/24'
  appGwSubnetAddressSpace: ''
  postgresSubnetAddressSpace: ''
  hubVnetResourceId: ''
  hubPeeringAllowForwardedTraffic: false
  hubPeeringAllowGatewayTransit: false
  hubPeeringAllowVirtualNetworkAccess: true
  hubPeeringDoNotVerifyRemoteGateways: true
  hubPeeringUseRemoteGateways: false
  hubRemotePeeringEnabled: false
  hubRemotePeeringAllowForwardedTraffic: true
  hubRemotePeeringAllowGatewayTransit: false
  hubRemotePeeringAllowVirtualNetworkAccess: true
  hubRemotePeeringDoNotVerifyRemoteGateways: true
  hubRemotePeeringUseRemoteGateways: false
  firewallInternalIp: ''
  enableEgressLockdown: false
  dnsServers: []
  ddosProtectionPlanResourceId: ''
  disableBgpRoutePropagation: true
  encryption: false
  encryptionEnforcement: 'AllowUnencrypted'
  flowTimeoutInMinutes: 0
  enableVmProtection: false
  enablePrivateEndpointVNetPolicies: 'Disabled'
  bgpCommunity: ''
  roleAssignments: []
  diagnosticSettings: []

  // Example hub peering configuration. Leave commented out unless you want to
  // override the default spoke-to-hub configs
  //
  // hubVnetResourceId: '/subscriptions/<subscription-id>/resourceGroups/<hub-rg>/providers/Microsoft.Network/virtualNetworks/<hub-vnet>'
  // hubPeeringAllowForwardedTraffic: false
  // hubPeeringAllowGatewayTransit: false
  // hubPeeringAllowVirtualNetworkAccess: true
  // hubPeeringDoNotVerifyRemoteGateways: true
  // hubPeeringUseRemoteGateways: false
  //
  // hubRemotePeeringEnabled: true
  // hubRemotePeeringAllowForwardedTraffic: true
  // hubRemotePeeringAllowGatewayTransit: false
  // hubRemotePeeringAllowVirtualNetworkAccess: true
  // hubRemotePeeringDoNotVerifyRemoteGateways: true
  // hubRemotePeeringUseRemoteGateways: false
  //
  // enablePrivateEndpointVNetPolicies: 'Basic'
}

param servicePlanConfig = {
  sku: 'B1'
  skuCapacity: 1
  zoneRedundant: false
  kind: 'windows'
  existingPlanId: ''
  workerTierName: ''
  elasticScaleEnabled: false
  maximumElasticWorkerCount: 1
  perSiteScaling: false
  targetWorkerCount: 1
  targetWorkerSize: 0
  virtualNetworkSubnetId: ''
  isCustomMode: false
  rdpEnabled: false
  installScripts: []
  registryAdapters: []
  storageMounts: []
  managedIdentities: {
    systemAssigned: false
  }
  roleAssignments: []
  diagnosticSettings: []
}

param appServiceConfig = {
  kind: 'app'
  httpsOnly: true
  clientCertEnabled: false
  disableBasicPublishingCredentials: true
  publicNetworkAccess: 'Disabled'
  redundancyMode: 'None'
  scmSiteAlsoStopped: false
  siteConfig: {
    alwaysOn: false
    ftpsState: 'FtpsOnly'
    minTlsVersion: '1.2'
    healthCheckPath: '/healthz'
    http20Enabled: true
  }
  hyperV: false
  managedIdentities: {
    systemAssigned: true
  }
  enabled: true
  storageAccountRequired: false
  reserved: false
  clientAffinityEnabled: false
  clientAffinityProxyEnabled: true
  clientAffinityPartitioningEnabled: false
  diagnosticSettings: []
  slots: []
  configs: []
  privateEndpoints: []

  // Example slot configuration. Leave commented out unless you want to
  // override the default staging slot configs
  //
  // slots: [
  //   {
  //     name: 'staging'
  //     enabled: true
  //     clientAffinityEnabled: false
  //     managedIdentities: {
  //       systemAssigned: true
  //     }
  //     hyperV: false
  //     customDomainVerificationId: 'custom-domain-verification-id'
  //     privateEndpoints: [
  //       {
  //         name: 'webApp-slot'
  //         subnetResourceId: '/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<subnet>'
  //         privateDnsZoneGroup: {
  //           name: 'webApp-slot'
  //           privateDnsZoneGroupConfigs: [
  //             {
  //               name: 'privatelink.azurewebsites.net'
  //               privateDnsZoneResourceId: '/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net'
  //             }
  //           ]
  //         }
  //       }
  //     ]
  //   }
  // ]
}

// Example Key Vault configuration. Leave commented out unless you want to
// override the default Key Vault bconfigs
//
// param keyVaultConfig = {
//   sku: 'standard'
//   enablePurgeProtection: true
//   softDeleteRetentionInDays: 90
//   publicNetworkAccess: 'Disabled'
//   enableVaultForDeployment: true
//   enableVaultForTemplateDeployment: true
//   enableVaultForDiskEncryption: true
//   networkAcls: {
//     bypass: 'AzureServices'
//     defaultAction: 'Deny'
//     ipRules: []
//     virtualNetworkRules: []
//   }
//   privateEndpoints: [
//     {
//       name: 'keyvault-pep'
//       subnetResourceId: '/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<subnet>'
//       privateDnsZoneGroup: {
//         privateDnsZoneGroupConfigs: [
//           {
//             privateDnsZoneResourceId: '/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net'
//           }
//         ]
//       }
//     }
//   ]
// }

param keyVaultConfig = {
  enablePurgeProtection: false
  softDeleteRetentionInDays: 90
  createMode: 'default'
  sku: 'standard'
  enableVaultForDeployment: true
  enableVaultForTemplateDeployment: true
  enableVaultForDiskEncryption: true
  publicNetworkAccess: 'Disabled'
  networkAcls: {
    bypass: 'AzureServices'
    defaultAction: 'Deny'
  }
  privateEndpoints: []
  roleAssignments: []
  diagnosticSettings: []
}

// Example monitoring configuration. Leave commented out unless you want to
// override the default monitoring configs 
//
// param logAnalyticsConfig = {
//   sku: 'PerGB2018'
//   retentionInDays: 365
//   enableLogAccessUsingOnlyResourcePermissions: false
//   disableLocalAuth: true
//   publicNetworkAccessForIngestion: 'Enabled'
//   publicNetworkAccessForQuery: 'Enabled'
// }
//
// param appInsightsConfig = {
//   applicationType: 'web'
//   publicNetworkAccessForIngestion: 'Enabled'
//   publicNetworkAccessForQuery: 'Enabled'
//   retentionInDays: 90
//   samplingPercentage: 100
//   disableLocalAuth: true
//   disableIpMasking: true
//   forceCustomerStorageForProfiler: false
//   kind: 'web'
// }

param appInsightsConfig = {
  applicationType: 'web'
  publicNetworkAccessForIngestion: 'Enabled'
  publicNetworkAccessForQuery: 'Enabled'
  retentionInDays: 90
  samplingPercentage: 100
  disableLocalAuth: true
  disableIpMasking: true
  forceCustomerStorageForProfiler: false
  kind: 'web'
  roleAssignments: []
  diagnosticSettings: []
}

param postgresqlAdminGroupConfig = {
  workloadDescription: 'postgresqladmin'
  description: 'Administrators for the workload PostgreSQL flexible server.'
  members: []
  owners: []
}

param postgresqlConfig = {
  workloadDescription: 'postgresql'
  privateAccessMode: 'delegatedSubnet'
  skuName: 'Standard_B1ms'
  tier: 'Burstable'
  availabilityZone: -1
  highAvailabilityZone: -1
  highAvailability: 'Disabled'
  backupRetentionDays: 7
  geoRedundantBackup: 'Disabled'
  storageSizeGB: 32
  autoGrow: 'Enabled'
  version: '18'
  publicNetworkAccess: 'Disabled'
  databases: [
    {
      name: 'appdb'
    }
  ]
  configurations: []
  roleAssignments: []
  diagnosticSettings: []
}

param appGatewayConfig = {
  sku: 'WAF_v2'
  capacity: 2
  autoscaleMinCapacity: 2
  autoscaleMaxCapacity: 10
  availabilityZones: [
    1
    2
    3
  ]
  sslPolicyType: 'Custom'
  sslPolicyName: ''
  sslPolicyMinProtocolVersion: 'TLSv1_2'
  sslPolicyCipherSuites: []
  sslCertificates: []
  managedIdentities: {
    systemAssigned: false
  }
  trustedRootCertificates: []
  authenticationCertificates: []
  customErrorConfigurations: []
  enableHttp2: true
  enableFips: false
  enableRequestBuffering: false
  enableResponseBuffering: false
  healthProbePath: '/healthz'
  loadDistributionPolicies: []
  privateEndpoints: []
  privateLinkConfigurations: []
  redirectConfigurations: []
  rewriteRuleSets: []
  sslProfiles: []
  trustedClientCertificates: []
  urlPathMaps: []
  backendSettingsCollection: []
  listeners: []
  routingRules: []
  roleAssignments: []
  diagnosticSettings: []
  backendRequestTimeout: 120
  probeInterval: 30
  probeTimeout: 30
  probeUnhealthyThreshold: 3
  wafPolicySettings: {
    mode: 'Prevention'
    state: 'Enabled'
    requestBodyCheck: true
    maxRequestBodySizeInKb: 128
    fileUploadLimitInMb: 100
  }
  wafManagedRuleSets: [
    {
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
    }
    {
      ruleSetType: 'Microsoft_BotManagerRuleSet'
      ruleSetVersion: '1.0'
    }
  ]
}

param frontDoorConfig = {
  managedIdentities: {
    systemAssigned: true
  }
  enableDefaultWafMethodBlock: true
  wafCustomRules: {}
  sku: 'Premium_AzureFrontDoor'
  wafPolicySettings: {
    enabledState: 'Enabled'
    mode: 'Prevention'
    requestBodyCheck: 'Enabled'
  }
  wafManagedRuleSets: [
    {
      ruleSetType: 'Microsoft_DefaultRuleSet'
      ruleSetVersion: '2.1'
      ruleSetAction: 'Block'
      ruleGroupOverrides: []
    }
    {
      ruleSetType: 'Microsoft_BotManagerRuleSet'
      ruleSetVersion: '1.0'
      ruleSetAction: 'Block'
      ruleGroupOverrides: []
    }
  ]
  healthProbePath: '/'
  healthProbeIntervalInSeconds: 100
  customDomains: []
  ruleSets: []
  secrets: []
  roleAssignments: []
  originResponseTimeoutSeconds: 120
  autoApprovePrivateEndpoint: true
  afdPeAutoApproverIsolationScope: 'Regional'
  endpointEnabledState: 'Enabled'
  routePatternsToMatch: [
    '/*'
  ]
  routeForwardingProtocol: 'HttpsOnly'
  routeLinkToDefaultDomain: 'Enabled'
  routeHttpsRedirect: 'Enabled'
  routeEnabledState: 'Enabled'
  originHttpPort: 80
  originHttpsPort: 443
  originPriority: 1
  originWeight: 1000
  originEnabledState: 'Enabled'
  originEnforceCertificateNameCheck: true
  sharedPrivateLinkRequestMessage: 'frontdoor'
  sharedPrivateLinkGroupId: 'sites'
  loadBalancingSampleSize: 4
  loadBalancingSuccessfulSamplesRequired: 3
  loadBalancingAdditionalLatencyInMilliseconds: 50
  healthProbeRequestType: 'GET'
  healthProbeProtocol: 'Https'
  sessionAffinityState: 'Disabled'
  trafficRestorationTimeToHealedOrNewEndpointsInMinutes: 10
  securityPatternsToMatch: [
    '/*'
  ]
  diagnosticSettings: []
}

param aseConfig = {
  clusterSettings: [
    {
      name: 'DisableTls1.0'
      value: '1'
    }
  ]
  customDnsSuffix: ''
  ipsslAddressCount: 0
  multiSize: ''
  customDnsSuffixCertificateUrl: ''
  customDnsSuffixKeyVaultReferenceIdentity: ''
  dedicatedHostCount: 0
  dnsSuffix: ''
  frontEndScaleFactor: 15
  internalLoadBalancingMode: 'Web, Publishing'
  zoneRedundant: true
  allowNewPrivateEndpointConnections: true
  ftpEnabled: false
  inboundIpAddressOverride: ''
  remoteDebugEnabled: false
  upgradePreference: 'None'
  roleAssignments: []
  diagnosticSettings: []
}
param logAnalyticsConfig = {
  sku: 'PerGB2018'
  retentionInDays: 365
  enableLogAccessUsingOnlyResourcePermissions: false
  disableLocalAuth: true
  publicNetworkAccessForIngestion: 'Enabled'
  publicNetworkAccessForQuery: 'Enabled'
}
