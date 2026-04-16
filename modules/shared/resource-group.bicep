metadata name = 'Resource Groups'
metadata description = 'This module deploys a Resource Group.'

targetScope = 'subscription'

import { regionAbbreviations } from './region-abbreviations.bicep'

@description('Required. System abbreviation used for resource naming.')
param systemAbbreviation string

@description('Required. Environment abbreviation used for resource naming.')
param environmentAbbreviation string

@description('Required. Instance number used for resource naming.')
param instanceNumber string

@description('Optional. Workload description segment used for resource naming.')
param workloadDescription string = ''

@description('Optional. Sub-workload description segment used for resource naming.')
param subWorkloadDescription string = ''

@description('Optional. Location of the Resource Group. It uses the deployment\'s location when not provided.')
param location string = deployment().location

import { lockType } from './avm-common-types.bicep'
param lock lockType?

import { roleAssignmentType } from './avm-common-types.bicep'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

@description('Optional. Tags of the storage account resource.')
param tags resourceInput<'Microsoft.Resources/resourceGroups@2025-04-01'>.tags?

var regionAbbreviation = regionAbbreviations[location]
var workloadSegment = empty(workloadDescription) ? '' : '-${workloadDescription}'
var subWorkloadSegment = empty(subWorkloadDescription) ? '' : '-${subWorkloadDescription}'
var name = take('rg-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}${workloadSegment}${subWorkloadSegment}-${instanceNumber}', 90)

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  location: location
  name: name
  tags: tags
  // managedBy: managedBy // removed due to immutable string, only used for managed resource groups
  properties: {}
}

module resourceGroup_lock './resource-group-lock.bicep' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: '${uniqueString(subscription().id, location)}-RG-Lock'
  params: {
    lock: lock!
    name: resourceGroup.name
  }
  scope: resourceGroup
}

module resourceGroup_roleAssignments './resource-group-role-assignments.bicep' = if (!empty(roleAssignments ?? [])) {
  name: '${uniqueString(subscription().id, location)}-RG-RoleAssignments'
  params: {
    roleAssignments: roleAssignments
  }
  scope: resourceGroup
}

output name string = resourceGroup.name

output resourceId string = resourceGroup.id

output location string = resourceGroup.location
