metadata name = 'CDN Profiles Rule Sets'
metadata description = 'This module deploys a CDN Profile rule set.'
param name string
param profileName string
param rules ruleType[]?

resource profile 'Microsoft.Cdn/profiles@2025-06-01' existing = {
  name: profileName
}

resource ruleSet 'Microsoft.Cdn/profiles/ruleSets@2025-06-01' = {
  name: name
  parent: profile
}

module ruleSet_rules './front-door-rule.bicep' = [
  for (rule, index) in (rules ?? []): {
    name: '${uniqueString(deployment().name)}-RuleSet-Rule-${rule.name}-${index}'
    params: {
      profileName: profileName
      ruleSetName: name
      name: rule.name
      order: rule.order
      actions: rule.?actions
      conditions: rule.?conditions
      matchProcessingBehavior: rule.?matchProcessingBehavior
    }
  }
]
output name string = ruleSet.name
output resourceId string = ruleSet.id
output resourceGroupName string = resourceGroup().name

// =============== //
//   Definitions   //
// =============== //

@export()
type ruleType = {
  name: string
  order: int
  actions: resourceInput<'Microsoft.Cdn/profiles/ruleSets/rules@2025-06-01'>.properties.actions?
  conditions: resourceInput<'Microsoft.Cdn/profiles/ruleSets/rules@2025-06-01'>.properties.conditions?
  matchProcessingBehavior: 'Continue' | 'Stop' | null
}
