# App Service / Web App / API App

- **Resource provider**: `Microsoft.Web`

## Region considerations

- Region selection matters because App Services are regional workloads. West US 2 is the likely primary hosting region, and West Central US should be treated as a separate secondary deployment target if application DR is required.
- Availability zones are not usually handled directly at the app resource layer, so resiliency depends more on the ASE, ingress design, and regional duplication strategy.
- Paired-region and DR considerations are important because application instances, configuration, and deployment artifacts must be replicated deliberately across regions.
- Service-by-service regional validation is required for Microsoft.Web features, deployment slots, networking behavior, and supported runtime capabilities in both target regions.
- Feature parity should not be assumed between West US 2 and West Central US, particularly for newer hosting features or quota-sensitive capabilities.

## Purpose in the IEP

App Service workloads host the platform's web applications and APIs. In this environment, they are expected to run inside the ASE and be deployed from Azure Container Registry images rather than from source packages directly.

## Key design considerations

- Externalize state so applications can scale or fail over without depending on local instance state.
- Align ingress with Application Gateway and, where appropriate, API Management.
- Use managed identity and Key Vault instead of embedding credentials in configuration.
- Decide how configuration, slot usage, and rollout strategy will work for container-based deployments.
- Plan for regional replication of images, configuration, and dependent services for West Central US DR.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- App Service Environment
- App Service Plan
- Azure Container Registry
- Application Gateway
- API Management
- Key Vault

## Open questions

- Which applications are hosted as web apps versus other runtime patterns?
- Will every internet-facing app be fronted by Application Gateway, API Management, or both?
- How will images be promoted from build to deployment across environments and regions?
- Which applications require deployment slots or other release-safety mechanisms?
- What DR behavior is required for applications in West Central US: warm standby, active-active, or rebuild on demand?

## Relevant links

- [Microsoft Learn: Azure App Service overview](https://learn.microsoft.com/en-us/azure/app-service/overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- This page assumes containerized deployment from ACR is the standard hosting pattern for App Services in the platform.
