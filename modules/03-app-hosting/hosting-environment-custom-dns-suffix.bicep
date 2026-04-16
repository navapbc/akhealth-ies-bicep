metadata name = 'Hosting Environment Custom DNS Suffix Configuration'
metadata description = 'This module deploys a Hosting Environment Custom DNS Suffix Configuration.'
param hostingEnvironmentName string
param dnsSuffix string
param certificateUrl string

resource appServiceEnvironment 'Microsoft.Web/hostingEnvironments@2025-03-01' existing = {
  name: hostingEnvironmentName
}

resource configuration 'Microsoft.Web/hostingEnvironments/configurations@2025-03-01' = {
  name: 'customdnssuffix'
  parent: appServiceEnvironment
  properties: {
    certificateUrl: certificateUrl
    // Microsoft documents the literal "systemassigned" for ASE custom DNS suffix Key Vault references.
    // https://learn.microsoft.com/en-us/azure/app-service/environment/how-to-custom-domain-suffix
    keyVaultReferenceIdentity: 'systemassigned'
    dnsSuffix: dnsSuffix
  }
}
output name string = configuration.name
output resourceId string = configuration.id
output resourceGroupName string = resourceGroup().name
