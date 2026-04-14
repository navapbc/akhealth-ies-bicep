using '../../main.bicep'

// Parameter examples reference
// Copy the shapes you need into an active environment param file such as
// params/main.dev.bicepparam and adjust the values for your workload.

param workloadDescription = ''

param spokeNetworkConfig = {
  ingressOption: 'frontDoor'
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
}

param servicePlanConfig = {
  sku: 'B1'
  skuCapacity: 1
  zoneRedundant: false
  osFamily: 'windows'
  existingPlanId: ''
  workerTierName: null
  elasticScaleEnabled: false
  maximumElasticWorkerCount: 1
  perSiteScaling: false
  targetWorkerCount: 1
  targetWorkerSize: 0
  virtualNetworkSubnetId: null
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
}

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
  roleAssignments: []
  diagnosticSettings: []
}

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

// Example fuller PostgreSQL HA/private-access configuration:
// param postgresqlConfig = {
//   workloadDescription: 'postgresql'
//   privateAccessMode: 'delegatedSubnet'
//   skuName: 'Standard_D2s_v3'
//   tier: 'GeneralPurpose'
//   availabilityZone: 1
//   highAvailabilityZone: 2
//   highAvailability: 'ZoneRedundant'
//   backupRetentionDays: 14
//   geoRedundantBackup: 'Disabled'
//   storageSizeGB: 128
//   autoGrow: 'Enabled'
//   version: '17'
//   publicNetworkAccess: 'Disabled'
//   grantAppServiceIdentityReaderRole: true
//   databases: [
//     {
//       name: 'appdb'
//       charset: 'UTF8'
//       collation: 'en_US.utf8'
//     }
//   ]
//   configurations: [
//     {
//       name: 'pgaudit.log'
//       source: 'user-override'
//       value: 'READ,WRITE'
//     }
//   ]
//   roleAssignments: []
//   diagnosticSettings: []
// }

// Example customized PostgreSQL databases/configurations:
// param postgresqlConfig = {
//   workloadDescription: 'postgresql'
//   privateAccessMode: 'delegatedSubnet'
//   skuName: 'Standard_B2s'
//   tier: 'Burstable'
//   availabilityZone: -1
//   highAvailabilityZone: -1
//   highAvailability: 'Disabled'
//   backupRetentionDays: 7
//   geoRedundantBackup: 'Disabled'
//   storageSizeGB: 64
//   autoGrow: 'Enabled'
//   version: '18'
//   publicNetworkAccess: 'Disabled'
//   grantAppServiceIdentityReaderRole: true
//   databases: [
//     {
//       name: 'appdb'
//       charset: 'UTF8'
//       collation: 'en_US.utf8'
//     }
//     {
//       name: 'jobdb'
//       charset: 'UTF8'
//       collation: 'en_US.utf8'
//     }
//   ]
//   configurations: [
//     {
//       name: 'pg_qs.query_capture_mode'
//       source: 'user-override'
//       value: 'TOP'
//     }
//     {
//       name: 'log_min_duration_statement'
//       source: 'user-override'
//       value: '1000'
//     }
//   ]
//   roleAssignments: []
//   diagnosticSettings: []
// }

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

// Example Front Door public-origin configuration:
// param frontDoorConfig = {
//   managedIdentities: {
//     systemAssigned: true
//   }
//   enableDefaultWafMethodBlock: true
//   wafCustomRules: {}
//   sku: 'Premium_AzureFrontDoor'
//   wafPolicySettings: {
//     enabledState: 'Enabled'
//     mode: 'Prevention'
//     requestBodyCheck: 'Enabled'
//   }
//   wafManagedRuleSets: [
//     {
//       ruleSetType: 'Microsoft_DefaultRuleSet'
//       ruleSetVersion: '2.1'
//       ruleSetAction: 'Block'
//       ruleGroupOverrides: []
//     }
//     {
//       ruleSetType: 'Microsoft_BotManagerRuleSet'
//       ruleSetVersion: '1.0'
//       ruleSetAction: 'Block'
//       ruleGroupOverrides: []
//     }
//   ]
//   customDomains: []
//   ruleSets: []
//   secrets: []
//   roleAssignments: []
//   originResponseTimeoutSeconds: 120
//   autoApprovePrivateEndpoint: false
//   afdPeAutoApproverIsolationScope: 'None'
//   originGroups: [
//     {
//       name: 'app-public'
//       healthProbeSettings: {
//         probePath: '/'
//         probeIntervalInSeconds: 100
//         probeRequestType: 'GET'
//         probeProtocol: 'Https'
//       }
//       loadBalancingSettings: {
//         sampleSize: 4
//         successfulSamplesRequired: 3
//         additionalLatencyInMilliseconds: 50
//       }
//       sessionAffinityState: 'Disabled'
//       trafficRestorationTimeToHealedOrNewEndpointsInMinutes: 10
//       origins: [
//         {
//           name: 'app-public'
//           httpPort: 80
//           httpsPort: 443
//           priority: 1
//           weight: 1000
//           enabledState: 'Enabled'
//           enforceCertificateNameCheck: true
//         }
//       ]
//     }
//   ]
//   afdEndpoints: [
//     {
//       name: 'default'
//       autoGeneratedDomainNameLabelScope: 'TenantReuse'
//       enabledState: 'Enabled'
//       routes: [
//         {
//           name: 'public-default'
//           originGroupName: 'app-public'
//           patternsToMatch: [
//             '/*'
//           ]
//           forwardingProtocol: 'HttpsOnly'
//           linkToDefaultDomain: 'Enabled'
//           httpsRedirect: 'Enabled'
//           enabledState: 'Enabled'
//           supportedProtocols: [
//             'Http'
//             'Https'
//           ]
//         }
//       ]
//     }
//   ]
//   securityPatternsToMatch: [
//     '/*'
//   ]
//   diagnosticSettings: []
// }

// Example Front Door custom-domain, rule-set, and secret configuration:
// param frontDoorConfig = {
//   managedIdentities: {
//     systemAssigned: true
//   }
//   enableDefaultWafMethodBlock: true
//   wafCustomRules: {}
//   sku: 'Premium_AzureFrontDoor'
//   wafPolicySettings: {
//     enabledState: 'Enabled'
//     mode: 'Prevention'
//     requestBodyCheck: 'Enabled'
//   }
//   wafManagedRuleSets: [
//     {
//       ruleSetType: 'Microsoft_DefaultRuleSet'
//       ruleSetVersion: '2.1'
//       ruleSetAction: 'Block'
//       ruleGroupOverrides: []
//     }
//     {
//       ruleSetType: 'Microsoft_BotManagerRuleSet'
//       ruleSetVersion: '1.0'
//       ruleSetAction: 'Block'
//       ruleGroupOverrides: []
//     }
//   ]
//   customDomains: [
//     {
//       name: 'app-custom'
//       hostName: 'app-dev.example.org'
//       azureDnsZoneResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns-eus2-dev-001/providers/Microsoft.Network/dnsZones/example.org'
//       certificateType: 'CustomerCertificate'
//       minimumTlsVersion: 'TLS12'
//       secretName: 'app-custom-cert'
//     }
//   ]
//   ruleSets: [
//     {
//       name: 'security-headers'
//       rules: []
//     }
//   ]
//   secrets: [
//     {
//       name: 'app-custom-cert'
//       type: 'CustomerCertificate'
//       secretSourceResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sec-eus2-dev-001/providers/Microsoft.KeyVault/vaults/kv-iep-eus2-dev-001/secrets/frontdoor-cert'
//       useLatestVersion: true
//       subjectAlternativeNames: [
//         'app-dev.example.org'
//       ]
//     }
//   ]
//   roleAssignments: []
//   originResponseTimeoutSeconds: 120
//   autoApprovePrivateEndpoint: true
//   afdPeAutoApproverIsolationScope: 'Regional'
//   originGroups: [
//     {
//       name: 'app-default'
//       healthProbeSettings: {
//         probePath: '/'
//         probeIntervalInSeconds: 100
//         probeRequestType: 'GET'
//         probeProtocol: 'Https'
//       }
//       loadBalancingSettings: {
//         sampleSize: 4
//         successfulSamplesRequired: 3
//         additionalLatencyInMilliseconds: 50
//       }
//       sessionAffinityState: 'Disabled'
//       trafficRestorationTimeToHealedOrNewEndpointsInMinutes: 10
//       origins: [
//         {
//           name: 'app-default'
//           httpPort: 80
//           httpsPort: 443
//           priority: 1
//           weight: 1000
//           enabledState: 'Enabled'
//           enforceCertificateNameCheck: true
//           sharedPrivateLink: {
//             requestMessage: 'frontdoor'
//             groupId: 'sites'
//           }
//         }
//       ]
//     }
//   ]
//   afdEndpoints: [
//     {
//       name: 'default'
//       autoGeneratedDomainNameLabelScope: 'TenantReuse'
//       enabledState: 'Enabled'
//       routes: [
//         {
//           name: 'default'
//           originGroupName: 'app-default'
//           customDomainNames: [
//             'app-custom'
//           ]
//           patternsToMatch: [
//             '/*'
//           ]
//           forwardingProtocol: 'HttpsOnly'
//           linkToDefaultDomain: 'Disabled'
//           httpsRedirect: 'Enabled'
//           enabledState: 'Enabled'
//           ruleSets: [
//             'security-headers'
//           ]
//           supportedProtocols: [
//             'Http'
//             'Https'
//           ]
//         }
//       ]
//     }
//   ]
//   securityPatternsToMatch: [
//     '/*'
//   ]
//   diagnosticSettings: []
// }

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

// ======================== //
// Spoke Networking         //
// ======================== //

// Example hub peering configuration
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

// Example Application Gateway subnet planning block
//
// applicationGatewayConfig: {
//   subnetAddressSpace: '10.240.12.0/24'
// }

// Example egress firewall block
//
// egressFirewallConfig: {
//   internalIp: '10.0.0.4'
// }

// Example alternate private endpoint subnet policy
//
// enablePrivateEndpointVNetPolicies: 'Basic'

// ======================== //
// Service Plan             //
// ======================== //

// Example existing App Service Plan configuration
//
// param servicePlanConfig = {
//   sku: 'B1'
//   skuCapacity: 1
//   zoneRedundant: false
//   osFamily: 'windows'
//   existingPlanId: '/subscriptions/<subscription-id>/resourceGroups/<app-rg>/providers/Microsoft.Web/serverfarms/<plan-name>'
//   workerTierName: null
//   elasticScaleEnabled: false
//   maximumElasticWorkerCount: 1
//   perSiteScaling: false
//   targetWorkerCount: 1
//   targetWorkerSize: 0
//   virtualNetworkSubnetId: null
//   isCustomMode: false
//   rdpEnabled: false
//   installScripts: []
//   registryAdapters: []
//   storageMounts: []
//   managedIdentities: {
//     systemAssigned: false
//   }
//   roleAssignments: []
//   diagnosticSettings: []
// }

// Example custom-mode App Service Plan configuration
//
// param servicePlanConfig = {
//   sku: 'P1V3'
//   skuCapacity: 1
//   zoneRedundant: false
//   osFamily: 'windows'
//   existingPlanId: ''
//   workerTierName: null
//   elasticScaleEnabled: false
//   maximumElasticWorkerCount: 1
//   perSiteScaling: false
//   targetWorkerCount: 1
//   targetWorkerSize: 0
//   virtualNetworkSubnetId: '/subscriptions/<subscription-id>/resourceGroups/<spoke-rg>/providers/Microsoft.Network/virtualNetworks/<spoke-vnet>/subnets/<appsvc-subnet>'
//   isCustomMode: true
//   rdpEnabled: false
//   installScripts: []
//   registryAdapters: []
//   storageMounts: []
//   managedIdentities: {
//     systemAssigned: false
//   }
//   roleAssignments: []
//   diagnosticSettings: []
// }

// ======================== //
// Web App                  //
// ======================== //

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

// Example slot configuration
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
//   }
// ]

// ======================== //
// Key Vault                //
// ======================== //

// Example Key Vault configuration
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
// }

// ======================== //
// Monitoring               //
// ======================== //

// Example monitoring configuration
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

// ======================== //
// Application Gateway      //
// ======================== //

// Example minimal regional ingress configuration for
// spokeNetworkConfig.ingressOption = 'applicationGateway'
//
// Also update spokeNetworkConfig with:
// applicationGatewayConfig: {
//   subnetAddressSpace: '10.240.12.0/24'
// }
//
// param appGatewayConfig = {
//   sku: 'WAF_v2'
//   capacity: 2
//   autoscaleMinCapacity: 2
//   autoscaleMaxCapacity: 4
//   availabilityZones: [
//     1
//     2
//     3
//   ]
//   sslPolicyType: 'Custom'
//   sslPolicyName: ''
//   sslPolicyMinProtocolVersion: 'TLSv1_2'
//   sslPolicyCipherSuites: []
//   sslCertificates: []
//   managedIdentities: {
//     systemAssigned: false
//   }
//   trustedRootCertificates: []
//   authenticationCertificates: []
//   customErrorConfigurations: []
//   enableHttp2: true
//   enableFips: false
//   enableRequestBuffering: false
//   enableResponseBuffering: false
//   loadDistributionPolicies: []
//   gatewayIPConfigurations: [
//     {
//       name: 'appGateway'
//       properties: {
//         subnet: {
//           id: '/subscriptions/<subscription-id>/resourceGroups/<spoke-rg>/providers/Microsoft.Network/virtualNetworks/<spoke-vnet>/subnets/<appgw-subnet>'
//         }
//       }
//     }
//   ]
//   frontendIPConfigurations: [
//     {
//       name: 'public'
//       properties: {
//         publicIPAddress: {
//           id: '/subscriptions/<subscription-id>/resourceGroups/<spoke-rg>/providers/Microsoft.Network/publicIPAddresses/<appgw-pip>'
//         }
//       }
//     }
//   ]
//   frontendPorts: [
//     {
//       name: 'https-443'
//       properties: {
//         port: 443
//       }
//     }
//   ]
//   backendAddressPools: [
//     {
//       name: 'webapp'
//       properties: {
//         backendAddresses: [
//           {
//             fqdn: '<web-app-default-hostname>'
//           }
//         ]
//       }
//     }
//   ]
//   backendHttpSettingsCollection: [
//     {
//       name: 'https'
//       properties: {
//         port: 443
//         protocol: 'Https'
//         requestTimeout: 30
//         probeEnabled: true
//         probe: {
//           id: '/subscriptions/<subscription-id>/resourceGroups/<spoke-rg>/providers/Microsoft.Network/applicationGateways/<appgw-name>/probes/healthz'
//         }
//       }
//     }
//   ]
//   probes: [
//     {
//       name: 'healthz'
//       properties: {
//         protocol: 'Https'
//         path: '/healthz'
//         interval: 30
//         timeout: 30
//         unhealthyThreshold: 3
//         pickHostNameFromBackendHttpSettings: true
//         match: {
//           statusCodes: [
//             '200-399'
//           ]
//         }
//       }
//     }
//   ]
//   httpListeners: [
//     {
//       name: 'https'
//       properties: {
//         frontendIPConfiguration: {
//           id: '/subscriptions/<subscription-id>/resourceGroups/<spoke-rg>/providers/Microsoft.Network/applicationGateways/<appgw-name>/frontendIPConfigurations/public'
//         }
//         frontendPort: {
//           id: '/subscriptions/<subscription-id>/resourceGroups/<spoke-rg>/providers/Microsoft.Network/applicationGateways/<appgw-name>/frontendPorts/https-443'
//         }
//         protocol: 'Https'
//         sslCertificate: {
//           id: '/subscriptions/<subscription-id>/resourceGroups/<spoke-rg>/providers/Microsoft.Network/applicationGateways/<appgw-name>/sslCertificates/<certificate-name>'
//         }
//       }
//     }
//   ]
//   privateEndpoints: []
//   privateLinkConfigurations: []
//   redirectConfigurations: []
//   rewriteRuleSets: []
//   sslProfiles: []
//   trustedClientCertificates: []
//   urlPathMaps: []
//   backendSettingsCollection: []
//   listeners: []
//   requestRoutingRules: [
//     {
//       name: 'default'
//       properties: {
//         ruleType: 'Basic'
//         priority: 100
//         httpListener: {
//           id: '/subscriptions/<subscription-id>/resourceGroups/<spoke-rg>/providers/Microsoft.Network/applicationGateways/<appgw-name>/httpListeners/https'
//         }
//         backendAddressPool: {
//           id: '/subscriptions/<subscription-id>/resourceGroups/<spoke-rg>/providers/Microsoft.Network/applicationGateways/<appgw-name>/backendAddressPools/webapp'
//         }
//         backendHttpSettings: {
//           id: '/subscriptions/<subscription-id>/resourceGroups/<spoke-rg>/providers/Microsoft.Network/applicationGateways/<appgw-name>/backendHttpSettingsCollection/https'
//         }
//       }
//     }
//   ]
//   routingRules: []
//   roleAssignments: []
//   diagnosticSettings: []
//   wafPolicySettings: {
//     mode: 'Prevention'
//     state: 'Enabled'
//     requestBodyCheck: true
//     maxRequestBodySizeInKb: 128
//     fileUploadLimitInMb: 100
//   }
//   wafManagedRuleSets: [
//     {
//       ruleSetType: 'OWASP'
//       ruleSetVersion: '3.2'
//     }
//     {
//       ruleSetType: 'Microsoft_BotManagerRuleSet'
//       ruleSetVersion: '1.0'
//     }
//   ]
// }

// Example fuller regional ingress configuration for
// spokeNetworkConfig.ingressOption = 'applicationGateway'
//
// param appGatewayConfig = {
//   sku: 'WAF_v2'
//   capacity: 2
//   autoscaleMinCapacity: 2
//   autoscaleMaxCapacity: 10
//   availabilityZones: [
//     1
//     2
//     3
//   ]
//   sslPolicyType: 'Custom'
//   sslPolicyName: ''
//   sslPolicyMinProtocolVersion: 'TLSv1_2'
//   sslPolicyCipherSuites: []
//   sslCertificates: []
//   managedIdentities: {
//     systemAssigned: false
//   }
//   trustedRootCertificates: []
//   authenticationCertificates: []
//   customErrorConfigurations: []
//   enableHttp2: true
//   enableFips: false
//   enableRequestBuffering: false
//   enableResponseBuffering: false
//   loadDistributionPolicies: []
//   gatewayIPConfigurations: []
//   frontendIPConfigurations: []
//   frontendPorts: []
//   backendAddressPools: []
//   backendHttpSettingsCollection: []
//   probes: []
//   httpListeners: []
//   privateEndpoints: []
//   privateLinkConfigurations: []
//   redirectConfigurations: []
//   rewriteRuleSets: []
//   sslProfiles: []
//   trustedClientCertificates: []
//   urlPathMaps: []
//   backendSettingsCollection: []
//   listeners: []
//   requestRoutingRules: []
//   routingRules: []
//   roleAssignments: []
//   diagnosticSettings: []
//   wafPolicySettings: {
//     mode: 'Prevention'
//     state: 'Enabled'
//     requestBodyCheck: true
//     maxRequestBodySizeInKb: 128
//     fileUploadLimitInMb: 100
//   }
//   wafManagedRuleSets: [
//     {
//       ruleSetType: 'OWASP'
//       ruleSetVersion: '3.2'
//     }
//     {
//       ruleSetType: 'Microsoft_BotManagerRuleSet'
//       ruleSetVersion: '1.0'
//     }
//   ]
// }

// ======================== //
// App Service Environment  //
// ======================== //

// Example fuller App Service Environment configuration for deployAseV3 = true
//
// param aseConfig = {
//   clusterSettings: [
//     {
//       name: 'DisableTls1.0'
//       value: '1'
//     }
//   ]
//   customDnsSuffix: 'apps.example.com'
//   customDnsSuffixCertificateUrl: 'https://<key-vault-name>.vault.azure.net/secrets/<certificate-secret>/<version>'
//   ipsslAddressCount: 2
//   multiSize: 'Medium'
//   dedicatedHostCount: 0
//   dnsSuffix: ''
//   frontEndScaleFactor: 15
//   internalLoadBalancingMode: 'Web, Publishing'
//   zoneRedundant: true
//   allowNewPrivateEndpointConnections: true
//   ftpEnabled: false
//   inboundIpAddressOverride: ''
//   remoteDebugEnabled: false
//   upgradePreference: 'None'
//   roleAssignments: []
//   diagnosticSettings: []
// }
