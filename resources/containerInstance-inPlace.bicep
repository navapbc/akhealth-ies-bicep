



param containerGroups_cg_v1mu_workspaceKey string
param containerGroups_cg_v1mu_name string = 'cg-v1mu'
param virtualNetworks_vnet_v1mu_externalid string = '/subscriptions/dec9c331-d773-4f77-a5a8-39e95699c4a5/resourceGroups/rg-v1mu/providers/Microsoft.Network/virtualNetworks/vnet-v1mu'

resource containerGroups_cg_v1mu_name_resource 'Microsoft.ContainerInstance/containerGroups@2024-11-01-preview' = {
  name: containerGroups_cg_v1mu_name
  location: 'eastus'
  tags: {}
  zones: [
    '1'
  ]
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/dec9c331-d773-4f77-a5a8-39e95699c4a5/resourceGroups/rg-v1mu/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-v1mu': {}
    }
  }
  properties: {
    sku: 'Standard'
    containers: [
      {
        name: 'container1'
        properties: {
          image: 'nginx:latest'
          command: []
          ports: [
            {
              protocol: 'TCP'
              port: 80
            }
          ]
          environmentVariables: [
            {
              name: 'ENVIRONMENT'
              value: 'dev'
            }
            {
              name: 'SECENV'
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('2')
              cpu: json('1')
            }
          }
          volumeMounts: [
            {
              name: 'nginx'
              mountPath: '/usr/share/nginx/html'
              readOnly: false
            }
            {
              name: 'secrets'
              mountPath: '/etc/secrets'
              readOnly: false
            }
          ]
        }
      }
    ]
    initContainers: []
    restartPolicy: 'Always'
    ipAddress: {
      ports: [
        {
          protocol: 'TCP'
          port: 80
        }
      ]
      ip: '192.168.0.4'
      type: 'Private'
    }
    osType: 'Linux'
    volumes: [
      {
        name: 'nginx'
        secret: {}
      }
      {
        name: 'secrets'
        secret: {}
      }
    ]
    diagnostics: {
      logAnalytics: {
        workspaceId: 'd4e68683-6a8d-423b-a3a4-a1090845fe0e'
        workspaceKey: containerGroups_cg_v1mu_workspaceKey
      }
    }
    subnetIds: [
      {
        id: '${virtualNetworks_vnet_v1mu_externalid}/subnets/snet-v1mu'
      }
    ]
    priority: 'Regular'
  }
}
