metadata name = 'Private DNS Zones'
metadata description = 'This module deploys a Private DNS zone.'

import { virtualNetworkLinkType } from '../shared/shared.types.bicep'

@description('Required. Private DNS zone name.')
param name string

@description('Optional. Array of A records.')
param a aType[]?

@description('Optional. Array of AAAA records.')
param aaaa aaaaType[]?

@description('Optional. Array of CNAME records.')
param cname cnameType[]?

@description('Optional. Array of MX records.')
param mx mxType[]?

@description('Optional. Array of PTR records.')
param ptr ptrType[]?

@description('Optional. Array of SOA records.')
param soa soaType[]?

@description('Optional. Array of SRV records.')
param srv srvType[]?

@description('Optional. Array of TXT records.')
param txt txtType[]?

@description('Optional. Array of custom objects describing vNet links of the DNS zone. Each object should contain properties \'virtualNetworkResourceId\' and \'registrationEnabled\'. The \'vnetResourceId\' is a resource ID of a vNet to link, \'registrationEnabled\' (bool) enables automatic DNS registration in the zone for the linked vNet.')
param virtualNetworkLinks virtualNetworkLinkType[]?

@description('Optional. The location of the PrivateDNSZone. Should be global.')
param location string = 'global'

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
@sys.description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

@description('Optional. Tags of the resource.')
param tags object?

import { lockType } from '../shared/avm-common-types.bicep'
@sys.description('Optional. The lock settings of the service.')
param lock lockType?


var builtInRoleNames = {
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  'Network Contributor': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '4d97b98b-1d4f-4787-a291-c67834d212e7'
  )
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  'Private DNS Zone Contributor': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'b12aa53e-6015-4669-85d0-8515ebb3ae7f'
  )
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Role Based Access Control Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'f58310d9-a9f6-439a-9e8d-f62e7b41a168'
  )
}

var formattedRoleAssignments = [
  for (roleAssignment, index) in (roleAssignments ?? []): union(roleAssignment, {
    roleDefinitionId: builtInRoleNames[?roleAssignment.roleDefinitionIdOrName] ?? (contains(
        roleAssignment.roleDefinitionIdOrName,
        '/providers/Microsoft.Authorization/roleDefinitions/'
      )
      ? roleAssignment.roleDefinitionIdOrName
      : subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionIdOrName))
  })
]


resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  location: location
  tags: tags
}

module privateDnsZone_A './private-dns-zone-a-record.bicep' = [
  for (aRecord, index) in (a ?? []): {
    name: '${uniqueString(deployment().name, location)}-PrivateDnsZone-ARecord-${index}'
    params: {
      privateDnsZoneName: privateDnsZone.name
      name: aRecord.name
      aRecords: aRecord.?aRecords
      metadata: aRecord.?metadata
      ttl: aRecord.?ttl ?? 3600
      roleAssignments: aRecord.?roleAssignments    }
  }
]

module privateDnsZone_AAAA './private-dns-zone-aaaa-record.bicep' = [
  for (aaaaRecord, index) in (aaaa ?? []): {
    name: '${uniqueString(deployment().name, location)}-PrivateDnsZone-AAAARecord-${index}'
    params: {
      privateDnsZoneName: privateDnsZone.name
      name: aaaaRecord.name
      aaaaRecords: aaaaRecord.?aaaaRecords
      metadata: aaaaRecord.?metadata
      ttl: aaaaRecord.?ttl ?? 3600
      roleAssignments: aaaaRecord.?roleAssignments    }
  }
]

module privateDnsZone_CNAME './private-dns-zone-cname-record.bicep' = [
  for (cnameRecord, index) in (cname ?? []): {
    name: '${uniqueString(deployment().name, location)}-PrivateDnsZone-CNAMERecord-${index}'
    params: {
      privateDnsZoneName: privateDnsZone.name
      name: cnameRecord.name
      cnameRecord: cnameRecord.?cnameRecord
      metadata: cnameRecord.?metadata
      ttl: cnameRecord.?ttl ?? 3600
      roleAssignments: cnameRecord.?roleAssignments    }
  }
]

module privateDnsZone_MX './private-dns-zone-mx-record.bicep' = [
  for (mxRecord, index) in (mx ?? []): {
    name: '${uniqueString(deployment().name, location)}-PrivateDnsZone-MXRecord-${index}'
    params: {
      privateDnsZoneName: privateDnsZone.name
      name: mxRecord.name
      metadata: mxRecord.?metadata
      mxRecords: mxRecord.?mxRecords
      ttl: mxRecord.?ttl ?? 3600
      roleAssignments: mxRecord.?roleAssignments    }
  }
]

module privateDnsZone_PTR './private-dns-zone-ptr-record.bicep' = [
  for (ptrRecord, index) in (ptr ?? []): {
    name: '${uniqueString(deployment().name, location)}-PrivateDnsZone-PTRRecord-${index}'
    params: {
      privateDnsZoneName: privateDnsZone.name
      name: ptrRecord.name
      metadata: ptrRecord.?metadata
      ptrRecords: ptrRecord.?ptrRecords
      ttl: ptrRecord.?ttl ?? 3600
      roleAssignments: ptrRecord.?roleAssignments    }
  }
]

module privateDnsZone_SOA './private-dns-zone-soa-record.bicep' = [
  for (soaRecord, index) in (soa ?? []): {
    name: '${uniqueString(deployment().name, location)}-PrivateDnsZone-SOARecord-${index}'
    params: {
      privateDnsZoneName: privateDnsZone.name
      name: soaRecord.name
      metadata: soaRecord.?metadata
      soaRecord: soaRecord.?soaRecord
      ttl: soaRecord.?ttl ?? 3600
      roleAssignments: soaRecord.?roleAssignments    }
  }
]

module privateDnsZone_SRV './private-dns-zone-srv-record.bicep' = [
  for (srvRecord, index) in (srv ?? []): {
    name: '${uniqueString(deployment().name, location)}-PrivateDnsZone-SRVRecord-${index}'
    params: {
      privateDnsZoneName: privateDnsZone.name
      name: srvRecord.name
      metadata: srvRecord.?metadata
      srvRecords: srvRecord.?srvRecords
      ttl: srvRecord.?ttl ?? 3600
      roleAssignments: srvRecord.?roleAssignments    }
  }
]

module privateDnsZone_TXT './private-dns-zone-txt-record.bicep' = [
  for (txtRecord, index) in (txt ?? []): {
    name: '${uniqueString(deployment().name, location)}-PrivateDnsZone-TXTRecord-${index}'
    params: {
      privateDnsZoneName: privateDnsZone.name
      name: txtRecord.name
      metadata: txtRecord.?metadata
      txtRecords: txtRecord.?txtRecords
      ttl: txtRecord.?ttl ?? 3600
      roleAssignments: txtRecord.?roleAssignments    }
  }
]

var resolvedVirtualNetworkLinks = [
  for virtualNetworkLink in (virtualNetworkLinks ?? []): {
    name: virtualNetworkLink.name
    virtualNetworkResourceId: virtualNetworkLink.virtualNetworkResourceId
    registrationEnabled: virtualNetworkLink.registrationEnabled ?? false
    resolutionPolicy: virtualNetworkLink.?resolutionPolicy
  }
]

module privateDnsZone_virtualNetworkLinks './private-dns-zone-link.bicep' = [
  for (virtualNetworkLink, index) in resolvedVirtualNetworkLinks: {
    name: '${uniqueString(deployment().name, location)}-PrivateDnsZone-VNetLink-${index}'
    params: {
      privateDnsZoneName: privateDnsZone.name
      name: virtualNetworkLink.name
      virtualNetworkResourceId: virtualNetworkLink.virtualNetworkResourceId
      registrationEnabled: virtualNetworkLink.registrationEnabled
      resolutionPolicy: virtualNetworkLink.?resolutionPolicy
    }
  }
]

resource privateDnsZone_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${name}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?notes ?? (lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.')
  }
  scope: privateDnsZone
}

resource privateDnsZone_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(privateDnsZone.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: privateDnsZone
  }
]

@description('The resource group the private DNS zone was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The name of the private DNS zone.')
output name string = privateDnsZone.name

@description('The resource ID of the private DNS zone.')
output resourceId string = privateDnsZone.id

@description('The location the resource was deployed into.')
output location string = privateDnsZone.location

// ================ //
// Definitions      //
// ================ //

@export()
@description('The type for the A record.')
type aType = {
  @description('Required. The name of the record.')
  name: string

  @description('Optional. The metadata of the record.')
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/A@2024-06-01'>.properties.metadata?

  @description('Optional. The TTL of the record.')
  ttl: int?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType[]?

  @description('Optional. The list of A records in the record set.')
  aRecords: resourceInput<'Microsoft.Network/privateDnsZones/A@2024-06-01'>.properties.aRecords?
}

@export()
@description('The type for the AAAA record.')
type aaaaType = {
  @description('Required. The name of the record.')
  name: string

  @description('Optional. The metadata of the record.')
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/AAAA@2024-06-01'>.properties.metadata?

  @description('Optional. The TTL of the record.')
  ttl: int?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType[]?

  @description('Optional. The list of AAAA records in the record set.')
  aaaaRecords: resourceInput<'Microsoft.Network/privateDnsZones/AAAA@2024-06-01'>.properties.aaaaRecords?
}

@export()
@description('The type for the CNAME record.')
type cnameType = {
  @description('Required. The name of the record.')
  name: string

  @description('Optional. The metadata of the record.')
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/CNAME@2024-06-01'>.properties.metadata?

  @description('Optional. The TTL of the record.')
  ttl: int?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType[]?

  @description('Optional. The CNAME record in the record set.')
  cnameRecord: resourceInput<'Microsoft.Network/privateDnsZones/CNAME@2024-06-01'>.properties.cnameRecord?
}

@export()
@description('The type for the MX record.')
type mxType = {
  @description('Required. The name of the record.')
  name: string

  @description('Optional. The metadata of the record.')
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/MX@2024-06-01'>.properties.metadata?

  @description('Optional. The TTL of the record.')
  ttl: int?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType[]?

  @description('Optional. The list of MX records in the record set.')
  mxRecords: resourceInput<'Microsoft.Network/privateDnsZones/MX@2024-06-01'>.properties.mxRecords?
}

@export()
@description('The type for the PTR record.')
type ptrType = {
  @description('Required. The name of the record.')
  name: string

  @description('Optional. The metadata of the record.')
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/PTR@2024-06-01'>.properties.metadata?

  @description('Optional. The TTL of the record.')
  ttl: int?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType[]?

  @description('Optional. The list of PTR records in the record set.')
  ptrRecords: resourceInput<'Microsoft.Network/privateDnsZones/PTR@2024-06-01'>.properties.ptrRecords?
}

@export()
@description('The type for the SOA record.')
type soaType = {
  @description('Required. The name of the record.')
  name: string

  @description('Optional. The metadata of the record.')
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/SOA@2024-06-01'>.properties.metadata?

  @description('Optional. The TTL of the record.')
  ttl: int?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType[]?

  @description('Optional. The SOA record in the record set.')
  soaRecord: resourceInput<'Microsoft.Network/privateDnsZones/SOA@2024-06-01'>.properties.soaRecord?
}

@export()
@description('The type for the SRV record.')
type srvType = {
  @description('Required. The name of the record.')
  name: string

  @description('Optional. The metadata of the record.')
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/SRV@2024-06-01'>.properties.metadata?

  @description('Optional. The TTL of the record.')
  ttl: int?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType[]?

  @description('Optional. The list of SRV records in the record set.')
  srvRecords: resourceInput<'Microsoft.Network/privateDnsZones/SRV@2024-06-01'>.properties.srvRecords?
}

@export()
@description('The type for the TXT record.')
type txtType = {
  @description('Required. The name of the record.')
  name: string

  @description('Optional. The metadata of the record.')
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/TXT@2024-06-01'>.properties.metadata?

  @description('Optional. The TTL of the record.')
  ttl: int?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType[]?

  @description('Optional. The list of TXT records in the record set.')
  txtRecords: resourceInput<'Microsoft.Network/privateDnsZones/TXT@2024-06-01'>.properties.txtRecords?
}
