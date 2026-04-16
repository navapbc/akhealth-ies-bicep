metadata name = 'Web Site Basic Publishing Credentials Policies'
metadata description = 'This module deploys a Web Site Basic Publishing Credentials Policy.'
@allowed([
  'scm'
  'ftp'
])
param name string
param allow bool = true
param webAppName string
param location string = resourceGroup().location

resource webApp 'Microsoft.Web/sites@2025-03-01' existing = {
  name: webAppName
}

resource basicPublishingCredentialsPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2025-03-01' = {
  #disable-next-line BCP225 // False-positive. Value is required.
  name: name
  location: location
  parent: webApp
  properties: {
    allow: allow
  }
}
output name string = basicPublishingCredentialsPolicy.name
output resourceId string = basicPublishingCredentialsPolicy.id
output resourceGroupName string = resourceGroup().name
output location string = basicPublishingCredentialsPolicy.location
