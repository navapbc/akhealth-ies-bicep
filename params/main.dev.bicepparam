using '../main.bicep'

// Starter parameter file
// Add or override more configuration blocks here as needed.

param workloadName = '456ERT'
param location = 'eastus2'
param environmentName = 'dev'
param systemAbbreviation = 'iep'
param environmentAbbreviation = 'dev'
param instanceNumber = '001'
param workloadDescription = ''

param deployPrivateNetworking = true
param deployPostgreSql = true

param tags = {
  environment: 'dev'
  workload: '456TRF'
  managedBy: 'bicepparam'
}

param spokeNetworkConfig = {
  ingressOption: 'frontDoor' //options are none, frontDoor, applicationGateway
  vnetAddressSpace: '10.240.0.0/20'
  appSvcSubnetAddressSpace: '10.240.0.0/26'
  privateEndpointSubnetAddressSpace: '10.240.11.0/24'
  postgreSqlPrivateAccessConfig: {
    subnetAddressSpace: '10.240.10.0/28'
  }
  enableEgressLockdown: false
  dnsServers: []
  disableBgpRoutePropagation: true
  encryption: false
  encryptionEnforcement: 'AllowUnencrypted'
  flowTimeoutInMinutes: 0
  enableVmProtection: false
  enablePrivateEndpointVNetPolicies: 'Disabled'
  roleAssignments: []
  diagnosticSettings: []

  // Example hub peering configuration. Leave commented out unless you want to
  // override the default spoke-to-hub configs
  //
  // hubPeeringConfig: {
  //   virtualNetworkResourceId: '/subscriptions/<subscription-id>/resourceGroups/<hub-rg>/providers/Microsoft.Network/virtualNetworks/<hub-vnet>'
  //   virtualNetworkName: '<hub-vnet>'
  //   resourceGroupName: '<hub-rg>'
  //   subscriptionId: '<subscription-id>'
  //   allowForwardedTraffic: false
  //   allowGatewayTransit: false
  //   allowVirtualNetworkAccess: true
  //   doNotVerifyRemoteGateways: true
  //   useRemoteGateways: false
  //   reversePeeringConfig: {
  //     allowForwardedTraffic: true
  //     allowGatewayTransit: false
  //     allowVirtualNetworkAccess: true
  //     doNotVerifyRemoteGateways: true
  //     useRemoteGateways: false
  //   }
  // }
  //
  // applicationGatewayConfig: {
  //   subnetAddressSpace: '10.240.12.0/24'
  // }
  //
  // egressFirewallConfig: {
  //   internalIp: '10.0.0.4'
  // }
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

  // Example app settings configuration. Keep final literal settings in
  // `properties`. Use `useSolutionApplicationInsights` when you want this
  // solution's App Insights component to provide
  // `APPLICATIONINSIGHTS_CONNECTION_STRING`. Use `applicationInsights`
  // when the upstream component already exists outside this deployment.
  //
  // configs: [
  //   {
  //     name: 'appsettings'
  //     existingFunctionHostStorageAccount: {
  //       name: 'stexample001'
  //       resourceGroupName: 'rg-example'
  //     }
  //     applicationInsights: {
  //       name: 'appi-example'
  //       resourceGroupName: 'rg-example'
  //     }
  //     properties: {
  //       ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
  //     }
  //   }
  // ]

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
  //         resourceGroupSubscriptionId: '<subscription-id>'
  //         resourceGroupName: '<rg>'
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
// override the default Key Vault configs
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

//the group defined here cant be deployed in this worload set of templates
//as groups are a tenant scoped resource
param postgresqlAdminGroupConfig = {
  objectId: 'b58ff011-4384-42b9-b25c-26c5dfc26b06'
  displayName: 'secgrp-iep-eus2-dev-pgsqladmin-001'
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
  grantAppServiceIdentityReaderRole: true
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
  loadDistributionPolicies: []
  gatewayIPConfigurations: []
  frontendIPConfigurations: []
  frontendPorts: []
  backendAddressPools: []
  backendHttpSettingsCollection: []
  probes: []
  httpListeners: []
  privateEndpoints: []
  privateLinkConfigurations: []
  redirectConfigurations: []
  rewriteRuleSets: []
  sslProfiles: []
  trustedClientCertificates: []
  urlPathMaps: []
  backendSettingsCollection: []
  listeners: []
  requestRoutingRules: []
  routingRules: []
  roleAssignments: []
  diagnosticSettings: []
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
  customDomains: []
  ruleSets: []
  secrets: []
  roleAssignments: []
  originResponseTimeoutSeconds: 120
  autoApprovePrivateEndpoint: true
  afdPeAutoApproverIsolationScope: 'Regional'
  originGroups: [
    {
      name: 'app-default'
      healthProbeSettings: {
        probePath: '/'
        probeIntervalInSeconds: 100
        probeRequestType: 'GET'
        probeProtocol: 'Https'
      }
      loadBalancingSettings: {
        sampleSize: 4
        successfulSamplesRequired: 3
        additionalLatencyInMilliseconds: 50
      }
      sessionAffinityState: 'Disabled'
      trafficRestorationTimeToHealedOrNewEndpointsInMinutes: 10
      origins: [
        {
          name: 'app-default'
          httpPort: 80
          httpsPort: 443
          priority: 1
          weight: 1000
          enabledState: 'Enabled'
          enforceCertificateNameCheck: true
          sharedPrivateLink: {
            requestMessage: 'frontdoor'
            groupId: 'sites'
          }
        }
      ]
    }
  ]
  afdEndpoints: [
    {
      name: 'default'
      autoGeneratedDomainNameLabelScope: 'TenantReuse'
      enabledState: 'Enabled'
      routes: [
        {
          name: 'default'
          originGroupName: 'app-default'
          patternsToMatch: [
            '/*'
          ]
          forwardingProtocol: 'HttpsOnly'
          linkToDefaultDomain: 'Enabled'
          httpsRedirect: 'Enabled'
          enabledState: 'Enabled'
          supportedProtocols: [
            'Http'
            'Https'
          ]
        }
      ]
    }
  ]
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
  roleAssignments: []
  diagnosticSettings: []
}
