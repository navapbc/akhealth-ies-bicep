metadata name = 'CDN Profiles Security Policy'
metadata description = 'This module deploys a CDN Profile Security Policy.'

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

param systemAbbreviation string
param environmentAbbreviation string
param instanceNumber string
param workloadDescription string = ''
param profileName string
param wafPolicyResourceId string

// param associations associationsType
param associations associationsType[]
var resourceAbbreviation = 'fdsecp'
var resourceLocation = 'global'
var regionAbbreviation = regionAbbreviations[resourceLocation]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take(
  '${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}',
  128
)
var resolvedName = derivedName

resource profile 'Microsoft.Cdn/profiles@2025-06-01' existing = {
  name: profileName
}

resource securityPolicies 'Microsoft.Cdn/profiles/securityPolicies@2025-06-01' = {
  name: resolvedName
  parent: profile
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: wafPolicyResourceId
      }
      associations: associations
    }
  }
}
output name string = securityPolicies.name
output resourceId string = securityPolicies.id
output resourceGroupName string = resourceGroup().name

// =============== //
//   Definitions   //
// =============== //

@export()
type associationsType = {
  domains: {
    id: string
  }[]
  patternsToMatch: string[]
}
