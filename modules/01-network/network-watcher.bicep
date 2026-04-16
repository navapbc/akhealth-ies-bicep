metadata name = 'Network Watcher'
metadata description = 'This module deploys a regional Azure Network Watcher instance.'

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

param systemAbbreviation string
param environmentAbbreviation string
param instanceNumber string
param workloadDescription string = ''
param location string = resourceGroup().location
param tags resourceInput<'Microsoft.Network/networkWatchers@2024-05-01'>.tags?

var resourceAbbreviation = 'nw'
var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var resolvedName = take(
  '${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}',
  80
)

resource networkWatcher 'Microsoft.Network/networkWatchers@2024-05-01' = {
  name: resolvedName
  location: location
  tags: tags
  properties: {}
}

output name string = networkWatcher.name
output resourceId string = networkWatcher.id
output resourceGroupName string = resourceGroup().name
output location string = networkWatcher.location
