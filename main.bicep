var environment = 'dev'
var systemName = 'sys'
var workLoadDescriptor = 'web'
var region string = 'eastus'
var regionAbbreviation string = 'eus'
var sku = 'Standard'
var containerImageName = 'mcr.microsoft.com/azuredocs/aci-helloworld:latest'
var containerImageMemoryInGB = 2
var containerImageCPU = 1
var restartPolicy = 'OnFailure'
var osType = 'Linux'

resource defaultVnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: 'vnet-vdi1'
  location: 'eastus'
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/21'
      ]
    }
    privateEndpointVNetPolicies: 'Disabled'
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource pgsqlDelegatedSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  parent: defaultVnet
  name: 'snet-n1cy'
  properties: {
    addressPrefix: '10.0.1.0/25'
    delegations: [
      {
        name: 'delegation'
        id: '${defaultVnet.id}/delegations/delegation'
        properties: {
          serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
      }
    ]
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
}

/* resource pgsqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'private.postgres.database.azure.com'
  location: 'global'
} */

resource containerinstanceSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  parent: defaultVnet
  name: 'snet-vdi1'
  properties: {
    addressPrefix: '10.0.0.128/25'
    serviceEndpoints: []
    delegations: [
      {
        name: 'delegation'
        id: '${defaultVnet.id}/delegations/delegation'
        properties: {
          serviceName: 'Microsoft.ContainerInstance/containerGroups'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
      }
    ]
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: true
  }
}

resource postgreSqlFlexibleServer 'Microsoft.DBforPostgreSQL/flexibleServers@2025-06-01-preview' = {
  location: 'string'
  name: 'string'
  properties: {
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Disabled'
      tenantId: 'ba06645f-e0cc-44b5-897f-34eb6aa59588'
    }
    availabilityZone: '1'
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    dataEncryption: {
      type: 'SystemManaged'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    maintenanceWindow: {
      customWindow: 'Disabled'
      dayOfWeek: 0
      startHour: 0
      startMinute: 0
    }

    network: {
      delegatedSubnetResourceId: pgsqlDelegatedSubnet.id
      privateDnsZoneArmResourceId: 
      publicNetworkAccess: 'string'
    }

    pointInTimeUTC: 'string'
    replica: {
      promoteMode: 'string'
      promoteOption: 'string'
      role: 'string'
    }
    replicationRole: 'string'
    sourceServerResourceId: 'string'
    storage: {
      autoGrow: 'string'
      iops: int
      storageSizeGB: int
      throughput: int
      tier: 'string'
      type: 'string'
    }
    version: 'string'
  }
  sku: {
    name: 'string'
    tier: 'string'
  }
  tags: {
    {customized property}: 'string'
  }
}

module containerInstance 'resources/containerInstance.bicep' = {
  name: 'containerInstance'
  params: {
    environment: environment
    instanceNumber: '001'
    systemName: systemName
    workloadDescriptor: workLoadDescriptor
    region: region
    regionAbbreviation: regionAbbreviation
    sku: sku
    containerImageName: containerImageName
    containerImageMemoryInGB: containerImageMemoryInGB
    containerImageCPU: containerImageCPU
    restartPolicy: restartPolicy
    osType: osType
  }
}
