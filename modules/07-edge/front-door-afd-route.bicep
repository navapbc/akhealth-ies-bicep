metadata name = 'CDN Profiles AFD Endpoint Route'
metadata description = 'This module deploys a CDN Profile AFD Endpoint route.'
param name string
param profileName string
param afdEndpointName string
param cacheConfiguration resourceInput<'Microsoft.Cdn/profiles/afdEndpoints/routes@2025-06-01'>.properties.cacheConfiguration?
param customDomainNames string[]?
@allowed([
  'HttpOnly'
  'HttpsOnly'
  'MatchRequest'
])
param forwardingProtocol string
@allowed([
  'Disabled'
  'Enabled'
])
param enabledState string
@allowed([
  'Disabled'
  'Enabled'
])
param httpsRedirect string
@allowed([
  'Disabled'
  'Enabled'
])
param linkToDefaultDomain string
param originGroupName string
param originPath string?
param patternsToMatch resourceInput<'Microsoft.Cdn/profiles/afdEndpoints/routes@2025-06-01'>.properties.patternsToMatch?
param ruleSets string[]?
@allowed(['Http', 'Https'])
param supportedProtocols resourceInput<'Microsoft.Cdn/profiles/afdEndpoints/routes@2025-06-01'>.properties.supportedProtocols?

resource profile 'Microsoft.Cdn/profiles@2025-06-01' existing = {
  name: profileName

  resource afdEndpoint 'afdEndpoints@2025-06-01' existing = {
    name: afdEndpointName
  }

  resource customDomains 'customDomains@2025-06-01' existing = [
    for customDomainName in (customDomainNames ?? []): {
      name: customDomainName
    }
  ]

  resource originGroup 'originGroups@2025-06-01' existing = {
    name: originGroupName
  }

  resource ruleSet 'ruleSets@2025-06-01' existing = [
    for ruleSet in (ruleSets ?? []): {
      name: ruleSet
    }
  ]
}

resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2025-06-01' = {
  name: name
  parent: profile::afdEndpoint
  properties: {
    cacheConfiguration: cacheConfiguration
    customDomains: [
      for index in range(0, length(customDomainNames ?? [])): {
        id: profile::customDomains[index].id
      }
    ]
    enabledState: enabledState
    forwardingProtocol: forwardingProtocol
    httpsRedirect: httpsRedirect
    linkToDefaultDomain: linkToDefaultDomain
    originGroup: {
      id: profile::originGroup.id
    }
    originPath: originPath
    patternsToMatch: patternsToMatch
    ruleSets: [
      for (item, index) in (ruleSets ?? []): {
        id: profile::ruleSet[index].id
      }
    ]
    supportedProtocols: supportedProtocols
  }
}
output name string = route.name
output resourceId string = route.id
output resourceGroupName string = resourceGroup().name
