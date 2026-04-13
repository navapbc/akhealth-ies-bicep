# API Management

- **Resource provider**: `Microsoft.ApiManagement`

## Region considerations

- Region selection matters strongly because API Management is a regional service with region- and SKU-specific networking behaviors. West US 2 is the likely primary region, and West Central US should be assessed as a secondary or DR deployment target if API continuity is required.
- Availability zones are relevant only for supported SKUs and regions, so zonal resiliency must be validated rather than assumed.
- Paired-region and DR considerations are important because API definitions, policies, identities, certificates, and networking mode may all need explicit secondary-region treatment.
- Service-by-service regional validation is required for VNet integration mode, private exposure options, zone support, and developer or management endpoint behavior.
- Feature parity should not be assumed between West US 2 and West Central US, especially for network injection patterns and premium capabilities.

## Purpose in the IEP

API Management provides the managed API facade for internal or external consumers. In this environment, it can centralize API publishing, policy enforcement, versioning, and access control in front of ASE-hosted web apps and function apps.

## Key design considerations

- Decide whether API Management is externally exposed, internally exposed, or positioned behind Application Gateway.
- Align network mode with the private-first design and the ASE-based hosting model.
- Determine how backend routing, versioning, and policy inheritance will be structured.
- Plan identity, secret access, and certificate handling without embedding sensitive values in configuration.
- Consider DR expectations for API traffic, gateway state, and policy synchronization across regions.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Application Gateway
- App Service / Web App / API App
- Azure Functions / Function App
- Managed Identity
- Key Vault
- Azure Monitor alerting / monitor resources

## Open questions

- Will API Management be internet-facing, internal-only, or behind Application Gateway?
- Which APIs need centralized policy enforcement at launch versus later phases?
- What SKU and networking mode meet both private access and resiliency requirements?
- Does the DR strategy require a hot secondary API gateway in West Central US?
- How will API definitions and policies be promoted across environments and regions?

## Relevant links

- [Microsoft Learn: API Management documentation](https://learn.microsoft.com/en-us/azure/api-management/)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- API Management is especially valuable if the platform is expected to become more integration-heavy over time, even if the initial API surface is modest.
