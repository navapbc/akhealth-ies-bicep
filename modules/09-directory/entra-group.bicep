targetScope = 'tenant'

metadata name = 'Microsoft Entra Group'
metadata description = 'This module creates and populates a Microsoft Entra security group.'

extension microsoftGraphV1 with {
  relationshipSemantics: 'replace'
}

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

@description('Required. Abbreviation for the owning system.')
param systemAbbreviation string

@description('Required. Abbreviation for the lifecycle environment.')
param environmentAbbreviation string

@description('Required. Instance number used for deterministic naming.')
param instanceNumber string

@description('Required. Workload descriptor to include in the group name.')
param workloadDescription string

@description('Required. Deployment location used to derive the region abbreviation for naming.')
param location string

@description('Optional. Human-readable description for the group.')
param groupDescription string = ''

@description('Required. Object IDs of Microsoft Entra principals that should be members of the group.')
param memberObjectIds string[]

@description('Optional. Object IDs of Microsoft Entra principals that should own the group.')
param ownerObjectIds string[] = []

var resourceAbbreviation = 'grp'
var regionAbbreviation = regionAbbreviations[?location] ?? toLower(location)
var derivedDisplayName = '${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${workloadDescription}-${instanceNumber}'
var derivedMailNickname = take(toLower(replace(derivedDisplayName, '-', '')), 64)
var derivedUniqueName = toLower(derivedDisplayName)

resource entraGroup 'Microsoft.Graph/groups@v1.0' = {
  displayName: derivedDisplayName
  description: !empty(groupDescription) ? groupDescription : null
  mailEnabled: false
  mailNickname: derivedMailNickname
  securityEnabled: true
  uniqueName: derivedUniqueName
  members: !empty(memberObjectIds)
    ? {
        relationships: memberObjectIds
      }
    : null
  owners: !empty(ownerObjectIds)
    ? {
        relationships: ownerObjectIds
      }
    : null
}

@description('The display name of the Microsoft Entra group.')
output name string = derivedDisplayName

@description('The object ID of the Microsoft Entra group.')
output objectId string = entraGroup.id

@description('The mail nickname of the Microsoft Entra group.')
output mailNickname string = derivedMailNickname
