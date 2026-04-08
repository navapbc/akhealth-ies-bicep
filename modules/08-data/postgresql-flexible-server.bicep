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

@description('Required. Abbreviation for the owning system.')
param systemAbbreviation string

@description('Required. Abbreviation for the lifecycle environment.')
param environmentAbbreviation string

@description('Required. Instance number used for deterministic naming.')
param instanceNumber string

@description('Required. Workload descriptor used to derive the PostgreSQL server name.')
param workloadDescription string

@description('Required. Location for all resources.')
param location string

@description('Required. Object ID of the Microsoft Entra group that will administer the PostgreSQL server.')
param administratorGroupObjectId string

@description('Required. Display name of the Microsoft Entra group that will administer the PostgreSQL server.')
param administratorGroupDisplayName string

@description('Required. The SKU name for the PostgreSQL flexible server.')
param skuName string

@description('Required. The pricing tier for the PostgreSQL flexible server.')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param tier string

@description('Required. Availability zone. Use -1 when no explicit zone is intended.')
@allowed([
  -1
  1
  2
  3
])
param availabilityZone int

@description('Required. Standby availability zone. Use -1 when no explicit zone is intended.')
@allowed([
  -1
  1
  2
  3
])
param highAvailabilityZone int

@description('Required. High availability mode.')
@allowed([
  'Disabled'
  'SameZone'
  'ZoneRedundant'
])
param highAvailability string

@description('Required. Backup retention days for the server.')
param backupRetentionDays int

@description('Required. Whether geo-redundant backup is enabled.')
@allowed([
  'Disabled'
  'Enabled'
])
param geoRedundantBackup string

@description('Required. Maximum storage size in GB.')
param storageSizeGB int

@description('Required. Storage autogrow setting.')
@allowed([
  'Disabled'
  'Enabled'
])
param autoGrow string

@description('Required. PostgreSQL engine version.')
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

@description('Required. Public network access setting for the server.')
@allowed([
  'Disabled'
  'Enabled'
])
param publicNetworkAccess string

@description('Required. Private networking mode for PostgreSQL.')
@allowed([
  'delegatedSubnet'
  'none'
])
param privateAccessMode string

@description('Required. Top-level deployment flag that determines whether PostgreSQL should use private networking for this workload.')
param deployPrivateNetworking bool

@description('Conditional. Delegated subnet resource ID used for PostgreSQL private access. Pass null when privateAccessMode is none.')
param delegatedSubnetResourceId string?

@description('Required. Virtual network links for the module-owned PostgreSQL private DNS zone.')
param privateDnsZoneVirtualNetworkLinks virtualNetworkLinkType[]

@description('Required. Databases to create on the server.')
param databases databaseType[]

@description('Required. Server configurations to apply.')
param configurations configurationType[]

@description('Optional. Resource lock for the server.')
param lock lockType?

@description('Required. Role assignments for the server.')
param roleAssignments roleAssignmentType[] = []

@description('Required. Diagnostic settings for the server.')
param diagnosticSettings diagnosticSettingFullType[] = []

@description('Required. Tags for the server and companion resources.')
param tags object

var resourceAbbreviation = 'psqlfx'
var regionAbbreviation = regionAbbreviations[?location] ?? location
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

module postgreSqlPrivateDnsZone '../01-network/private-dns-zone.bicep' = if (networkingModeIsValid && privateAccessInputsAreValid && privateAccessEnabled) {
    name: '${uniqueString(deployment().name, location)}-postgresql-dnszone'
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

@description('The name of the PostgreSQL flexible server.')
output name string = privateAccessEnabled ? flexibleServerPrivate.?outputs.?name! : flexibleServerPublic.?outputs.?name!

@description('The resource ID of the PostgreSQL flexible server.')
output resourceId string = privateAccessEnabled ? flexibleServerPrivate.?outputs.?resourceId! : flexibleServerPublic.?outputs.?resourceId!

@description('The resource group the PostgreSQL flexible server was deployed into.')
output resourceGroupName string = privateAccessEnabled ? flexibleServerPrivate.?outputs.?resourceGroupName! : flexibleServerPublic.?outputs.?resourceGroupName!

@description('The location of the PostgreSQL flexible server.')
output serverLocation string = privateAccessEnabled ? flexibleServerPrivate.?outputs.?location! : flexibleServerPublic.?outputs.?location!

@description('The fully qualified domain name of the PostgreSQL flexible server.')
output fqdn string = privateAccessEnabled ? flexibleServerPrivate.?outputs.?fqdn! : flexibleServerPublic.?outputs.?fqdn!

@description('The module-owned PostgreSQL private DNS zone name. Null when private access is not enabled.')
output privateDnsZoneName string? = privateAccessEnabled ? derivedPrivateDnsZoneName : null

@description('The resource ID of the module-owned PostgreSQL private DNS zone. Null when private access is not enabled.')
output privateDnsZoneResourceId string? = privateAccessEnabled ? postgreSqlPrivateDnsZone.?outputs.?resourceId : null
