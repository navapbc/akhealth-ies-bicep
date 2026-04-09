// ======================== //
// Shared User-Defined Types //
// ======================== //

import {
  diagnosticSettingFullType
  diagnosticSettingMetricsOnlyType
  diagnosticSettingLogsOnlyType
  lockType
  roleAssignmentType
  managedIdentityOnlySysAssignedType
} from './avm-common-types.bicep'

// ======================== //
// Existing types            //
// ======================== //

@export()
@description('Describes a virtual network link for a private DNS zone.')
type virtualNetworkLinkType = {
  @description('Required. The name of the virtual network link.')
  name: string

  @description('Required. The resource ID of the virtual network.')
  virtualNetworkResourceId: string

  @description('Optional. Is auto-registration of virtual machine records in the virtual network in the Private DNS zone enabled.')
  registrationEnabled: bool?

  @description('Optional. The resolution policy on the virtual network link. Only applicable for virtual network links to privatelink zones.')
  resolutionPolicy: ('Default' | 'NxDomainRedirect')?
}

@export()
@description('Describes a cluster setting for the App Service Environment.')
type clusterSettingType = {
  @description('Required. The name of the cluster setting.')
  name: string

  @description('Required. The value of the cluster setting.')
  value: string
}

@export()
@description('User-defined type for site configuration properties.')
type siteConfigType = {
  @description('Optional. Whether the web app should always be loaded.')
  alwaysOn: bool?

  @description('Optional. State of FTP / FTPS service.')
  ftpsState: ('AllAllowed' | 'Disabled' | 'FtpsOnly')?

  @description('Optional. Configures the minimum version of TLS required for SSL requests.')
  minTlsVersion: ('1.0' | '1.1' | '1.2' | '1.3')?

  @description('Optional. Health check path. Used by App Service load balancers to determine instance health.')
  healthCheckPath: string?

  @description('Optional. Whether HTTP 2.0 is enabled.')
  http20Enabled: bool?

  @description('Optional. Linux app framework and version string for container deployments (e.g. "DOCKER|image:tag").')
  linuxFxVersion: string?

  @description('Optional. Windows app framework and version string for container deployments (e.g. "DOCKER|image:tag").')
  windowsFxVersion: string?
}

// ======================== //
// Spoke Network Config     //
// ======================== //

@export()
@description('Configuration for the spoke virtual network and ingress networking.')
type spokeNetworkConfigType = {
  @description('Required. CIDR of the spoke VNet (e.g. "10.240.0.0/20").')
  vnetAddressSpace: string

  @description('Required. CIDR of the App Service / ASE subnet. ASEv3 needs a /24.')
  appSvcSubnetAddressSpace: string

  @description('Required. CIDR of the private endpoint subnet.')
  privateEndpointSubnetAddressSpace: string

  @description('Optional. Application Gateway network configuration. Omit this object when ingressOption is not "applicationGateway".')
  applicationGatewayConfig: {
    @description('Required. CIDR of the Application Gateway subnet.')
    subnetAddressSpace: string
  }?

  @description('Optional. PostgreSQL private access network configuration. Omit this object when PostgreSQL delegated subnet access is not intended.')
  postgreSqlPrivateAccessConfig: {
    @description('Required. CIDR of the PostgreSQL delegated subnet.')
    subnetAddressSpace: string
  }?

  @description('Optional. Existing hub VNet peering configuration. Omit this object when no hub peering is required.')
  hubPeeringConfig: {
    @description('Required. Resource ID of the existing hub VNet.')
    virtualNetworkResourceId: string

    @description('Required. Name of the existing hub VNet.')
    virtualNetworkName: string

    @description('Required. Resource group name of the existing hub VNet.')
    resourceGroupName: string

    @description('Required. Subscription ID of the existing hub VNet.')
    subscriptionId: string

    @description('Required. Allow forwarded traffic on the spoke-to-hub peering.')
    allowForwardedTraffic: bool

    @description('Required. Allow gateway transit on the spoke-to-hub peering.')
    allowGatewayTransit: bool

    @description('Required. Allow virtual network access on the spoke-to-hub peering.')
    allowVirtualNetworkAccess: bool

    @description('Required. Do not verify remote gateways on the spoke-to-hub peering.')
    doNotVerifyRemoteGateways: bool

    @description('Required. Use remote gateways on the spoke-to-hub peering.')
    useRemoteGateways: bool

    @description('Optional. Reverse hub-to-spoke peering settings. Omit this object when the reverse peering should not be created.')
    reversePeeringConfig: {
      @description('Required. Allow forwarded traffic on the hub-to-spoke peering.')
      allowForwardedTraffic: bool

      @description('Required. Allow gateway transit on the hub-to-spoke peering.')
      allowGatewayTransit: bool

      @description('Required. Allow virtual network access on the hub-to-spoke peering.')
      allowVirtualNetworkAccess: bool

      @description('Required. Do not verify remote gateways on the hub-to-spoke peering.')
      doNotVerifyRemoteGateways: bool

      @description('Required. Use remote gateways on the hub-to-spoke peering.')
      useRemoteGateways: bool
    }?
  }?

  @description('Optional. Egress firewall configuration. Omit this object when egress traffic is not routed through a hub firewall.')
  egressFirewallConfig: {
    @description('Required. Internal IP of the Azure Firewall in the hub.')
    internalIp: string
  }?

  @description('Required. Ingress option: "frontDoor", "applicationGateway", or "none".')
  ingressOption: ('frontDoor' | 'applicationGateway' | 'none')

  @description('Required. Set to true to route all egress traffic through the firewall.')
  enableEgressLockdown: bool

  @description('Required. Custom DNS servers for the spoke VNet. Use an empty array when Azure-provided DNS is intended.')
  dnsServers: string[]

  @description('Optional. Resource ID of a DDoS Protection Plan to associate with the spoke VNet.')
  ddosProtectionPlanResourceId: string?

  @description('Required. Whether to disable BGP route propagation on the route table.')
  disableBgpRoutePropagation: bool

  @description('Required. Enable VNet encryption.')
  encryption: bool

  @description('Required. VNet encryption enforcement policy.')
  encryptionEnforcement: ('AllowUnencrypted' | 'DropUnencrypted')

  @description('Required. The flow timeout in minutes for the VNet (max 30). 0 = disabled.')
  flowTimeoutInMinutes: int

  @description('Required. Enable VM protection for the VNet.')
  enableVmProtection: bool

  @description('Required. Virtual network private endpoint policies setting. Use "Basic" for high-scale private endpoint scenarios, otherwise "Disabled".')
  enablePrivateEndpointVNetPolicies: ('Basic' | 'Disabled')

  @description('Optional. The BGP community for the VNet.')
  bgpCommunity: string?

  @description('Optional. Resource lock for the spoke virtual network.')
  lock: lockType?

  @description('Required. Role assignments for the spoke virtual network.')
  roleAssignments: roleAssignmentType[]

  @description('Required. Diagnostic settings for the spoke virtual network.')
  diagnosticSettings: diagnosticSettingFullType[]
}

// ======================== //
// Service Plan Config       //
// ======================== //

@export()
@description('Configuration for the App Service Plan.')
type servicePlanConfigType = {
  @description('Required. The SKU name for the App Service Plan (e.g. "P1V3").')
  sku: string

  @description('Required. The SKU capacity (number of workers).')
  skuCapacity: int

  @description('Required. Deploy the plan in a zone redundant manner.')
  zoneRedundant: bool

  @description('Required. Kind of server OS: "windows" or "linux".')
  kind: ('windows' | 'linux')

  @description('Required. Resource ID of an existing App Service Plan. Use an empty string to create a new plan.')
  existingPlanId: string

  @description('Required. Target worker tier name. Use an empty string when not applicable.')
  workerTierName: string

  @description('Required. Whether elastic scale is enabled.')
  elasticScaleEnabled: bool

  @description('Required. Maximum number of total workers for ElasticScaleEnabled plans.')
  maximumElasticWorkerCount: int

  @description('Required. If true, apps can be scaled independently.')
  perSiteScaling: bool

  @description('Required. Scaling worker count.')
  targetWorkerCount: int

  @description('Required. The instance size of the hosting plan (0=small, 1=medium, 2=large).')
  targetWorkerSize: (0 | 1 | 2)

  @description('Required. Resource ID of a subnet for App Service Plan VNet integration. Use an empty string when not applicable.')
  virtualNetworkSubnetId: string

  @description('Required. Whether the App Service Plan uses custom mode.')
  isCustomMode: bool

  @description('Required. Whether RDP is enabled.')
  rdpEnabled: bool

  @description('Required. Install scripts for the App Service Plan.')
  installScripts: array

  @description('Optional. The default identity for the App Service Plan.')
  planDefaultIdentity: ('DefaultIdentity')?

  @description('Required. Registry adapter configuration.')
  registryAdapters: array

  @description('Required. Storage mount configuration.')
  storageMounts: array

  @description('Required. Managed identities for the App Service Plan.')
  managedIdentities: managedIdentityOnlySysAssignedType

  @description('Optional. Resource lock for the App Service Plan.')
  lock: lockType?

  @description('Required. Role assignments for the App Service Plan.')
  roleAssignments: roleAssignmentType[]

  @description('Required. Diagnostic settings for the App Service Plan.')
  diagnosticSettings: diagnosticSettingMetricsOnlyType[]
}

// ======================== //
// Web App Config            //
// ======================== //

@export()
@description('Container image configuration for the web app.')
type containerConfigType = {
  @description('Optional. The container image name (e.g. "mcr.microsoft.com/appsvc/staticsite:latest").')
  imageName: string?

  @description('Optional. The container registry URL (e.g. "https://myregistry.azurecr.io").')
  registryUrl: string?

  @description('Optional. The container registry username.')
  registryUsername: string?

  @secure()
  @description('Optional. The container registry password.')
  registryPassword: string?
}

@export()
@description('Configuration for the Web App.')
type appServiceConfigType = {
  @description('Required. Kind of web app (e.g. "app", "app,linux", "app,linux,container", "functionapp").')
  kind: ('api' | 'app' | 'app,container,windows' | 'app,linux' | 'app,linux,container' | 'functionapp' | 'functionapp,linux' | 'functionapp,linux,container' | 'functionapp,linux,container,azurecontainerapps' | 'functionapp,workflowapp' | 'functionapp,workflowapp,linux' | 'linux,api')

  @description('Required. Require HTTPS only.')
  httpsOnly: bool

  @description('Required. Enable client certificate authentication (mTLS).')
  clientCertEnabled: bool

  @description('Optional. Client certificate mode. Only used when clientCertEnabled is true.')
  clientCertMode: ('Optional' | 'OptionalInteractiveUser' | 'Required')?

  @description('Optional. Client certificate exclusion paths (comma-separated).')
  clientCertExclusionPaths: string?

  @description('Required. Disable basic publishing credentials (FTP/SCM).')
  disableBasicPublishingCredentials: bool

  @description('Required. Public network access for the web app.')
  publicNetworkAccess: ('Enabled' | 'Disabled' | '')

  @description('Required. Site redundancy mode.')
  redundancyMode: ('ActiveActive' | 'Failover' | 'GeoRedundant' | 'Manual' | 'None')

  @description('Required. Stop SCM (Kudu) site when the app is stopped.')
  scmSiteAlsoStopped: bool

  @description('Required. The site configuration object.')
  siteConfig: siteConfigType

  @description('Optional. Function App configuration object.')
  functionAppConfig: object?

  @description('Optional. Managed environment resource ID for Azure Container Apps.')
  managedEnvironmentResourceId: string?

  @description('Optional. Outbound VNet routing configuration.')
  outboundVnetRouting: object?

  @description('Optional. Hostname SSL states for managing SSL bindings.')
  hostNameSslStates: array?

  @description('Optional. Enable end-to-end encryption (used with ASE).')
  e2eEncryptionEnabled: bool?

  @description('Optional. Resource ID of the identity for Key Vault references.')
  keyVaultAccessIdentityResourceId: string?

  @description('Required. Managed identities assigned to the web app.')
  managedIdentities: managedIdentityOnlySysAssignedType

  @description('Optional. Extensions configuration for the web app.')
  extensions: array?

  @description('Required. Setting to false disables the app (takes it offline).')
  enabled: bool

  @description('Optional. Cloning info for creating from a source app.')
  cloningInfo: object?

  @description('Optional. Size of the function container.')
  containerSize: int?

  @description('Optional. Maximum allowed daily memory-time quota.')
  dailyMemoryTimeQuota: int?

  @description('Required. Enable Hyper-V isolation for Windows container apps.')
  hyperV: bool

  @description('Required. Whether customer-provided storage account is required.')
  storageAccountRequired: bool

  @description('Optional. Azure Storage account mounts (BYOS). Each key is a mount name; value specifies accountName, shareName, mountPath, accessKey, type (AzureFiles|AzureBlob), and protocol (Smb|Nfs|Http).')
  storageAccounts: object?

  @description('Optional. DNS-related settings for the site.')
  dnsConfiguration: object?

  @description('Optional. Default hostname uniqueness scope.')
  autoGeneratedDomainNameLabelScope: ('NoReuse' | 'ResourceGroupReuse' | 'SubscriptionReuse' | 'TenantReuse')?

  @description('Optional. Whether to enable SSH access.')
  sshEnabled: bool?

  @description('Optional. Dapr configuration (Container Apps).')
  daprConfig: object?

  @description('Optional. IP mode of the app.')
  ipMode: ('IPv4' | 'IPv4AndIPv6' | 'IPv6')?

  @description('Optional. Function app resource requirements.')
  resourceConfig: object?

  @description('Optional. Workload profile name for function app.')
  workloadProfileName: string?

  @description('Optional. Disable public hostnames of the app.')
  hostNamesDisabled: bool?

  @description('Required. True if reserved (Linux).')
  reserved: bool

  @description('Optional. Extended location of the web app resource.')
  extendedLocation: object?

  @description('Required. Enable client affinity on the web app.')
  clientAffinityEnabled: bool

  @description('Required. Proxy-based client affinity.')
  clientAffinityProxyEnabled: bool

  @description('Required. Partitioned client affinity using CHIPS cookies.')
  clientAffinityPartitioningEnabled: bool

  @description('Optional. Container configuration for container-based deployments.')
  container: containerConfigType?

  @description('Optional. Resource lock for the Web App.')
  lock: lockType?

  @description('Optional. Role assignments for the Web App.')
  roleAssignments: roleAssignmentType[]?

  @description('Required. Diagnostic settings for the Web App.')
  diagnosticSettings: diagnosticSettingFullType[]

  @description('Required. Deployment slot definitions for the web app.')
  slots: appServiceSlotConfigType[]

  @description('Required. Web app configuration resources to apply, such as app settings or storage account mounts.')
  configs: array

}

@description('Configuration for an App Service deployment slot passed through the solution-level interface.')
type appServiceSlotConfigType = {
  @description('Required. Name of the slot.')
  name: string

  @description('Optional. Location for all resources.')
  location: string?

  @description('Optional. The resource ID of the App Service plan to use for the slot.')
  serverFarmResourceId: string?

  @description('Optional. Azure Resource Manager ID of the managed environment on which to host this app.')
  managedEnvironmentResourceId: string?

  @description('Optional. Configures a slot to accept only HTTPS requests.')
  httpsOnly: bool?

  @description('Optional. If client affinity is enabled.')
  clientAffinityEnabled: bool?

  @description('Optional. Enables proxy-based client affinity.')
  clientAffinityProxyEnabled: bool?

  @description('Optional. Enables client affinity partitioning using CHIPS cookies.')
  clientAffinityPartitioningEnabled: bool?

  @description('Optional. The resource ID of the App Service Environment to use for this slot.')
  appServiceEnvironmentResourceId: string?

  @description('Optional. The managed identity definition for this slot.')
  managedIdentities: managedIdentityOnlySysAssignedType?

  @description('Optional. The resource ID of the assigned identity to be used to access a Key Vault.')
  keyVaultAccessIdentityResourceId: string?

  @description('Optional. Checks if customer-provided storage account is required.')
  storageAccountRequired: bool?

  @description('Optional. Azure Resource Manager ID of the virtual network subnet to join by regional VNet integration.')
  virtualNetworkSubnetResourceId: string?

  @description('Optional. The site config object.')
  siteConfig: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.siteConfig?

  @description('Optional. The Function App config object.')
  functionAppConfig: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.functionAppConfig?

  @description('Optional. The web site configs for the slot.')
  configs: array?

  @description('Optional. The extensions configuration.')
  extensions: resourceInput<'Microsoft.Web/sites/extensions@2025-03-01'>.properties[]?

  @description('Optional. The lock settings of the service.')
  lock: lockType?

  @description('Optional. Tags of the resource.')
  tags: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.tags?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType[]?

  @description('Optional. The diagnostic settings of the service.')
  diagnosticSettings: diagnosticSettingFullType[]?

  @description('Optional. Enables client certificate authentication (TLS mutual authentication).')
  clientCertEnabled: bool?

  @description('Optional. Client certificate authentication comma-separated exclusion paths.')
  clientCertExclusionPaths: string?

  @description('Optional. Client certificate mode.')
  clientCertMode: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.clientCertMode?

  @description('Optional. If specified during app creation, the app is cloned from a source app.')
  cloningInfo: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.cloningInfo?

  @description('Optional. Size of the function container.')
  containerSize: int?

  @description('Optional. Unique identifier used to verify custom domains assigned to the app.')
  customDomainVerificationId: string?

  @description('Optional. Maximum allowed daily memory-time quota.')
  dailyMemoryTimeQuota: int?

  @description('Optional. Setting this value to false disables the app.')
  enabled: bool?

  @description('Optional. Hostname SSL states used to manage the SSL bindings for the app hostnames.')
  hostNameSslStates: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.hostNameSslStates?

  @description('Optional. Hyper-V sandbox.')
  hyperV: bool?

  @description('Optional. Allow or block all public traffic.')
  publicNetworkAccess: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.publicNetworkAccess?

  @description('Optional. Site redundancy mode.')
  redundancyMode: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.redundancyMode?

  @description('Optional. Site publishing credential policies associated with the slot.')
  basicPublishingCredentialsPolicies: {
    @description('Required. The name of the publishing credential policy.')
    name: ('scm' | 'ftp')

    @description('Optional. Set to true to enable or false to disable a publishing method.')
    allow: bool?

    @description('Optional. Location for all resources.')
    location: string?
  }[]?

  @description('Optional. The outbound VNET routing configuration for the slot.')
  outboundVnetRouting: resourceInput<'Microsoft.Web/sites/slots@2025-03-01'>.properties.outboundVnetRouting?

  @description('Optional. Property to configure various DNS-related settings for a site.')
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

  @description('Optional. Workload profile name for the function app to execute on.')
  workloadProfileName: string?

  @description('Optional. True to disable the public hostnames of the app.')
  hostNamesDisabled: bool?

  @description('Optional. True if reserved (Linux); otherwise false (Windows).')
  reserved: bool?

  @description('Optional. Stop SCM (KUDU) site when the app is stopped.')
  scmSiteAlsoStopped: bool?

  @description('Optional. End-to-end encryption setting.')
  e2eEncryptionEnabled: bool?
}

// ======================== //
// Key Vault Config          //
// ======================== //

@export()
@description('Explicit private endpoint configuration for a Key Vault.')
type keyVaultPrivateEndpointType = {
  @description('Required. The name of the private endpoint.')
  name: string

  @description('Required. The location to deploy the private endpoint to.')
  location: string

  @description('Required. The resource group name where the private endpoint will be created.')
  resourceGroupName: string

  @description('Required. The name of the private link service connection to create.')
  privateLinkServiceConnectionName: string

  @description('Required. The Key Vault subresource to connect to.')
  service: 'vault'

  @description('Required. Resource ID of the subnet where the endpoint needs to be created.')
  subnetResourceId: string

  @description('Optional. The private DNS zone group to configure for the private endpoint.')
  privateDnsZoneGroup: {
    @description('Optional. The name of the private DNS zone group.')
    name: string?

    @description('Required. The private DNS zone group configs to associate with the private endpoint.')
    privateDnsZoneGroupConfigs: {
      @description('Required. The name of the private DNS zone group config.')
      name: string

      @description('Required. The resource ID of the private DNS zone.')
      privateDnsZoneResourceId: string
    }[]
  }?

  @description('Required. If manual private link connection approval is required.')
  isManualConnection: bool

  @description('Optional. A message passed to the owner of the remote resource with the manual connection request.')
  manualConnectionRequestMessage: string?

  @description('Optional. Custom DNS configurations.')
  customDnsConfigs: {
    @description('Optional. FQDN that resolves to private endpoint IP address.')
    fqdn: string?

    @description('Required. A list of private IP addresses of the private endpoint.')
    ipAddresses: string[]
  }[]?

  @description('Optional. A list of IP configurations of the private endpoint.')
  ipConfigurations: {
    @description('Required. The name of the IP configuration.')
    name: string

    @description('Required. Properties of private endpoint IP configurations.')
    properties: {
      @description('Required. The ID of a group obtained from the remote resource that this private endpoint should connect to.')
      groupId: string

      @description('Required. The member name of a group obtained from the remote resource that this private endpoint should connect to.')
      memberName: string

      @description('Required. A private IP address obtained from the private endpoint subnet.')
      privateIPAddress: string
    }
  }[]?

  @description('Optional. Application security groups in which the private endpoint IP configuration is included.')
  applicationSecurityGroupResourceIds: string[]?

  @description('Optional. The custom name of the network interface attached to the private endpoint.')
  customNetworkInterfaceName: string?

  @description('Optional. Resource lock for the private endpoint.')
  lock: lockType?

  @description('Optional. Role assignments for the private endpoint.')
  roleAssignments: roleAssignmentType[]?

  @description('Optional. Tags for the private endpoint.')
  tags: resourceInput<'Microsoft.Network/privateEndpoints@2025-05-01'>.tags?
}

@export()
@description('Configuration for the Key Vault.')
type keyVaultConfigType = {
  @description('Required. Enable purge protection.')
  enablePurgeProtection: bool

  @description('Required. Soft delete retention in days.')
  softDeleteRetentionInDays: int

  @description('Optional. Secrets to create.')
  secrets: array?

  @description('Optional. Keys to create.')
  keys: array?

  @description('Required. Enable for template deployment.')
  enableVaultForTemplateDeployment: bool

  @description('Required. Enable for disk encryption.')
  enableVaultForDiskEncryption: bool

  @description('Required. Create mode: "default" or "recover".')
  createMode: ('default' | 'recover')

  @description('Required. The SKU: "standard" or "premium".')
  sku: ('standard' | 'premium')

  @description('Required. Enable for deployment.')
  enableVaultForDeployment: bool

  @description('Required. Network ACLs for the Key Vault.')
  networkAcls: object

  @description('Required. Public network access for the Key Vault.')
  publicNetworkAccess: ('Enabled' | 'Disabled')

  @description('Optional. Resource lock for the Key Vault.')
  lock: lockType?

  @description('Required. Role assignments for the Key Vault.')
  roleAssignments: roleAssignmentType[]

  @description('Required. Diagnostic settings for the Key Vault.')
  diagnosticSettings: diagnosticSettingFullType[]
}

// ======================== //
// App Insights Config       //
// ======================== //

@export()
@description('Configuration for Application Insights.')
type appInsightsConfigType = {
  @description('Required. Application type.')
  applicationType: ('web' | 'other')

  @description('Required. Public network access for ingestion.')
  publicNetworkAccessForIngestion: ('Enabled' | 'Disabled')

  @description('Required. Public network access for query.')
  publicNetworkAccessForQuery: ('Enabled' | 'Disabled')

  @description('Required. Data retention in days.')
  retentionInDays: (30 | 60 | 90 | 120 | 180 | 270 | 365 | 550 | 730)

  @description('Required. Sampling percentage (1-100).')
  samplingPercentage: int

  @description('Required. Disable non-AAD based auth.')
  disableLocalAuth: bool

  @description('Required. Disable IP masking (false = mask IPs for privacy).')
  disableIpMasking: bool

  @description('Required. Force customer storage for profiler.')
  forceCustomerStorageForProfiler: bool

  @description('Optional. Linked storage account resource ID.')
  linkedStorageAccountResourceId: string?

  @description('Optional. Flow type.')
  flowType: string?

  @description('Optional. Request source.')
  requestSource: string?

  @description('Required. Kind of App Insights resource.')
  kind: string

  @description('Optional. Purge data immediately after 30 days.')
  immediatePurgeDataOn30Days: bool?

  @description('Optional. Ingestion mode.')
  ingestionMode: ('ApplicationInsights' | 'ApplicationInsightsWithDiagnosticSettings' | 'LogAnalytics')?

  @description('Optional. Resource lock for App Insights.')
  lock: lockType?

  @description('Required. Role assignments for App Insights.')
  roleAssignments: roleAssignmentType[]

  @description('Required. Diagnostic settings for App Insights.')
  diagnosticSettings: diagnosticSettingFullType[]
}

// ======================== //
// Log Analytics Config     //
// ======================== //

@export()
@description('Configuration for the Log Analytics workspace when this template creates one.')
type logAnalyticsConfigType = {
  @description('Required. Workspace SKU.')
  sku: string

  @description('Required. Workspace retention in days.')
  retentionInDays: int

  @description('Required. Enable resource-permission-only log access.')
  enableLogAccessUsingOnlyResourcePermissions: bool

  @description('Required. Disable local auth.')
  disableLocalAuth: bool

  @description('Required. Public network access for ingestion.')
  publicNetworkAccessForIngestion: ('Enabled' | 'Disabled')

  @description('Required. Public network access for query.')
  publicNetworkAccessForQuery: ('Enabled' | 'Disabled')

  @description('Optional. Resource lock for the Log Analytics workspace.')
  lock: lockType?

  @description('Required. Role assignments for the Log Analytics workspace.')
  roleAssignments: roleAssignmentType[]

  @description('Required. Diagnostic settings for the Log Analytics workspace.')
  diagnosticSettings: diagnosticSettingFullType[]
}

// ======================== //
// Application Gateway Config //
// ======================== //

@export()
@description('Configuration for the Application Gateway.')
type appGatewayConfigType = {
  @description('Required. Application Gateway SKU.')
  sku: ('Basic' | 'Standard_v2' | 'WAF_v2')

  @description('Required. Fixed instance capacity when autoscale is not used.')
  capacity: int

  @description('Required. Minimum autoscale instance count.')
  autoscaleMinCapacity: int

  @description('Required. Maximum autoscale instance count.')
  autoscaleMaxCapacity: int

  @description('Required. Availability zones for the Application Gateway and its public IP.')
  availabilityZones: int[]

  @description('Required. SSL certificates for HTTPS termination.')
  sslCertificates: array

  @description('Required. Managed identities for Key Vault-referenced SSL certificates.')
  managedIdentities: managedIdentityOnlySysAssignedType

  @description('Required. Trusted root certificates for end-to-end SSL.')
  trustedRootCertificates: array

  @description('Required. SSL policy type.')
  sslPolicyType: ('Custom' | 'CustomV2' | 'Predefined')

  @description('Required. Predefined SSL policy name. Use an empty string when not applicable.')
  sslPolicyName: ('' | 'AppGwSslPolicy20150501' | 'AppGwSslPolicy20170401' | 'AppGwSslPolicy20170401S' | 'AppGwSslPolicy20220101' | 'AppGwSslPolicy20220101S')

  @description('Required. Minimum TLS protocol version.')
  sslPolicyMinProtocolVersion: ('TLSv1_2' | 'TLSv1_3')

  @description('Required. SSL cipher suites.')
  sslPolicyCipherSuites: string[]

  @description('Required. Role assignments for the Application Gateway.')
  roleAssignments: roleAssignmentType[]

  @description('Required. Authentication certificates for backend auth.')
  authenticationCertificates: array

  @description('Required. Custom error configurations.')
  customErrorConfigurations: array

  @description('Required. Whether FIPS mode is enabled.')
  enableFips: bool

  @description('Required. Whether HTTP/2 is enabled.')
  enableHttp2: bool

  @description('Required. Whether request buffering is enabled.')
  enableRequestBuffering: bool

  @description('Required. Whether response buffering is enabled.')
  enableResponseBuffering: bool

  @description('Required. Load distribution policies.')
  loadDistributionPolicies: array

  @description('Required. Private endpoints for the Application Gateway.')
  privateEndpoints: array

  @description('Required. Private link configurations.')
  privateLinkConfigurations: array

  @description('Required. Redirect configurations.')
  redirectConfigurations: array

  @description('Required. Rewrite rule sets.')
  rewriteRuleSets: array

  @description('Required. Gateway IP configurations.')
  gatewayIPConfigurations: array

  @description('Required. Frontend IP configurations.')
  frontendIPConfigurations: array

  @description('Required. Frontend ports.')
  frontendPorts: array

  @description('Required. Backend address pools.')
  backendAddressPools: array

  @description('Required. Backend HTTP settings collection.')
  backendHttpSettingsCollection: array

  @description('Required. Health probes.')
  probes: array

  @description('Required. HTTP listeners.')
  httpListeners: array

  @description('Required. Request routing rules.')
  requestRoutingRules: array

  @description('Required. SSL profiles.')
  sslProfiles: array

  @description('Required. Trusted client certificates for mTLS.')
  trustedClientCertificates: array

  @description('Required. URL path maps for path-based routing.')
  urlPathMaps: array

  @description('Required. Backend settings collection (v2).')
  backendSettingsCollection: array

  @description('Required. Listeners (v2).')
  listeners: array

  @description('Required. Routing rules (v2).')
  routingRules: array

  @description('Optional. Resource lock for the Application Gateway.')
  lock: lockType?

  @description('Required. Diagnostic settings for the Application Gateway.')
  diagnosticSettings: diagnosticSettingFullType[]

  @description('Required. WAF policy settings for the Application Gateway.')
  wafPolicySettings: object

  @description('Required. WAF managed rule sets for the Application Gateway.')
  wafManagedRuleSets: array
}

// ======================== //
// Front Door Config         //
// ======================== //

@export()
@description('Configuration for a Front Door shared private link to the workload web app.')
type frontDoorAppServiceOriginPrivateLinkType = {
  @description('Required. Shared Private Link approval message.')
  requestMessage: string

  @description('Required. Shared Private Link group ID.')
  groupId: string
}

@export()
@description('Configuration for a Front Door origin that targets the workload web app.')
type frontDoorAppServiceOriginConfigType = {
  @description('Required. Name of the origin.')
  name: string

  @description('Required. Whether the origin is enabled.')
  enabledState: ('Enabled' | 'Disabled')

  @description('Required. Whether Front Door enforces certificate name checks for the origin.')
  enforceCertificateNameCheck: bool

  @description('Required. Origin HTTP port.')
  httpPort: int

  @description('Required. Origin HTTPS port.')
  httpsPort: int

  @description('Required. Origin priority.')
  priority: int

  @description('Required. Origin weight.')
  weight: int

  @description('Optional. Shared private link configuration to the workload web app. Omit this object to use a public origin path.')
  sharedPrivateLink: frontDoorAppServiceOriginPrivateLinkType?
}

@export()
@description('Configuration for a Front Door origin group.')
type frontDoorOriginGroupConfigType = {
  @description('Required. Name of the origin group.')
  name: string

  @description('Optional. Settings for Origin Authentication.')
  authentication: resourceInput<'Microsoft.Cdn/profiles/originGroups@2025-06-01'>.properties.authentication?

  @description('Optional. Health probe settings for the origin group.')
  healthProbeSettings: resourceInput<'Microsoft.Cdn/profiles/originGroups@2025-06-01'>.properties.healthProbeSettings?

  @description('Required. Load balancing settings for the origin group.')
  loadBalancingSettings: resourceInput<'Microsoft.Cdn/profiles/originGroups@2025-06-01'>.properties.loadBalancingSettings

  @description('Required. Session affinity state for the origin group.')
  sessionAffinityState: ('Enabled' | 'Disabled')

  @description('Required. Traffic restoration time for healed or new endpoints.')
  trafficRestorationTimeToHealedOrNewEndpointsInMinutes: int

  @description('Required. Origins in this group. These origins target the workload web app.')
  origins: frontDoorAppServiceOriginConfigType[]
}

@export()
@description('Configuration for a Front Door route.')
type frontDoorRouteConfigType = {
  @description('Required. Name of the route.')
  name: string

  @description('Optional. Caching configuration for this route.')
  cacheConfiguration: resourceInput<'Microsoft.Cdn/profiles/afdEndpoints/routes@2025-06-01'>.properties.cacheConfiguration?

  @description('Optional. Names of custom domains attached to this route.')
  customDomainNames: string[]?

  @description('Required. Whether the route is enabled.')
  enabledState: ('Enabled' | 'Disabled')

  @description('Required. The protocol this route uses when forwarding traffic to the origin group.')
  forwardingProtocol: ('HttpOnly' | 'HttpsOnly' | 'MatchRequest')

  @description('Required. Whether HTTP traffic is redirected to HTTPS.')
  httpsRedirect: ('Enabled' | 'Disabled')

  @description('Required. Whether the route is linked to the default endpoint domain.')
  linkToDefaultDomain: ('Enabled' | 'Disabled')

  @description('Required. Name of the origin group that serves this route.')
  originGroupName: string

  @description('Optional. Origin path prefix for this route.')
  originPath: string?

  @description('Required. Route patterns to match.')
  patternsToMatch: string[]

  @description('Optional. Names of rule sets attached to this route.')
  ruleSets: string[]?

  @description('Required. Supported protocols for this route.')
  supportedProtocols: resourceInput<'Microsoft.Cdn/profiles/afdEndpoints/routes@2025-06-01'>.properties.supportedProtocols
}

@export()
@description('Configuration for a Front Door AFD endpoint.')
type frontDoorAfdEndpointConfigType = {
  @description('Required. Name of the AFD endpoint.')
  name: string

  @description('Required. Routes for this endpoint.')
  routes: frontDoorRouteConfigType[]

  @description('Optional. Tags for the AFD endpoint.')
  tags: resourceInput<'Microsoft.Cdn/profiles/afdEndpoints@2025-06-01'>.tags?

  @description('Required. Scope of the auto-generated domain name label.')
  autoGeneratedDomainNameLabelScope: ('NoReuse' | 'ResourceGroupReuse' | 'SubscriptionReuse' | 'TenantReuse')

  @description('Required. Whether the AFD endpoint is enabled.')
  enabledState: ('Enabled' | 'Disabled')
}

@export()
@description('Configuration for Azure Front Door.')
type frontDoorConfigType = {
  @description('Required. Isolation scope for the AFD private-endpoint auto-approver managed identity.')
  afdPeAutoApproverIsolationScope: ('None' | 'Regional')

  @description('Required. Managed identities for the Front Door profile.')
  managedIdentities: managedIdentityOnlySysAssignedType

  @description('Required. Deploy the default WAF rule that blocks non-GET/HEAD/OPTIONS methods.')
  enableDefaultWafMethodBlock: bool

  @description('Required. Custom WAF rules. Use an empty object when enableDefaultWafMethodBlock is true.')
  wafCustomRules: object

  @description('Required. Custom domains for the Front Door profile.')
  customDomains: array

  @description('Required. Rule sets for the Front Door profile.')
  ruleSets: array

  @description('Required. Secrets for the Front Door profile (e.g. BYOC certificates).')
  secrets: array

  @description('Required. Role assignments for the Front Door profile.')
  roleAssignments: roleAssignmentType[]

  @description('Required. Origin response timeout in seconds.')
  originResponseTimeoutSeconds: int

  @description('Required. Auto-approve the private endpoint connection to AFD.')
  autoApprovePrivateEndpoint: bool

  @description('Required. Front Door SKU.')
  sku: string

  @description('Required. WAF policy settings for Front Door.')
  wafPolicySettings: object

  @description('Required. WAF managed rule sets for Front Door.')
  wafManagedRuleSets: array

  @description('Required. Explicit origin groups for the Front Door topology.')
  originGroups: frontDoorOriginGroupConfigType[]

  @description('Required. Explicit AFD endpoints and routes for the Front Door topology.')
  afdEndpoints: frontDoorAfdEndpointConfigType[]

  @description('Required. Security policy patterns to match.')
  securityPatternsToMatch: string[]

  @description('Optional. Resource lock for the Front Door profile.')
  lock: lockType?

  @description('Required. Diagnostic settings for Front Door.')
  diagnosticSettings: diagnosticSettingFullType[]
}

// ======================== //
// ASE Config                //
// ======================== //

@export()
@description('Configuration for the App Service Environment v3.')
type aseConfigType = {
  @description('Required. Custom settings for ASE behavior.')
  clusterSettings: clusterSettingType[]

  @description('Required. Custom DNS suffix for the ASE. Use an empty string when not applicable.')
  customDnsSuffix: string

  @description('Required. Number of IP SSL addresses reserved.')
  ipsslAddressCount: int

  @description('Required. Front-end VM size. Use an empty string when not applicable.')
  multiSize: string

  @description('Required. Key Vault certificate URL for the custom DNS suffix. Use an empty string when not applicable.')
  customDnsSuffixCertificateUrl: string

  @description('Required. Dedicated Host Count. Set to 0 when not applicable.')
  dedicatedHostCount: int

  @description('Required. DNS suffix of the ASE. Use an empty string when not applicable.')
  dnsSuffix: string

  @description('Required. Scale factor for ASE frontends.')
  frontEndScaleFactor: int

  @description('Required. Which endpoints to serve internally in the VNet.')
  internalLoadBalancingMode: ('None' | 'Web' | 'Publishing' | 'Web, Publishing')

  @description('Required. Deploy the App Service Environment in a zone redundant manner.')
  zoneRedundant: bool

  @description('Required. Allow new private endpoint connections on the ASE.')
  allowNewPrivateEndpointConnections: bool

  @description('Required. Enable FTP on the ASE.')
  ftpEnabled: bool

  @description('Required. Customer-provided inbound IP address. Use an empty string when not applicable.')
  inboundIpAddressOverride: string

  @description('Required. Enable remote debug on the ASE.')
  remoteDebugEnabled: bool

  @description('Required. Maintenance upgrade preference.')
  upgradePreference: ('Early' | 'Late' | 'Manual' | 'None')

  @description('Optional. Resource lock for the ASE.')
  lock: lockType?

  @description('Required. Role assignments for the ASE.')
  roleAssignments: roleAssignmentType[]

  @description('Required. Diagnostic settings for the ASE.')
  diagnosticSettings: diagnosticSettingLogsOnlyType[]
}

// ======================== //
// Directory Config         //
// ======================== //

@export()
@description('Configuration for an existing Microsoft Entra security group used by the workload.')
type entraGroupConfigType = {
  @description('Required. Object ID of the existing Microsoft Entra security group.')
  objectId: string

  @description('Required. Display name of the existing Microsoft Entra security group.')
  displayName: string
}

// ======================== //
// PostgreSQL Config        //
// ======================== //

@export()
@description('Configuration for a PostgreSQL database created on the flexible server.')
type postgresqlDatabaseConfigType = {
  @description('Required. Database name.')
  name: string

  @description('Optional. Database collation.')
  collation: string?

  @description('Optional. Database charset.')
  charset: string?
}

@export()
@description('Configuration for a PostgreSQL flexible server setting.')
type postgresqlServerConfigurationType = {
  @description('Required. Server configuration name.')
  name: string

  @description('Optional. Configuration source.')
  source: string?

  @description('Optional. Configuration value.')
  value: string?
}

@export()
@description('Configuration for Azure Database for PostgreSQL Flexible Server.')
type postgresqlConfigType = {
  @description('Required. Workload descriptor used by the owning module to derive the server name.')
  workloadDescription: string

  @description('Required. Private networking mode for PostgreSQL. Use "delegatedSubnet" when deployPrivateNetworking is true. Use "none" when deployPrivateNetworking is false.')
  privateAccessMode: ('delegatedSubnet' | 'none')

  @description('Required. The SKU name for the PostgreSQL flexible server, for example "Standard_D2s_v3".')
  skuName: string

  @description('Required. The pricing tier that aligns with the SKU name.')
  tier: ('Burstable' | 'GeneralPurpose' | 'MemoryOptimized')

  @description('Required. Availability zone. Use -1 when no explicit zone is intended.')
  availabilityZone: (-1 | 1 | 2 | 3)

  @description('Required. Standby availability zone. Use -1 when no explicit zone is intended.')
  highAvailabilityZone: (-1 | 1 | 2 | 3)

  @description('Required. High availability mode.')
  highAvailability: ('Disabled' | 'SameZone' | 'ZoneRedundant')

  @description('Required. Backup retention in days.')
  backupRetentionDays: int

  @description('Required. Whether geo-redundant backup is enabled.')
  geoRedundantBackup: ('Disabled' | 'Enabled')

  @description('Required. Maximum storage size in GB.')
  storageSizeGB: int

  @description('Required. Storage autogrow setting.')
  autoGrow: ('Disabled' | 'Enabled')

  @description('Required. PostgreSQL engine version. Region support varies by subscription and location.')
  version: ('11' | '12' | '13' | '14' | '15' | '16' | '17' | '18')

  @description('Required. Public network access setting for the server. Use "Disabled" when deployPrivateNetworking is true and "Enabled" when deployPrivateNetworking is false.')
  publicNetworkAccess: ('Disabled' | 'Enabled')

  @description('Required. Set to true to assign the Azure Reader role on the PostgreSQL server resource to the Web App system-assigned identity.')
  grantAppServiceIdentityReaderRole: bool

  @description('Required. Databases to create on the server.')
  databases: postgresqlDatabaseConfigType[]

  @description('Required. Server configurations to apply.')
  configurations: postgresqlServerConfigurationType[]

  @description('Optional. Resource lock for the server.')
  lock: lockType?

  @description('Required. Azure RBAC role assignments for the PostgreSQL server resource. These do not configure database principals or in-database grants.')
  roleAssignments: roleAssignmentType[]

  @description('Required. Diagnostic settings for the server.')
  diagnosticSettings: diagnosticSettingFullType[]
}
