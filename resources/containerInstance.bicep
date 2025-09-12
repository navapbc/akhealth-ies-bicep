var containerGroupsName string = 'aci-project-dev-web-001'
var region string = 'eastus'
var sku = 'Standard'
var containerImageName = 'mcr.microsoft.com/azuredocs/aci-helloworld:latest'
var containerImageMemoryInGB = 2
var containerImageCPU = 1
var restartPolicy = 'OnFailutre'
var osType = 'Linux'


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
