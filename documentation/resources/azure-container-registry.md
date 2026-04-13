# Azure Container Registry

- **Resource provider**: `Microsoft.ContainerRegistry`

## Region considerations

- Region selection matters strongly because the registry is a regional dependency for image storage and pull performance. West US 2 is the likely primary registry region, and West Central US should be evaluated as a secondary replication or standby location for DR.
- Availability zones are not the primary design lever for this service, but regional resiliency and image availability remain important.
- Paired-region and DR considerations are significant because App Services and Function Apps hosted from registry images depend on image availability during deployment and recovery.
- Service-by-service regional validation is required for SKU support, private networking, geo-replication options, and regional capacity expectations.
- Feature parity should not be assumed between West US 2 and West Central US, particularly for replication features and private access behavior.

## Purpose in the IEP

Azure Container Registry stores the container images used by App Services and Function Apps in the Microsoft.Web hosting estate. It is the central artifact repository for the platform's container-based deployment model.

## Key design considerations

- Decide whether a single primary registry is sufficient or whether regional replication is required for DR.
- Use private access patterns so runtime image pulls stay aligned with the private-first architecture.
- Plan image naming, tagging, retention, and promotion practices carefully.
- Ensure Microsoft.Web workloads can authenticate to pull images without using shared credentials.
- Validate registry access and latency expectations for West US 2 primary hosting and West Central US secondary hosting.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- App Service / Web App / API App
- Azure Functions / Function App
- App Service Environment
- Managed Identity
- Private Endpoints
- Key Vault

## Open questions

- Is one primary registry sufficient, or is West Central US replication required?
- What image promotion strategy will separate build, test, and production artifacts?
- Which identities will be authorized to pull images at runtime?
- Will public network access be disabled for the registry?
- How long must old images be retained for rollback and audit needs?

## Relevant links

- [Microsoft Learn: Azure Container Registry introduction](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- Because the platform expects Microsoft.Web workloads to run from ACR images, registry availability directly affects both release safety and DR readiness.
