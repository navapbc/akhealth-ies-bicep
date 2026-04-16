targetScope = 'resourceGroup'

metadata name = 'PostgreSQL Flexible Server'
metadata description = 'This module deploys Azure Database for PostgreSQL Flexible Server.'

import { regionAbbreviations } from '../shared/region-abbreviations.bicep'
import { virtualNetworkLinkType } from '../shared/shared.types.bicep'
import {
  diagnosticSettingFullType
  lockType
  roleAssignmentType
} from '../shared/avm-common-types.bicep'
import {
  configurationType
  databaseType
} from './postgresql-flexible-server-server.bicep'

param systemAbbreviation string
param environmentAbbreviation string
param instanceNumber string
param workloadDescription string
param location string
param administratorGroupObjectId string
param administratorGroupDisplayName string
param skuName string
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param tier string
@allowed([
  -1
  1
  2
  3
])
param availabilityZone int
@allowed([
  -1
  1
  2
  3
])
param highAvailabilityZone int
@allowed([
  'Disabled'
  'SameZone'
  'ZoneRedundant'
])
param highAvailability string
param backupRetentionDays int
@allowed([
  'Disabled'
  'Enabled'
])
param geoRedundantBackup string
param storageSizeGB int
@allowed([
  'Disabled'
  'Enabled'
])
param autoGrow string
@allowed([
  '11'
  '12'
  '13'
  '14'
  '15'
  '16'
  '17'
  '18'
])
param version string
@allowed([
  'Disabled'
  'Enabled'
])
param publicNetworkAccess string
@allowed([
  'delegatedSubnet'
  'none'
])
param privateAccessMode string
param deployPrivateNetworking bool
param delegatedSubnetResourceId string?
param privateDnsZoneVirtualNetworkLinks virtualNetworkLinkType[]
param privateDnsZoneResourceGroupName string?
param databases databaseType[]
param configurations configurationType[]
param lock lockType?
param roleAssignments roleAssignmentType[] = []
param diagnosticSettings diagnosticSettingFullType[] = []
param tags object
var resourceAbbreviation = 'psqlfx'
var regionAbbreviation = regionAbbreviations[location]
var derivedName = take('${resourceAbbreviation}-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${workloadDescription}-${instanceNumber}', 63)
var privateAccessEnabled = privateAccessMode == 'delegatedSubnet'
var privateModeRequested = privateAccessMode == 'delegatedSubnet' && publicNetworkAccess == 'Disabled'
var publicModeRequested = privateAccessMode == 'none' && publicNetworkAccess == 'Enabled'
var networkingModeIsValid = deployPrivateNetworking
  ? (privateModeRequested
      ? true
      : fail('When deployPrivateNetworking is true, PostgreSQL must use delegatedSubnet private access and Disabled public network access.'))
  : (publicModeRequested
      ? true
      : fail('When deployPrivateNetworking is false, PostgreSQL must use none private access mode and Enabled public network access.'))
var privateAccessInputsAreValid = privateAccessEnabled
  ? (delegatedSubnetResourceId != null
      ? (!empty(privateDnsZoneVirtualNetworkLinks)
          ? true
          : fail('PostgreSQL private access requires privateDnsZoneVirtualNetworkLinks to be declared explicitly.'))
      : fail('PostgreSQL private access requires delegatedSubnetResourceId when privateAccessMode is delegatedSubnet.'))
  : (delegatedSubnetResourceId == null
      ? true
      : fail('PostgreSQL public access must not provide delegatedSubnetResourceId when privateAccessMode is none.'))
var privateDnsZoneLabel = take('pdz-${systemAbbreviation}-${regionAbbreviation}-${environmentAbbreviation}-${workloadDescription}-${instanceNumber}', 63)
// Azure recommends private DNS zones that end with .postgres.database.azure.com for Flexible Server private access.
// Ref: https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-networking-private
var derivedPrivateDnsZoneName = '${privateDnsZoneLabel}.postgres.database.azure.com'
var resolvedPrivateDnsZoneResourceGroupName = privateDnsZoneResourceGroupName ?? resourceGroup().name

module postgreSqlPrivateDnsZone '../01-network/private-dns-zone.bicep' = if (networkingModeIsValid && privateAccessInputsAreValid && privateAccessEnabled) {
  name: '${uniqueString(deployment().name, location)}-postgresql-dnszone'
  scope: resourceGroup(resolvedPrivateDnsZoneResourceGroupName)
  params: {
    name: derivedPrivateDnsZoneName
    location: 'global'
    virtualNetworkLinks: privateDnsZoneVirtualNetworkLinks
    tags: tags
  }
}

module flexibleServerPrivate './postgresql-flexible-server-server.bicep' = if (networkingModeIsValid && privateAccessInputsAreValid && privateAccessEnabled) {
  name: '${uniqueString(deployment().name, location)}-postgresql-private'
  params: {
    name: derivedName
    location: location
    skuName: skuName
    tier: tier
    availabilityZone: availabilityZone
    highAvailabilityZone: highAvailabilityZone
    highAvailability: highAvailability
    backupRetentionDays: backupRetentionDays
    geoRedundantBackup: geoRedundantBackup
    storageSizeGB: storageSizeGB
    autoGrow: autoGrow
    version: version
    publicNetworkAccess: publicNetworkAccess
    delegatedSubnetResourceId: delegatedSubnetResourceId!
    privateDnsZoneArmResourceId: postgreSqlPrivateDnsZone!.outputs.resourceId
    administrators: [
      {
        objectId: administratorGroupObjectId
        principalName: administratorGroupDisplayName
        principalType: 'Group'
        tenantId: tenant().tenantId
      }
    ]
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Disabled'
      tenantId:tenant().tenantId
    }
    databases: databases
    configurations: configurations
    roleAssignments: roleAssignments
    diagnosticSettings: diagnosticSettings
    lock: lock
    tags: tags
  }
}

module flexibleServerPublic './postgresql-flexible-server-server.bicep' = if (networkingModeIsValid && privateAccessInputsAreValid && !privateAccessEnabled) {
  name: '${uniqueString(deployment().name, location)}-postgresql-public'
  params: {
    name: derivedName
    location: location
    skuName: skuName
    tier: tier
    availabilityZone: availabilityZone
    highAvailabilityZone: highAvailabilityZone
    highAvailability: highAvailability
    backupRetentionDays: backupRetentionDays
    geoRedundantBackup: geoRedundantBackup
    storageSizeGB: storageSizeGB
    autoGrow: autoGrow
    version: version
    publicNetworkAccess: publicNetworkAccess
    administrators: [
      {
        objectId: administratorGroupObjectId
        principalName: administratorGroupDisplayName
        principalType: 'Group'
        tenantId: tenant().tenantId
      }
    ]
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Disabled'
    }
    databases: databases
    configurations: configurations
    roleAssignments: roleAssignments
    diagnosticSettings: diagnosticSettings
    lock: lock
    tags: tags
  }
}
output name string = privateAccessEnabled ? flexibleServerPrivate.?outputs.?name! : flexibleServerPublic.?outputs.?name!
output resourceId string = privateAccessEnabled ? flexibleServerPrivate.?outputs.?resourceId! : flexibleServerPublic.?outputs.?resourceId!
output resourceGroupName string = privateAccessEnabled ? flexibleServerPrivate.?outputs.?resourceGroupName! : flexibleServerPublic.?outputs.?resourceGroupName!
output serverLocation string = privateAccessEnabled ? flexibleServerPrivate.?outputs.?location! : flexibleServerPublic.?outputs.?location!
output fqdn string = privateAccessEnabled ? flexibleServerPrivate.?outputs.?fqdn! : flexibleServerPublic.?outputs.?fqdn!
output privateDnsZoneName string? = privateAccessEnabled ? derivedPrivateDnsZoneName : null
output privateDnsZoneResourceId string? = privateAccessEnabled ? postgreSqlPrivateDnsZone.?outputs.?resourceId : null
