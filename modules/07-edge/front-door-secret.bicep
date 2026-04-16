metadata name = 'CDN Profiles Secret'
metadata description = 'This module deploys a CDN Profile Secret.'
param name string
param profileName string
@allowed([
  'AzureFirstPartyManagedCertificate'
  'CustomerCertificate'
  'ManagedCertificate'
  'UrlSigningKey'
])
param type string

#disable-next-line secure-secrets-in-params
param secretSourceResourceId string?
param secretVersion string?
param subjectAlternativeNames string[]?
param useLatestVersion bool?
var resolvedSecretSourceResourceId = type == 'CustomerCertificate'
  ? (secretSourceResourceId != null
      ? secretSourceResourceId
      : fail('Front Door CustomerCertificate secrets require secretSourceResourceId to be declared explicitly.'))
  : null

resource profile 'Microsoft.Cdn/profiles@2025-06-01' existing = {
  name: profileName
}

resource secret 'Microsoft.Cdn/profiles/secrets@2025-06-01' = {
  name: name
  parent: profile
  properties: {
    // False positive
    #disable-next-line BCP225
    parameters: (type == 'CustomerCertificate')
      ? {
          type: type
          secretSource: {
            id: resolvedSecretSourceResourceId
          }
          secretVersion: secretVersion
          subjectAlternativeNames: subjectAlternativeNames ?? []
          useLatestVersion: useLatestVersion
        }
      : null
  }
}
output name string = secret.name
output resourceId string = secret.id
output resourceGroupName string = resourceGroup().name
