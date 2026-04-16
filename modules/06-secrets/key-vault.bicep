metadata name = 'Key Vaults'
metadata description = 'This module deploys a Key Vault.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'
import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

// ================ //
// Parameters       //
// ================ //
param systemAbbreviation string
param environmentAbbreviation string
param instanceNumber string
param workloadDescription string = ''
param location string = resourceGroup().location
param secrets secretType[]?
param keys keyType[]?
param enableVaultForDeployment bool = true
param enableVaultForTemplateDeployment bool = true
param enableVaultForDiskEncryption bool
param softDeleteRetentionInDays int
@allowed([
  'default'
  'recover'
])
param createMode string
param enablePurgeProtection bool
@allowed([
  'premium'
  'standard'
])
param sku string
param networkAcls networkAclsType?
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string

import { lockType } from '../shared/avm-common-types.bicep'
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
param roleAssignments roleAssignmentType[]?

import {
  virtualNetworkLinkType
} from '../shared/shared.types.bicep'
param enableDefaultPrivateEndpoint bool = false
param defaultPrivateEndpointSubnetResourceId string?
param defaultPrivateNetworkingResourceGroupName string?
param defaultPrivateDnsZoneName string = 'privatelink.vaultcore.azure.net'
param defaultPrivateDnsZoneVirtualNetworkLinks virtualNetworkLinkType[] = []
param tags resourceInput<'Microsoft.KeyVault/vaults@2024-11-01'>.tags?

import { diagnosticSettingFullType } from '../shared/avm-common-types.bicep'
param diagnosticSettings diagnosticSettingFullType[]?

// =========== //
// Variables   //
// =========== //

var resourceAbbreviation = 'kv'
var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take('${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}', 24)
var resolvedName = derivedName
var diagnosticSettingsDerivedName = replace(resolvedName, '${resourceAbbreviation}-', 'dgs${resourceAbbreviation}-')
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
var defaultPrivateNetworkingResolvedResourceGroupName = defaultPrivateNetworkingResourceGroupName ?? resourceGroup().name
var defaultPrivateDnsZoneResourceId = resourceId(defaultPrivateNetworkingResolvedResourceGroupName, 'Microsoft.Network/privateDnsZones', defaultPrivateDnsZoneName)
var defaultPrivateEndpointWorkloadDescription = 'keyvault'
var defaultPrivateEndpointName = 'pep-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${defaultPrivateEndpointWorkloadDescription}-${instanceNumber}'
var defaultPrivateLinkServiceConnectionName = 'plsc-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${defaultPrivateEndpointWorkloadDescription}-${instanceNumber}'
var moduleOwnedPrivateEndpoints = shouldCreateDefaultPrivateEndpoint
  ? [
      {
        name: defaultPrivateEndpointName
        location: location
        resourceGroupName: defaultPrivateNetworkingResolvedResourceGroupName
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
  scope: resourceGroup(defaultPrivateNetworkingResolvedResourceGroupName)
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
    name: diagnosticSetting.?name ?? (length(diagnosticSettings ?? []) > 1 ? '${diagnosticSettingsDerivedName}-${index + 1}' : diagnosticSettingsDerivedName)
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
output uri string = keyVault.properties.vaultUri
output location string = keyVault.location
output privateEndpoints privateEndpointOutputType[] = [
  for (item, index) in resolvedPrivateEndpoints: {
    name: keyVault_privateEndpoints[index].outputs.name
    resourceId: keyVault_privateEndpoints[index].outputs.resourceId
    groupId: keyVault_privateEndpoints[index].outputs.?groupId!
    customDnsConfigs: keyVault_privateEndpoints[index].outputs.customDnsConfigs
    networkInterfaceResourceIds: keyVault_privateEndpoints[index].outputs.networkInterfaceResourceIds
  }
]
output secrets credentialOutputType[] = [
  #disable-next-line outputs-should-not-contain-secrets // Only returning the references, not any secret value
  for index in range(0, length(secrets ?? [])): {
    resourceId: keyVault_secrets[index].outputs.resourceId
    uri: keyVault_secrets[index].outputs.secretUri
    uriWithVersion: keyVault_secrets[index].outputs.secretUriWithVersion
  }
]
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
type networkAclsType = {
  bypass: ('AzureServices' | 'None')?
  defaultAction: ('Allow' | 'Deny')?
  ipRules: {
    value: string
  }[]?

  virtualNetworkRules: {
    id: string
    ignoreMissingVnetServiceEndpoint: bool?
  }[]?
}

@export()
type privateEndpointOutputType = {
  name: string
  resourceId: string
  groupId: string?
  customDnsConfigs: {
    fqdn: string?
    ipAddresses: string[]
  }[]

  networkInterfaceResourceIds: string[]
}

@export()
type credentialOutputType = {
  resourceId: string
  uri: string
  uriWithVersion: string
}

@export()
type secretType = {
  name: string
  tags: object?
  attributes: {
    enabled: bool?
    exp: int?
    nbf: int?
  }?
  contentType: string?
  @secure()
  value: string
  roleAssignments: roleAssignmentType[]?
}

import { rotationPolicyType } from './key-vault-key.bicep'

@export()
type keyType = {
  name: string
  tags: object?
  attributes: {
    enabled: bool?
    exp: int?
    nbf: int?
  }?
  curveName: ('P-256' | 'P-256K' | 'P-384' | 'P-521')?
  keyOps: ('decrypt' | 'encrypt' | 'import' | 'release' | 'sign' | 'unwrapKey' | 'verify' | 'wrapKey')[]?
  keySize: (2048 | 3072 | 4096)?
  kty: ('EC' | 'EC-HSM' | 'RSA' | 'RSA-HSM')
  releasePolicy: {
    contentType: string?
    data: string?
  }?
  rotationPolicy: rotationPolicyType?
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
