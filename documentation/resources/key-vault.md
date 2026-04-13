# Key Vault

- **Resource provider**: `Microsoft.KeyVault`

## Region considerations

- Region selection matters strongly because Key Vault is a regional dependency for secrets, keys, and certificates. West US 2 is the likely primary vault region, and West Central US should be planned explicitly if secondary-region workloads need local or independent secret access.
- Availability zones are not usually the primary design concern for standard vault planning, but service resiliency in-region still matters.
- Paired-region and DR considerations are significant because secret availability, certificate continuity, and recovery workflows must work during regional failover.
- Service-by-service regional validation is required for private networking, certificate features, key management options, and regional service support in both target regions.
- Feature parity should not be assumed between West US 2 and West Central US for all vault-related capabilities or operational limits.

## Purpose in the IEP

Key Vault provides centralized secret, key, and certificate storage for the platform. It is a core control for keeping sensitive material out of application code, deployment artifacts, and shared configuration.

## Key design considerations

- Decide whether one shared vault or multiple vaults are needed for isolation boundaries.
- Use private access and managed identity to align with the private-first platform model.
- Plan secret and certificate lifecycle management, including rotation and expiry handling.
- Determine how West Central US workloads will access required secrets during DR.
- Choose an authorization model that is consistent and governable across teams.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Managed Identity
- App Service / Web App / API App
- Azure Functions / Function App
- API Management
- Azure Container Registry
- Azure Automation / Runbooks

## Open questions

- Should the platform use one shared vault or multiple vaults by boundary or environment?
- Which identities require read access to secrets, keys, or certificates?
- Will public network access be disabled for all vaults?
- How will secret and certificate rotation be automated and governed?
- What is the DR strategy for vault-backed configuration in West Central US?

## Relevant links

- [Microsoft Learn: Azure Key Vault basic concepts](https://learn.microsoft.com/en-us/azure/key-vault/general/basic-concepts)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- In a private-first platform, Key Vault usually becomes one of the most security-reviewed shared services, so simplicity and consistent access patterns matter.
