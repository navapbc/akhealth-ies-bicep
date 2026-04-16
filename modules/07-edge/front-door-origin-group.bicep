metadata name = 'CDN Profiles Origin Group'
metadata description = 'This module deploys a CDN Profile Origin Group.'
param name string
param profileName string
param healthProbeSettings resourceInput<'Microsoft.Cdn/profiles/originGroups@2025-06-01'>.properties.healthProbeSettings?
param loadBalancingSettings resourceInput<'Microsoft.Cdn/profiles/originGroups@2025-06-01'>.properties.loadBalancingSettings
param authentication resourceInput<'Microsoft.Cdn/profiles/originGroups@2025-06-01'>.properties.authentication?
@allowed([
  'Disabled'
  'Enabled'
])
param sessionAffinityState string
param trafficRestorationTimeToHealedOrNewEndpointsInMinutes int
param origins originType[]

resource profile 'Microsoft.Cdn/profiles@2025-06-01' existing = {
  name: profileName
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2025-06-01' = {
  name: name
  parent: profile
  properties: {
    authentication: authentication
    healthProbeSettings: healthProbeSettings
    loadBalancingSettings: loadBalancingSettings
    sessionAffinityState: sessionAffinityState
    trafficRestorationTimeToHealedOrNewEndpointsInMinutes: trafficRestorationTimeToHealedOrNewEndpointsInMinutes
  }
}

module originGroup_origins './front-door-origin-group-origin.bicep' = [
  for (origin, index) in origins: {
    name: '${uniqueString(deployment().name)}-OriginGroup-Origin-${index}'
    params: {
      name: origin.name
      profileName: profileName
      hostName: origin.hostName
      originGroupName: originGroup.name
      enabledState: origin.enabledState
      enforceCertificateNameCheck: origin.enforceCertificateNameCheck
      httpPort: origin.httpPort
      httpsPort: origin.httpsPort
      originHostHeader: origin.originHostHeader
      priority: origin.priority
      weight: origin.weight
      sharedPrivateLinkResource: origin.?sharedPrivateLinkResource    }
  }
]
output name string = originGroup.name
output resourceId string = originGroup.id
output resourceGroupName string = resourceGroup().name
output location string = profile.location

// =============== //
//   Definitions   //
// =============== //

@export()
type loadBalancingSettingsType = {
  additionalLatencyInMilliseconds: int
  sampleSize: int
  successfulSamplesRequired: int
}

@export()
type healthProbeSettingsType = {
  probePath: string?
  probeProtocol: 'Http' | 'Https' | 'NotSet' | null
  probeRequestType: 'GET' | 'HEAD' | 'NotSet' | null
  probeIntervalInSeconds: int?
}

@export()
type originType = {
  name: string
  hostName: string
  enabledState: 'Enabled' | 'Disabled'
  enforceCertificateNameCheck: bool
  httpPort: int
  httpsPort: int
  originHostHeader: string
  priority: int
  weight: int
  sharedPrivateLinkResource: resourceInput<'Microsoft.Cdn/profiles/originGroups/origins@2025-06-01'>.properties.sharedPrivateLinkResource?
}
