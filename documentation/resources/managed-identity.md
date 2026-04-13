# Managed Identity

- **Resource provider**: `Microsoft.ManagedIdentity`

## Region considerations

- Region selection matters because user-assigned managed identities are regional resources, while system-assigned identities are tied to the lifecycle of the resource that hosts them. West US 2 is the likely primary region, and West Central US needs equivalent identity planning for DR-hosted workloads.
- Availability zones are not a direct managed identity feature consideration.
- Paired-region and DR considerations are important because regional workload duplication often requires role assignments and identity references to be recreated or deliberately mirrored.
- Service-by-service regional validation is required where services have differing support for managed identity, token acquisition patterns, or cross-region access assumptions.
- Feature parity should not be assumed between West US 2 and West Central US for every dependent service that consumes managed identity.

## Purpose in the IEP

Managed Identity provides Azure-native workload identity so applications and automation can authenticate to Azure services without storing long-lived credentials.

## Key design considerations

- Decide where system-assigned identities are sufficient and where user-assigned identities improve reuse or lifecycle control.
- Standardize role assignment patterns so access is understandable and reviewable.
- Plan how identities and role bindings will be recreated or mirrored in West Central US DR resources.
- Ensure applications use managed identity consistently for Key Vault, Storage, Service Bus, and other dependencies.
- Avoid creating overly broad shared identities that weaken ownership boundaries.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Key Vault
- App Service / Web App / API App
- Azure Functions / Function App
- Azure Container Registry
- Service Bus
- Azure Automation / Runbooks

## Open questions

- Which workloads should use system-assigned identities versus user-assigned identities?
- What role standards will be used for common access patterns such as vault read or queue send?
- How will identity and role assignment parity be maintained across regions?
- Which services in scope still require exceptions or supplemental credentials?
- Who owns lifecycle cleanup for unused identities and stale role bindings?

## Relevant links

- [Microsoft Learn: Managed identities for Azure resources](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview-for-developers)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- Managed identity is one of the strongest enablers for making the private-first platform also credential-minimizing by design.
