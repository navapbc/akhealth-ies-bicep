metadata name = 'Key Vault Keys'
metadata description = 'This module deploys a Key Vault Key.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'

param keyVaultName string
param name string
param tags resourceInput<'Microsoft.KeyVault/vaults/keys@2024-11-01'>.tags?
param attributesEnabled bool?
param attributesExp int?
param attributesNbf int?
param curveName ('P-256' | 'P-256K' | 'P-384' | 'P-521')?
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
param keySize int?
param kty ('EC' | 'EC-HSM' | 'RSA' | 'RSA-HSM')
param releasePolicy object?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
param roleAssignments roleAssignmentType[]?
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
type rotationPolicyType = {
  attributes: {
    expiryTime: string?
  }?
  lifetimeActions: {
    action: {
      type: ('rotate' | 'notify')?
    }?
    trigger: {
      timeAfterCreate: string?
      timeBeforeExpiry: string?
    }?
  }[]?
}
output keyUri string = key.properties.keyUri
output keyUriWithVersion string = key.properties.keyUriWithVersion
output name string = key.name
output resourceId string = key.id
output resourceGroupName string = resourceGroup().name
