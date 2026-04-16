metadata name = 'Application Gateway Web Application Firewall (WAF) Policies'
metadata description = 'This module deploys an Application Gateway Web Application Firewall (WAF) Policy.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'
import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

param systemAbbreviation string
param environmentAbbreviation string
param instanceNumber string
param workloadDescription string = ''
param location string = resourceGroup().location
param tags resourceInput<'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2025-05-01'>.tags?
param managedRules resourceInput<'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2025-05-01'>.properties.managedRules
param customRules resourceInput<'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2025-05-01'>.properties.customRules?
param policySettings resourceInput<'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2025-05-01'>.properties.policySettings?

import { lockType } from '../shared/avm-common-types.bicep'
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
param roleAssignments roleAssignmentType[]?
var resourceAbbreviation = 'agwfp'
var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take(
  '${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}',
  80
)
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
output name string = applicationGatewayWAFPolicy.name
output resourceId string = applicationGatewayWAFPolicy.id
output resourceGroupName string = resourceGroup().name
output location string = applicationGatewayWAFPolicy.location

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
