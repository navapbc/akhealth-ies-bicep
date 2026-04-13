metadata name = 'Key Vault Secrets'
metadata description = 'This module deploys a Key Vault Secret.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'

@description('Conditional. The name of the parent key vault. Required if the template is used in a standalone deployment.')
param keyVaultName string

@description('Required. The name of the secret (letters (upper and lower case), numbers, -).')
@minLength(1)
@maxLength(127)
param name string

@description('Optional. Resource tags.')
param tags resourceInput<'Microsoft.KeyVault/vaults/secrets@2024-11-01'>.tags?

@description('Optional. Determines whether the object is enabled.')
param attributesEnabled bool?

@description('Optional. Expiry date in seconds since 1970-01-01T00:00:00Z. For security reasons, it is recommended to set an expiration date whenever possible.')
param attributesExp int?

@description('Optional. Not before date in seconds since 1970-01-01T00:00:00Z.')
param attributesNbf int?

@description('Optional. The content type of the secret.')
@secure()
param contentType string?

@description('Required. The value of the secret. NOTE: "value" will never be returned from the service, as APIs using this model are is intended for internal use in ARM deployments. Users should use the data-plane REST service for interaction with vault secrets.')
@secure()
param value string

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?


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

resource secret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  name: name
  parent: keyVault
  tags: tags
  properties: {
    contentType: contentType
    attributes: {
      enabled: attributesEnabled
      exp: attributesExp
      nbf: attributesNbf
    }
    value: value
  }
}

resource secret_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(secret.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: secret
  }
]

output name string = secret.name

output resourceId string = secret.id

@description('The uri of the secret.')
output secretUri string = secret.properties.secretUri

@description('The uri with version of the secret.')
output secretUriWithVersion string = secret.properties.secretUriWithVersion

output resourceGroupName string = resourceGroup().name
