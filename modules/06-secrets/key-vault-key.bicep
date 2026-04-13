metadata name = 'Key Vault Keys'
metadata description = 'This module deploys a Key Vault Key.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'

@description('Conditional. The name of the parent key vault. Required if the template is used in a standalone deployment.')
param keyVaultName string

@description('Required. The name of the key.')
param name string

@description('Optional. Resource tags.')
param tags resourceInput<'Microsoft.KeyVault/vaults/keys@2024-11-01'>.tags?

@description('Optional. Determines whether the object is enabled.')
param attributesEnabled bool?

@description('Optional. Expiry date in seconds since 1970-01-01T00:00:00Z. For security reasons, it is recommended to set an expiration date whenever possible.')
param attributesExp int?

@description('Optional. Not before date in seconds since 1970-01-01T00:00:00Z.')
param attributesNbf int?

@description('Optional. The elliptic curve name.')
param curveName ('P-256' | 'P-256K' | 'P-384' | 'P-521')?

@description('Optional. Array of JsonWebKeyOperation.')
@allowed([
  'decrypt'
  'encrypt'
  'import'
  'sign'
  'unwrapKey'
  'verify'
  'wrapKey'
])
param keyOps string[]?

@description('Optional. The key size in bits. For example: 2048, 3072, or 4096 for RSA.')
param keySize int?

@description('Required. The type of the key.')
param kty ('EC' | 'EC-HSM' | 'RSA' | 'RSA-HSM')

@description('Optional. Key release policy.')
param releasePolicy object?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

@description('Optional. Key rotation policy properties object.')
param rotationPolicy rotationPolicyType?


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

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

resource key 'Microsoft.KeyVault/vaults/keys@2025-05-01' = {
  name: name
  parent: keyVault
  tags: tags
  properties: {
    attributes: {
      enabled: attributesEnabled
      exp: attributesExp
      nbf: attributesNbf
    }
    keyOps: keyOps
    kty: kty
    ...(!empty(curveName)
      ? {
          curveName: curveName
        }
      : {})
    ...(keySize != null
      ? {
          keySize: keySize
        }
      : {})
    ...(!empty(releasePolicy ?? {})
      ? {
          release_policy: releasePolicy
        }
      : {})
    ...(!empty(rotationPolicy)
      ? {
          rotationPolicy: rotationPolicy
        }
      : {})
  }
}

resource key_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(key.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: key
  }
]

@export()
@description('The type for a rotation policy.')
type rotationPolicyType = {
  @description('Optional. The attributes of key rotation policy.')
  attributes: {
    @description('Optional. The expiration time for the new key version. It should be in ISO8601 format. Eg: "P90D", "P1Y".')
    expiryTime: string?
  }?

  @description('Optional. The key rotation policy lifetime actions.')
  lifetimeActions: {
    @description('Optional. The type of the action.')
    action: {
      @description('Optional. The type of the action.')
      type: ('rotate' | 'notify')?
    }?

    @description('Optional. The time duration for rotating the key.')
    trigger: {
      @description('Optional. The time duration after key creation to rotate the key. It only applies to rotate. It will be in ISO 8601 duration format. Eg: "P90D", "P1Y".')
      timeAfterCreate: string?

      @description('Optional. The time duration before key expiring to rotate or notify. It will be in ISO 8601 duration format. Eg: "P90D", "P1Y".')
      timeBeforeExpiry: string?
    }?
  }[]?
}

@description('The uri of the key.')
output keyUri string = key.properties.keyUri

@description('The uri with version of the key.')
output keyUriWithVersion string = key.properties.keyUriWithVersion

output name string = key.name

output resourceId string = key.id

output resourceGroupName string = resourceGroup().name
