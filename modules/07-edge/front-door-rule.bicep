metadata name = 'CDN Profiles Rules'
metadata description = 'This module deploys a CDN Profile rule.'
param name string
param profileName string
param ruleSetName string
param order int
param actions resourceInput<'Microsoft.Cdn/profiles/ruleSets/rules@2025-06-01'>.properties.actions?
param conditions resourceInput<'Microsoft.Cdn/profiles/ruleSets/rules@2025-06-01'>.properties.conditions?
@allowed([
  'Continue'
  'Stop'
])
param matchProcessingBehavior string = 'Continue'

resource profile 'Microsoft.Cdn/profiles@2025-06-01' existing = {
  name: profileName

  resource ruleSet 'ruleSets@2025-06-01' existing = {
    name: ruleSetName
  }
}

resource rule 'Microsoft.Cdn/profiles/ruleSets/rules@2025-06-01' = {
  name: name
  parent: profile::ruleSet
  properties: {
    order: order
    actions: actions
    conditions: conditions
    matchProcessingBehavior: matchProcessingBehavior
  }
}
output name string = rule.name
output resourceId string = rule.id
output resourceGroupName string = resourceGroup().name
