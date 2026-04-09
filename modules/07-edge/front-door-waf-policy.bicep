metadata name = 'Front Door Web Application Firewall (WAF) Policies'
metadata description = 'This module deploys a Front Door Web Application Firewall (WAF) Policy.'

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'
import { frontDoorConfigType } from '../shared/shared.types.bicep'

@description('Required. System abbreviation used for resource naming.')
param systemAbbreviation string

@description('Required. Environment abbreviation used for resource naming.')
param environmentAbbreviation string

@description('Required. Instance number used for resource naming.')
param instanceNumber string

@description('Optional. Workload description segment used for resource naming.')
param workloadDescription string = ''

@description('Required. Declared Front Door configuration for this workload.')
param config frontDoorConfigType

@description('Optional. Resource tags.')
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

var builtInRoleNames = {
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
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
@description('The type for the managed rules.')
type managedRulesType = {
  @description('Optional. List of rule sets.')
  managedRuleSets: managedRuleSetType[]?
}

@export()
@description('The type for the managed rule set.')
type managedRuleSetType = {
  @description('Required. Defines the rule set type to use.')
  ruleSetType: string

  @description('Required. Defines the version of the rule set to use.')
  ruleSetVersion: string

  @description('Optional. Defines the rule group overrides to apply to the rule set.')
  ruleGroupOverrides: array?

  @description('Optional. Describes the exclusions that are applied to all rules in the set.')
  exclusions: array?

  @description('Optional. Defines the rule set action.')
  ruleSetAction: 'Block' | 'Log' | 'Redirect' | null
}

@export()
@description('The type for the custom rules.')
type customRulesType = {
  @description('Optional. List of rules.')
  rules: customRulesRuleType[]?
}

@export()
@description('The type for the custom rules rule.')
type customRulesRuleType = {
  @description('Required. Describes what action to be applied when rule matches.')
  action: 'Allow' | 'Block' | 'Log' | 'Redirect'

  @description('Required. Describes if the custom rule is in enabled or disabled state.')
  enabledState: 'Enabled' | 'Disabled'

  @description('Required. List of match conditions. See https://learn.microsoft.com/en-us/azure/templates/microsoft.network/frontdoorwebapplicationfirewallpolicies#matchcondition for details.')
  matchConditions: array

  @description('Required. Describes the name of the rule.')
  name: string

  @description('Required. Describes priority of the rule. Rules with a lower value will be evaluated before rules with a higher value.')
  priority: int

  @description('Optional. Time window for resetting the rate limit count. Default is 1 minute.')
  rateLimitDurationInMinutes: int?

  @description('Optional. Number of allowed requests per client within the time window.')
  rateLimitThreshold: int?

  @description('Required. Describes type of rule.')
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
