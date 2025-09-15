param environment string
param instanceNumber string
param workloadDescriptor string
param region string
param regionAbbreviation string
param sku string
param containerImageName string
param containerImageMemoryInGB int
param containerImageCPU int
param restartPolicy  string
param osType string
param systemName string

var containerGroupsName = 'aci-${systemName}-${environment}-${workloadDescriptor}-${regionAbbreviation}-${instanceNumber}'


resource containerGroupsResource 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerGroupsName
  location: region
  properties: {
    sku: sku
    containers: [
      {
        name: containerGroupsName
        properties: {
          image: containerImageName
          ports: []
          environmentVariables: []
          resources: {
            requests: {
              memoryInGB: containerImageMemoryInGB
              cpu: containerImageCPU
            }
          }
        }
      }
    ]
    initContainers: []
    restartPolicy: restartPolicy
    osType: osType
  }
}
