metadata name = 'CDN Profiles Origin'
metadata description = 'This module deploys a CDN Profile Origin.'
param name string
param profileName string
param originGroupName string
@allowed([
  'Disabled'
  'Enabled'
])
param enabledState string
param enforceCertificateNameCheck bool
param hostName string
param httpPort int
param httpsPort int
param originHostHeader string
param priority int
param sharedPrivateLinkResource resourceInput<'Microsoft.Cdn/profiles/originGroups/origins@2025-06-01'>.properties.sharedPrivateLinkResource?
param weight int

resource profile 'Microsoft.Cdn/profiles@2025-06-01' existing = {
  name: profileName

  resource originGroup 'originGroups@2025-06-01' existing = {
    name: originGroupName
  }
}

resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2025-06-01' = {
  name: name
  parent: profile::originGroup
  properties: {
    enabledState: enabledState
    enforceCertificateNameCheck: enforceCertificateNameCheck
    hostName: hostName
    httpPort: httpPort
    httpsPort: httpsPort
    originHostHeader: originHostHeader
    priority: priority
    sharedPrivateLinkResource: sharedPrivateLinkResource
    weight: weight
  }
}
output name string = origin.name
output resourceId string = origin.id
output resourceGroupName string = resourceGroup().name
