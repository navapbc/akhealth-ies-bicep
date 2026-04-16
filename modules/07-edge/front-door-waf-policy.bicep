metadata name = 'Front Door Web Application Firewall (WAF) Policies'
metadata description = 'This module deploys a Front Door Web Application Firewall (WAF) Policy.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'
import { regionAbbreviations } from '../shared/region-abbreviations.bicep'
import { frontDoorConfigType } from '../shared/shared.types.bicep'

param systemAbbreviation string
param environmentAbbreviation string
param instanceNumber string
param workloadDescription string = ''
param config frontDoorConfigType
param tags resourceInput<'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2025-10-01'>.tags?

import { lockType } from '../shared/avm-common-types.bicep'
@sys.description('Optional. The lock settings of the service.')
param lock lockType?

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
@sys.description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?
var resourceAbbreviation = 'fdfp'
var resourceLocation = 'global'
var regionAbbreviation = regionAbbreviations[resourceLocation]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take(
  replace('${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}', '-', ''),
  128
)
var resolvedName = derivedName
var resolvedCustomRules = config.enableDefaultWafMethodBlock
  ? {
      rules: [
        {
          name: 'BlockMethod'
          enabledState: 'Enabled'
          action: 'Block'
          ruleType: 'MatchRule'
          priority: 10
          rateLimitDurationInMinutes: 1
          rateLimitThreshold: 100
          matchConditions: [
            {
              matchVariable: 'RequestMethod'
              operator: 'Equal'
              negateCondition: true
              matchValue: [
                'GET'
                'OPTIONS'
                'HEAD'
              ]
            }
          ]
        }
      ]
    }
  : config.wafCustomRules
var resolvedManagedRules = config.sku == 'Premium_AzureFrontDoor'
  ? {
      managedRuleSets: config.wafManagedRuleSets
    }
  : {
      managedRuleSets: []
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

resource frontDoorWAFPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2025-10-01' = {
  name: resolvedName
  location: resourceLocation
  sku: {
    name: config.sku
  }
  tags: tags
  properties: {
    customRules: resolvedCustomRules
    managedRules: resolvedManagedRules
    policySettings: config.wafPolicySettings
  }
}

resource frontDoorWAFPolicy_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(
      frontDoorWAFPolicy.id,
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
    scope: frontDoorWAFPolicy
  }
]
output name string = frontDoorWAFPolicy.name
output resourceId string = frontDoorWAFPolicy.id
output resourceGroupName string = resourceGroup().name
output location string = frontDoorWAFPolicy.location

// =============== //
//   Definitions   //
// =============== //

@export()
type managedRulesType = {
  managedRuleSets: managedRuleSetType[]?
}

@export()
type managedRuleSetType = {
  ruleSetType: string
  ruleSetVersion: string
  ruleGroupOverrides: array?
  exclusions: array?
  ruleSetAction: 'Block' | 'Log' | 'Redirect' | null
}

@export()
type customRulesType = {
  rules: customRulesRuleType[]?
}

@export()
type customRulesRuleType = {
  action: 'Allow' | 'Block' | 'Log' | 'Redirect'
  enabledState: 'Enabled' | 'Disabled'
  matchConditions: array
  name: string
  priority: int
  rateLimitDurationInMinutes: int?
  rateLimitThreshold: int?
  ruleType: 'MatchRule' | 'RateLimitRule'
}

resource frontDoorWAFPolicy_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${resolvedName}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?notes ?? (lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: frontDoorWAFPolicy
}
