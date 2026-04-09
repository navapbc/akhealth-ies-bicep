metadata name = 'Application Gateway Web Application Firewall (WAF) Policies'
metadata description = 'This module deploys an Application Gateway Web Application Firewall (WAF) Policy.'

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

@description('Required. System abbreviation used for resource naming.')
param systemAbbreviation string

@description('Required. Environment abbreviation used for resource naming.')
param environmentAbbreviation string

@description('Required. Instance number used for resource naming.')
param instanceNumber string

@description('Optional. Workload description segment used for resource naming.')
param workloadDescription string = ''

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Resource tags.')
param tags resourceInput<'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2025-05-01'>.tags?


@description('Required. Describes the managedRules structure.')
param managedRules resourceInput<'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2025-05-01'>.properties.managedRules

@description('Optional. The custom rules inside the policy.')
param customRules resourceInput<'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2025-05-01'>.properties.customRules?

@description('Optional. The PolicySettings for policy.')
param policySettings resourceInput<'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2025-05-01'>.properties.policySettings?

import { lockType } from '../shared/avm-common-types.bicep'
@description('Optional. The lock settings of the service.')
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

var resourceAbbreviation = 'agwfp'
var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take(
  '${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}',
  80
)
var resolvedName = derivedName

var builtInRoleNames = {
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Network Contributor': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '4d97b98b-1d4f-4787-a291-c67834d212e7'
  )
  'Role Based Access Control Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'f58310d9-a9f6-439a-9e8d-f62e7b41a168'
  )
  'User Access Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
  )
}

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

resource applicationGatewayWAFPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2025-05-01' = {
  name: resolvedName
  location: location
  tags: tags
  properties: {
    managedRules: managedRules
    customRules: customRules
    policySettings: policySettings
  }
}

resource applicationGatewayWAFPolicy_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${resolvedName}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?notes ?? (lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: applicationGatewayWAFPolicy
}

resource applicationGatewayWAFPolicy_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(
      applicationGatewayWAFPolicy.id,
      roleAssignment.principalId,
      roleAssignment.roleDefinitionId
    )
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: applicationGatewayWAFPolicy
  }
]

@description('The name of the application gateway WAF policy.')
output name string = applicationGatewayWAFPolicy.name

@description('The resource ID of the application gateway WAF policy.')
output resourceId string = applicationGatewayWAFPolicy.id

@description('The resource group the application gateway WAF policy was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The location the resource was deployed into.')
output location string = applicationGatewayWAFPolicy.location
