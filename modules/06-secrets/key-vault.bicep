metadata name = 'Key Vaults'
metadata description = 'This module deploys a Key Vault.'

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

// ================ //
// Parameters       //
// ================ //
@description('Required. Abbreviation for the owning system.')
param systemAbbreviation string

@description('Required. Abbreviation for the lifecycle environment.')
param environmentAbbreviation string

@description('Required. Instance number used for deterministic naming.')
param instanceNumber string

@description('Optional. Workload descriptor to include in names when it adds value. When empty, the segment is omitted.')
param workloadDescription string = ''

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. All secrets to create.')
param secrets secretType[]?

@description('Optional. All keys to create.')
param keys keyType[]?

@description('Optional. Specifies if the vault is enabled for deployment by script or compute.')
param enableVaultForDeployment bool = true

@description('Optional. Specifies if the vault is enabled for a template deployment.')
param enableVaultForTemplateDeployment bool = true

@description('Optional. Specifies if the azure platform has access to the vault for enabling disk encryption scenarios.')
param enableVaultForDiskEncryption bool

@description('Optional. softDelete data retention days. It accepts >=7 and <=90.')
param softDeleteRetentionInDays int

@description('Optional. The vault\'s create mode to indicate whether the vault need to be recovered or not.')
@allowed([
  'default'
  'recover'
])
param createMode string

@description('Optional. Provide \'true\' to enable Key Vault\'s purge protection feature.')
param enablePurgeProtection bool

@description('Optional. Specifies the SKU for the vault.')
@allowed([
  'premium'
  'standard'
])
param sku string

@description('Optional. Rules governing the accessibility of the resource from specific network locations.')
param networkAcls networkAclsType?

@description('Required. Whether or not public network access is allowed for this resource.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string

import { lockType } from '../shared/avm-common-types.bicep'
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

import {
  virtualNetworkLinkType
} from '../shared/shared.types.bicep'
@description('Optional. When true, the module creates the standard private endpoint wiring for the vault.')
param enableDefaultPrivateEndpoint bool = false

@description('Optional. Subnet resource ID for the module-owned default private endpoint.')
param defaultPrivateEndpointSubnetResourceId string?

@description('Optional. Private DNS zone name for the module-owned default private endpoint.')
param defaultPrivateDnsZoneName string = 'privatelink.vaultcore.azure.net'

@description('Optional. Virtual network links for the module-owned default private DNS zone.')
param defaultPrivateDnsZoneVirtualNetworkLinks virtualNetworkLinkType[] = []

@description('Optional. Resource tags.')
param tags resourceInput<'Microsoft.KeyVault/vaults@2024-11-01'>.tags?

import { diagnosticSettingFullType } from '../shared/avm-common-types.bicep'
@description('Optional. The diagnostic settings of the service.')
param diagnosticSettings diagnosticSettingFullType[]?


// =========== //
// Variables   //
// =========== //


var builtInRoleNames = {
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  'Key Vault Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '00482a5a-887f-4fb3-b363-3b7fe8e74483'
  )
  'Key Vault Certificates Officer': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'a4417e6f-fecd-4de8-b567-7b0420556985'
  )
  'Key Vault Certificate User': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba'
  )
  'Key Vault Contributor': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'f25e0fa2-a7c8-4377-a976-54943a77a395'
  )
  'Key Vault Crypto Officer': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '14b46e9e-c2b7-41b4-b07b-48a6ebf60603'
  )
  'Key Vault Crypto Service Encryption User': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'e147488a-f6f5-4113-8e2d-b22465e65bf6'
  )
  'Key Vault Crypto User': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '12338af0-0e69-4776-bea7-57ae8d297424'
  )
  'Key Vault Reader': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '21090545-7ca7-4776-b22c-e363652d74d2'
  )
  'Key Vault Secrets Officer': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
  )
  'Key Vault Secrets User': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '4633458b-17de-408a-b874-0445c86b69e6'
  )
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Role Based Access Control Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'f58310d9-a9f6-439a-9e8d-f62e7b41a168'
  )
  'User Access Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
  )
}

var resourceAbbreviation = 'kv'
var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take('${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}', 24)
var resolvedName = derivedName

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

var resolvedEnablePurgeProtection = enablePurgeProtection ? enablePurgeProtection : null
var resolvedKeyVaultNetworkAcls = !empty(networkAcls ?? {})
  ? {
      bypass: networkAcls.?bypass
      defaultAction: networkAcls.?defaultAction
      virtualNetworkRules: networkAcls.?virtualNetworkRules ?? []
      ipRules: networkAcls.?ipRules ?? []
    }
  : null
var shouldCreateDefaultPrivateEndpoint = enableDefaultPrivateEndpoint
var defaultPrivateEndpointInputsAreValid = !shouldCreateDefaultPrivateEndpoint || defaultPrivateEndpointSubnetResourceId != null
  ? true
  : fail('The module-owned default private endpoint requires defaultPrivateEndpointSubnetResourceId when enableDefaultPrivateEndpoint is true.')
var defaultPrivateDnsZoneResourceId = resourceId('Microsoft.Network/privateDnsZones', defaultPrivateDnsZoneName)
var defaultPrivateEndpointWorkloadDescription = 'keyvault'
var defaultPrivateEndpointName = 'pep-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${defaultPrivateEndpointWorkloadDescription}-${instanceNumber}'
var defaultPrivateLinkServiceConnectionName = 'plsc-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${defaultPrivateEndpointWorkloadDescription}-${instanceNumber}'
var moduleOwnedPrivateEndpoints = shouldCreateDefaultPrivateEndpoint
  ? [
      {
        name: defaultPrivateEndpointName
        location: location
        resourceGroupName: resourceGroup().name
        privateLinkServiceConnectionName: defaultPrivateLinkServiceConnectionName
        service: 'vault'
        subnetResourceId: defaultPrivateEndpointInputsAreValid ? defaultPrivateEndpointSubnetResourceId! : null
        isManualConnection: false
        manualConnectionRequestMessage: null
        customDnsConfigs: null
        ipConfigurations: null
        applicationSecurityGroupResourceIds: null
        customNetworkInterfaceName: null
        lock: lock
        roleAssignments: null
        tags: tags
        privateDnsZoneGroup: {
          name: resolvedName
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

module keyVault_defaultPrivateDnsZone '../01-network/private-dns-zone.bicep' = if (shouldCreateDefaultPrivateEndpoint) {
  name: '${uniqueString(deployment().name, location)}-KeyVault-DefaultPrivateDnsZone'
  params: {
    name: defaultPrivateDnsZoneName
    location: 'global'
    virtualNetworkLinks: defaultPrivateDnsZoneVirtualNetworkLinks
    tags: tags
  }
}
var resolvedPrivateEndpoints = moduleOwnedPrivateEndpoints
var resolvedKeys = [
  for key in (keys ?? []): {
    name: key.name
    attributes: key.?attributes
    curveName: (key.?kty == 'EC' || key.?kty == 'EC-HSM')
      ? (!empty(key.?curveName) ? key.curveName : fail('Key Vault EC and EC-HSM keys require curveName to be declared explicitly.'))
      : null
    keyOps: key.?keyOps
    keySize: (key.?kty == 'RSA' || key.?kty == 'RSA-HSM')
      ? (key.?keySize != null ? key.keySize : fail('Key Vault RSA and RSA-HSM keys require keySize to be declared explicitly.'))
      : null
    kty: !empty(key.?kty) ? key.kty : fail('Key Vault keys require kty to be declared explicitly.')
    releasePolicy: key.?releasePolicy
    rotationPolicy: key.?rotationPolicy
    tags: key.?tags ?? tags
    roleAssignments: key.?roleAssignments
  }
]

// ============ //
// Dependencies //
// ============ //

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' = {
  name: resolvedName
  location: location
  tags: tags
  properties: {
    enabledForDeployment: enableVaultForDeployment
    enabledForTemplateDeployment: enableVaultForTemplateDeployment
    enabledForDiskEncryption: enableVaultForDiskEncryption
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enableRbacAuthorization: true
    createMode: createMode
    enablePurgeProtection: resolvedEnablePurgeProtection
    tenantId: subscription().tenantId
    sku: {
      name: sku
      family: 'A'
    }
    networkAcls: resolvedKeyVaultNetworkAcls
    publicNetworkAccess: publicNetworkAccess
  }
}

resource keyVault_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
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
    scope: keyVault
  }
]

module keyVault_secrets './key-vault-secret.bicep' = [
  for (secret, index) in (secrets ?? []): {
    name: '${uniqueString(deployment().name, location)}-KeyVault-Secret-${index}'
    params: {
      name: secret.name
      value: secret.value
      keyVaultName: keyVault.name
      attributesEnabled: secret.?attributes.?enabled
      attributesExp: secret.?attributes.?exp
      attributesNbf: secret.?attributes.?nbf
      contentType: secret.?contentType
      tags: secret.?tags ?? tags
      roleAssignments: secret.?roleAssignments    }
  }
]

module keyVault_keys './key-vault-key.bicep' = [
  for (key, index) in resolvedKeys: {
    name: '${uniqueString(deployment().name, location)}-KeyVault-Key-${index}'
    params: {
      name: key.name
      keyVaultName: keyVault.name
      attributesEnabled: key.?attributes.?enabled
      attributesExp: key.?attributes.?exp
      attributesNbf: key.?attributes.?nbf
      curveName: key.curveName
      keyOps: key.?keyOps
      keySize: key.keySize
      releasePolicy: key.?releasePolicy
      kty: key.kty
      tags: key.?tags ?? tags
      roleAssignments: key.?roleAssignments
      rotationPolicy: key.?rotationPolicy    }
  }
]

module keyVault_privateEndpoints '../01-network/private-endpoint.bicep' = [
  for (privateEndpoint, index) in resolvedPrivateEndpoints: {
    name: '${uniqueString(deployment().name, location)}-keyVault-PrivateEndpoint-${index}'
    dependsOn: shouldCreateDefaultPrivateEndpoint ? [keyVault_defaultPrivateDnsZone] : []
    scope: resourceGroup(privateEndpoint.resourceGroupName)
    params: {
      name: privateEndpoint.name
      privateLinkServiceConnections: !privateEndpoint.isManualConnection
        ? [
            {
              name: privateEndpoint.privateLinkServiceConnectionName
              properties: {
                privateLinkServiceId: keyVault.id
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
                privateLinkServiceId: keyVault.id
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

resource keyVault_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(keyVault.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: keyVault
  }
]

// =========== //
// Outputs     //
// =========== //
output resourceId string = keyVault.id

output resourceGroupName string = resourceGroup().name

output name string = keyVault.name

@description('The URI of the key vault.')
output uri string = keyVault.properties.vaultUri

output location string = keyVault.location

@description('The private endpoints of the key vault.')
output privateEndpoints privateEndpointOutputType[] = [
  for (item, index) in resolvedPrivateEndpoints: {
    name: keyVault_privateEndpoints[index].outputs.name
    resourceId: keyVault_privateEndpoints[index].outputs.resourceId
    groupId: keyVault_privateEndpoints[index].outputs.?groupId!
    customDnsConfigs: keyVault_privateEndpoints[index].outputs.customDnsConfigs
    networkInterfaceResourceIds: keyVault_privateEndpoints[index].outputs.networkInterfaceResourceIds
  }
]

@description('The properties of the created secrets.')
output secrets credentialOutputType[] = [
  #disable-next-line outputs-should-not-contain-secrets // Only returning the references, not any secret value
  for index in range(0, length(secrets ?? [])): {
    resourceId: keyVault_secrets[index].outputs.resourceId
    uri: keyVault_secrets[index].outputs.secretUri
    uriWithVersion: keyVault_secrets[index].outputs.secretUriWithVersion
  }
]

@description('The properties of the created keys.')
output keys credentialOutputType[] = [
  for index in range(0, length(keys ?? [])): {
    resourceId: keyVault_keys[index].outputs.resourceId
    uri: keyVault_keys[index].outputs.keyUri
    uriWithVersion: keyVault_keys[index].outputs.keyUriWithVersion
  }
]

// ================ //
// Definitions      //
// ================ //

@export()
@description('The type for rules governing the accessibility of the key vault from specific network locations.')
type networkAclsType = {
  @description('Optional. The bypass options for traffic for the network ACLs.')
  bypass: ('AzureServices' | 'None')?

  @description('Optional. The default action for the network ACLs, when no rule matches.')
  defaultAction: ('Allow' | 'Deny')?

  @description('Optional. A list of IP rules.')
  ipRules: {
    @description('Required. An IPv4 address range in CIDR notation, such as "124.56.78.91" (simple IP address) or "124.56.78.0/24".')
    value: string
  }[]?

  @description('Optional. A list of virtual network rules.')
  virtualNetworkRules: {
    @description('Required. The resource ID of the virtual network subnet.')
    id: string

    @description('Optional. Whether NRP will ignore the check if parent subnet has serviceEndpoints configured.')
    ignoreMissingVnetServiceEndpoint: bool?
  }[]?
}

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

@export()
@description('The type for a credential output.')
type credentialOutputType = {
  @description('The item\'s resourceId.')
  resourceId: string

  @description('The item\'s uri.')
  uri: string

  @description('The item\'s uri with version.')
  uriWithVersion: string
}

@export()
@description('The type for a secret output.')
type secretType = {
  @description('Required. The name of the secret.')
  name: string

  @description('Optional. Resource tags.')
  tags: object?

  @description('Optional. Contains attributes of the secret.')
  attributes: {
    @description('Optional. Defines whether the secret is enabled or disabled.')
    enabled: bool?

    @description('Optional. Defines when the secret will become invalid. Defined in seconds since 1970-01-01T00:00:00Z.')
    exp: int?

    @description('Optional. If set, defines the date from which onwards the secret becomes valid. Defined in seconds since 1970-01-01T00:00:00Z.')
    nbf: int?
  }?
  @description('Optional. The content type of the secret.')
  contentType: string?

  @description('Required. The value of the secret. NOTE: "value" will never be returned from the service, as APIs using this model are is intended for internal use in ARM deployments. Users should use the data-plane REST service for interaction with vault secrets.')
  @secure()
  value: string

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType[]?
}

import { rotationPolicyType } from './key-vault-key.bicep'

@export()
@description('The type for a key.')
type keyType = {
  @description('Required. The name of the key.')
  name: string

  @description('Optional. Resource tags.')
  tags: object?

  @description('Optional. Contains attributes of the key.')
  attributes: {
    @description('Optional. Defines whether the key is enabled or disabled.')
    enabled: bool?

    @description('Optional. Defines when the key will become invalid. Defined in seconds since 1970-01-01T00:00:00Z.')
    exp: int?

    @description('Optional. If set, defines the date from which onwards the key becomes valid. Defined in seconds since 1970-01-01T00:00:00Z.')
    nbf: int?
  }?
  @description('Optional. The elliptic curve name. Required when kty is "EC" or "EC-HSM".')
  curveName: ('P-256' | 'P-256K' | 'P-384' | 'P-521')?

  @description('Optional. The allowed operations on this key.')
  keyOps: ('decrypt' | 'encrypt' | 'import' | 'release' | 'sign' | 'unwrapKey' | 'verify' | 'wrapKey')[]?

  @description('Optional. The key size in bits. Required when kty is "RSA" or "RSA-HSM".')
  keySize: (2048 | 3072 | 4096)?

  @description('Required. The type of the key.')
  kty: ('EC' | 'EC-HSM' | 'RSA' | 'RSA-HSM')

  @description('Optional. Key release policy.')
  releasePolicy: {
    @description('Optional. Content type and version of key release policy.')
    contentType: string?

    @description('Optional. Blob encoding the policy rules under which the key can be released.')
    data: string?
  }?

  @description('Optional. Key rotation policy.')
  rotationPolicy: rotationPolicyType?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType[]?
}

resource keyVault_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${resolvedName}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?notes ?? (lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: keyVault
}
