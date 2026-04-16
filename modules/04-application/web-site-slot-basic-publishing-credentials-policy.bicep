metadata name = 'Web Site Slot Basic Publishing Credentials Policies'
metadata description = 'This module deploys a Web Site Slot Basic Publishing Credentials Policy.'
@allowed([
  'scm'
  'ftp'
])
param name string
param allow bool = true
param appName string
param slotName string
param location string = resourceGroup().location

resource app 'Microsoft.Web/sites@2025-03-01' existing = {
  name: appName

  resource slot 'slots' existing = {
    name: slotName
  }
}

resource basicPublishingCredentialsPolicy 'Microsoft.Web/sites/slots/basicPublishingCredentialsPolicies@2025-03-01' = {
  #disable-next-line BCP225 // False-positive. Value is required.
  name: name
  location: location
  parent: app::slot
  properties: {
    allow: allow
  }
}
output name string = basicPublishingCredentialsPolicy.name
output resourceId string = basicPublishingCredentialsPolicy.id
output resourceGroupName string = resourceGroup().name
output location string = basicPublishingCredentialsPolicy.location
