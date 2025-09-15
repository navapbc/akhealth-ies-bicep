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



module containerInstance 'resources/containerInstance.bicep' = {
  name: 'containerInstance'
  params:{ 
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
