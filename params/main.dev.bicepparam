using '../main.bicep'

// ======================== //
// Deployment Info.         //
// ======================== //

param location = 'westus2'
param systemAbbreviation = 'iep'
param environmentAbbreviation = 'dev'
param instanceNumber = '005'
param workloadDescription = ''

// ======================== //
// Deployment Toggles      //
// ======================== //

param deployAseV3 = false
param deployPrivateNetworking = true
param deployPostgreSql = false

// ======================== //
// Subscription Setup       //
// ======================== //

param tags = {
  environment: environmentAbbreviation
  system: systemAbbreviation
  managedBy: 'Bicep'
}

// Resource groups created by this deployment.
param resourceGroupDefinitions = [
  {
    key: 'network'
    workloadDescription: 'network'
  }
  {
    key: 'networkEdge'
    workloadDescription: 'network'
    subWorkloadDescription: 'edge'
  }
  {
    key: 'hosting'
    workloadDescription: 'hosting'
  }
  {
    key: 'data'
    workloadDescription: 'data'
  }
  {
    key: 'operations'
    workloadDescription: 'operations'
  }
]

// Set to an existing workspace resource ID to reuse one; leave null to create
// the log analytics workspace defined below.
param existingLogAnalyticsID = null

param logAnalyticsConfig = {
  workloadDescription: null
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
// Networking              //
// ======================== //

param spokeNetworkConfig = {
  workloadDescription: null
  ingressOption: 'none' // options are none, frontDoor, applicationGateway
  vnetAddressSpace: '10.0.0.0/21'
  subnetPlan: [
    {
      key: 'appService'
      nameSuffix: 'appservice'
      cidr: '10.0.0.0/23'
      create: true
      purpose: 'Primary App Service hosting and integration subnet sized to the full /23 platform plan.'
      delegationProfile: 'appServicePlan'
      nsgProfile: 'appService'
      routeProfile: 'none'
      privateEndpointNetworkPolicies: 'Enabled'
    }
    {
      key: 'applicationGateway'
      nameSuffix: 'appgateway'
      cidr: '10.0.2.0/24'
      create: true
      purpose: 'Dedicated regional ingress subnet for Application Gateway if that ingress path is used.'
      delegationProfile: 'none'
      nsgProfile: 'applicationGateway'
      routeProfile: 'none'
    }
    {
      key: 'apimEdge'
      nameSuffix: 'apim'
      cidr: '10.0.3.0/24'
      create: true
      purpose: 'Reserved edge/API subnet for APIM or similar edge services.'
      delegationProfile: 'none'
      nsgProfile: 'none'
      routeProfile: 'none'
    }
    {
      key: 'privateEndpoints'
      nameSuffix: 'privateendpoint'
      cidr: '10.0.4.0/24'
      create: true
      purpose: 'Shared private endpoint subnet.'
      delegationProfile: 'none'
      nsgProfile: 'privateEndpoint'
      routeProfile: 'none'
      privateEndpointNetworkPolicies: 'Disabled'
    }
    {
      key: 'privateConnectivityReserve'
      nameSuffix: 'privateconnectivity'
      cidr: '10.0.5.0/24'
      create: false
      purpose: 'Reserved growth space for future private connectivity needs.'
      delegationProfile: 'none'
      nsgProfile: 'none'
      routeProfile: 'none'
    }
    {
      key: 'functions'
      nameSuffix: 'functions'
      cidr: '10.0.6.0/24'
      create: true
      purpose: 'Dedicated Functions subnet held in the active /21 platform plan.'
      delegationProfile: 'none'
      nsgProfile: 'none'
      routeProfile: 'none'
    }
    {
      key: 'logicApps'
      nameSuffix: 'logicapps'
      cidr: '10.0.7.0/26'
      create: true
      purpose: 'Dedicated Logic Apps subnet held in the active /21 platform plan.'
      delegationProfile: 'none'
      nsgProfile: 'none'
      routeProfile: 'none'
    }
    {
      key: 'postgresql'
      nameSuffix: 'postgresql'
      cidr: '10.0.7.64/27'
      create: true
      purpose: 'Delegated subnet for PostgreSQL Flexible Server private access.'
      delegationProfile: 'postgresqlFlexibleServer'
      nsgProfile: 'postgresql'
      routeProfile: 'none'
    }
    {
      key: 'futureDelegatedData'
      nameSuffix: 'futuredata'
      cidr: '10.0.7.96/27'
      create: false
      purpose: 'Reserved delegated data subnet for future services.'
      delegationProfile: 'none'
      nsgProfile: 'none'
      routeProfile: 'none'
    }
    {
      key: 'generalReserve'
      nameSuffix: 'reserve'
      cidr: '10.0.7.128/25'
      create: false
      purpose: 'General reserve block retained for future subnet planning flexibility.'
      delegationProfile: 'none'
      nsgProfile: 'none'
      routeProfile: 'none'
    }
  ]
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

  // See params/examples/main.example.bicepparam for hub peering, App Gateway
  // subnet planning, egress firewall, and alternate subnet-policy examples.
}

// ======================== //
// App Hosting             //
// ======================== //

// App Service Plan basic default for a new plan.
// See params/examples/main.example.bicepparam for existing-plan and
// custom examples.
param servicePlanConfig = {
  workloadDescription: 'frontEnd'
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
  workloadDescription: 'frontEnd'
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

  // See params/examples/main.example.bicepparam for app-settings and slot
  // examples.
}

// App Service Environment is optional and only used when:
//   deployAseV3 = true
//
// This active block is the basic default ASE shape used if you choose to turn
// ASE on. The commented example below shows a fuller configuration with custom
// DNS and dedicated host options. See params/examples/main.example.bicepparam
// for the fuller example block.
param aseConfig = {
  workloadDescription: null
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

// ======================== //
// Security And Monitoring //
// ======================== //

param keyVaultConfig = {
  workloadDescription: null
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

// See params/examples/main.example.bicepparam for fuller Key Vault and
// monitoring examples.
param appInsightsConfig = {
  workloadDescription: null
  applicationType: 'web'
  publicNetworkAccessForIngestion: 'Enabled'
  publicNetworkAccessForQuery: 'Enabled'
  retentionInDays: 90
  samplingPercentage: 100
  disableLocalAuth: true
  disableIpMasking: true
  forceCustomerStorageForProfiler: false
  kind: 'web'
  sendSmartDetectionEmailsToSubscriptionOwners: false
  roleAssignments: []
  diagnosticSettings: []
}

// ======================== //
// Ingress Networking       //
// ======================== //

// Application Gateway is optional and is only used when:
//   spokeNetworkConfig.ingressOption = 'applicationGateway'
//
// This active block is an inert placeholder while Front Door is the selected
// ingress path. See params/examples/main.example.bicepparam for minimal and
// fuller regional ingress examples if you switch away from 'frontDoor'.
param appGatewayConfig = {
  workloadDescription: null
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

// See params/examples/main.example.bicepparam for public-origin and custom
// domain / rule-set / secret Front Door examples.
param frontDoorConfig = {
  workloadDescription: null
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

// ======================== //
// Data                     //
// ======================== //


// This deployment expects an existing Microsoft Entra group for PostgreSQL
// admin. Tenant-scoped Entra groups are not created by this workload
// deployment.
param postgresqlAdminGroupConfig = {
  objectId: 'b58ff011-4384-42b9-b25c-26c5dfc26b06'
  displayName: 'secgrp-iep-eus2-dev-pgsqladmin-001'
}

// See params/examples/main.example.bicepparam for fuller PostgreSQL HA/private
// access and customized databases/configurations examples.
param postgresqlConfig = {
  workloadDescription: null
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
