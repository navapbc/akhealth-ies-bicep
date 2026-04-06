targetScope = 'resourceGroup'

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'

@description('Required. System abbreviation used for resource naming.')
param systemAbbreviation string

@description('Required. Environment abbreviation used for resource naming.')
param environmentAbbreviation string

@description('Required. Instance number used for resource naming.')
param instanceNumber string

@description('Optional. Workload description segment used for resource naming.')
param workloadDescription string = ''

@description('Optional. Location for the workspace.')
param location string = resourceGroup().location

@description('Optional. Tags to apply to the workspace.')
param tags object = {}

@description('Optional. Workspace SKU.')
param sku string

@description('Optional. Workspace retention in days.')
param retentionInDays int

@description('Optional. Enable resource-permission-only log access.')
param enableLogAccessUsingOnlyResourcePermissions bool

@description('Optional. Disable local auth.')
param disableLocalAuth bool

@description('Optional. Public network access for ingestion.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccessForIngestion string

@description('Optional. Public network access for query.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccessForQuery string

var resourceAbbreviation = 'log'
var regionAbbreviation = regionAbbreviations[?location] ?? location
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var derivedName = take(
  '${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}-${instanceNumber}',
  63
)

resource workspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' = {
  name: derivedName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: enableLogAccessUsingOnlyResourcePermissions
      disableLocalAuth: disableLocalAuth
    }
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
  }
}

@description('The resource ID of the Log Analytics workspace.')
output resourceId string = workspace.id

@description('The name of the Log Analytics workspace.')
output name string = workspace.name
