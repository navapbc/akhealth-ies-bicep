metadata name = 'Private DNS Zones'
metadata description = 'This module deploys a Private DNS zone.'

import { builtInRoleNames } from '../shared/role-definitions.bicep'
import { virtualNetworkLinkType } from '../shared/shared.types.bicep'

param name string
param a aType[]?
param aaaa aaaaType[]?
param cname cnameType[]?
param mx mxType[]?
param ptr ptrType[]?
param soa soaType[]?
param srv srvType[]?
param txt txtType[]?
param virtualNetworkLinks virtualNetworkLinkType[]?
param location string = 'global'

import { roleAssignmentType } from '../shared/avm-common-types.bicep'
@sys.description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?
param tags object?

import { lockType } from '../shared/avm-common-types.bicep'
@sys.description('Optional. The lock settings of the service.')
param lock lockType?
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

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
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
output resourceGroupName string = resourceGroup().name
output name string = privateDnsZone.name
output resourceId string = privateDnsZone.id
output location string = privateDnsZone.location

// ================ //
// Definitions      //
// ================ //

@export()
type aType = {
  name: string
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/A@2024-06-01'>.properties.metadata?
  ttl: int?
  roleAssignments: roleAssignmentType[]?
  aRecords: resourceInput<'Microsoft.Network/privateDnsZones/A@2024-06-01'>.properties.aRecords?
}

@export()
type aaaaType = {
  name: string
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/AAAA@2024-06-01'>.properties.metadata?
  ttl: int?
  roleAssignments: roleAssignmentType[]?
  aaaaRecords: resourceInput<'Microsoft.Network/privateDnsZones/AAAA@2024-06-01'>.properties.aaaaRecords?
}

@export()
type cnameType = {
  name: string
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/CNAME@2024-06-01'>.properties.metadata?
  ttl: int?
  roleAssignments: roleAssignmentType[]?
  cnameRecord: resourceInput<'Microsoft.Network/privateDnsZones/CNAME@2024-06-01'>.properties.cnameRecord?
}

@export()
type mxType = {
  name: string
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/MX@2024-06-01'>.properties.metadata?
  ttl: int?
  roleAssignments: roleAssignmentType[]?
  mxRecords: resourceInput<'Microsoft.Network/privateDnsZones/MX@2024-06-01'>.properties.mxRecords?
}

@export()
type ptrType = {
  name: string
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/PTR@2024-06-01'>.properties.metadata?
  ttl: int?
  roleAssignments: roleAssignmentType[]?
  ptrRecords: resourceInput<'Microsoft.Network/privateDnsZones/PTR@2024-06-01'>.properties.ptrRecords?
}

@export()
type soaType = {
  name: string
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/SOA@2024-06-01'>.properties.metadata?
  ttl: int?
  roleAssignments: roleAssignmentType[]?
  soaRecord: resourceInput<'Microsoft.Network/privateDnsZones/SOA@2024-06-01'>.properties.soaRecord?
}

@export()
type srvType = {
  name: string
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/SRV@2024-06-01'>.properties.metadata?
  ttl: int?
  roleAssignments: roleAssignmentType[]?
  srvRecords: resourceInput<'Microsoft.Network/privateDnsZones/SRV@2024-06-01'>.properties.srvRecords?
}

@export()
type txtType = {
  name: string
  metadata: resourceInput<'Microsoft.Network/privateDnsZones/TXT@2024-06-01'>.properties.metadata?
  ttl: int?
  roleAssignments: roleAssignmentType[]?
  txtRecords: resourceInput<'Microsoft.Network/privateDnsZones/TXT@2024-06-01'>.properties.txtRecords?
}

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
