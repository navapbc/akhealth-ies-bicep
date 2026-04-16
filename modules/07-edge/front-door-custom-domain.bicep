metadata name = 'CDN Profiles Custom Domains'
metadata description = 'This module deploys a CDN Profile Custom Domains.'
param name string
param profileName string
param hostName string
param azureDnsZoneResourceId string?
param extendedProperties resourceInput<'Microsoft.Cdn/profiles/customDomains@2025-06-01'>.properties.extendedProperties?
param preValidatedCustomDomainResourceId string?
@allowed([
  'AzureFirstPartyManagedCertificate'
  'CustomerCertificate'
  'ManagedCertificate'
])
param certificateType string
@allowed([
  'TLS10'
  'TLS12'
  'TLS13'
])
param minimumTlsVersion string?
param secretName string?
param cipherSuiteSetType string?
param customizedCipherSuiteSet resourceInput<'Microsoft.Cdn/profiles/customDomains@2025-06-01'>.properties.tlsSettings.customizedCipherSuiteSet?
var resolvedSecretName = certificateType == 'CustomerCertificate'
  ? (secretName != null
      ? secretName
      : fail('Front Door custom domains using CustomerCertificate require secretName to be declared explicitly.'))
  : secretName

resource profile 'Microsoft.Cdn/profiles@2025-06-01' existing = {
  name: profileName

  resource secret 'secrets@2025-06-01' existing = if (resolvedSecretName != null) {
    name: resolvedSecretName!
  }
}

resource customDomain 'Microsoft.Cdn/profiles/customDomains@2025-06-01' = {
  name: name
  parent: profile
  properties: {
    azureDnsZone: azureDnsZoneResourceId != null
      ? {
          id: azureDnsZoneResourceId
        }
      : null
    extendedProperties: extendedProperties
    hostName: hostName
    preValidatedCustomDomainResourceId: preValidatedCustomDomainResourceId != null
      ? {
          id: preValidatedCustomDomainResourceId
        }
      : null
    tlsSettings: {
      certificateType: certificateType
      cipherSuiteSetType: cipherSuiteSetType
      customizedCipherSuiteSet: customizedCipherSuiteSet
      minimumTlsVersion: minimumTlsVersion
      secret: resolvedSecretName != null
        ? {
            id: profile::secret.id
          }
        : null
    }
  }
}
output name string = customDomain.name
output resourceId string = customDomain.id
output resourceGroupName string = resourceGroup().name
output dnsValidation dnsValidationOutputType = {
  dnsTxtRecordName: !empty(customDomain.properties.validationProperties)
    ? '_dnsauth.${customDomain.properties.hostName}'
    : null
  dnsTxtRecordValue: customDomain.properties.?validationProperties.?validationToken
  dnsTxtRecordExpiry: customDomain.properties.?validationProperties.?expirationDate
}

// =============== //
//   Definitions   //
// =============== //

@export()
type dnsValidationOutputType = {
  dnsTxtRecordName: string?
  dnsTxtRecordValue: string?
  dnsTxtRecordExpiry: string?
}
