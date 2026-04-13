# App Service Environment

- **Resource provider**: `Microsoft.Web`

## Region considerations

- Region selection matters strongly because the App Service Environment is the regional hosting boundary for the application platform. West US 2 is the likely primary region, and West Central US would require its own ASE footprint if DR hosting is expected.
- Availability zones may be relevant depending on supported ASE generation, deployment model, and regional capability, so zonal assumptions should be validated explicitly.
- Paired-region and DR considerations are significant because application failover cannot rely on the primary ASE; a separate secondary-region hosting environment is typically needed.
- Service-by-service regional validation is required for ASE support, capacity, subnet requirements, zone options, and dependent Microsoft.Web capabilities in both target regions.
- Feature parity should not be assumed between West US 2 and West Central US for ASE availability, quotas, or related hosting features.

## Purpose in the IEP

The App Service Environment provides the isolated, network-integrated hosting boundary for web apps and function apps. It is a core design anchor for this private-first platform because it allows Microsoft.Web workloads to run inside a controlled virtual network perimeter.

## Key design considerations

- Reserve a dedicated subnet with sufficient capacity for platform growth and scale events.
- Decide how many ASE instances are required by environment, workload class, or region.
- Plan ingress, egress, and DNS behavior together with Application Gateway and private networking.
- Validate how ASE sizing, scaling, and cost align with the expected application estate.
- Design DR as a separate regional hosting capability rather than as an implied platform feature.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Virtual Network
- Subnets
- App Service Plan
- App Service / Web App / API App
- Azure Functions / Function App
- Azure Container Registry

## Open questions

- How many ASE instances are required across environments and regions?
- What subnet size is needed for initial deployment and future platform growth?
- Which workloads must run inside the ASE on day one versus later phases?
- Is a warm or active secondary ASE required in West Central US for DR objectives?
- What ingress and egress controls are mandatory for ASE-hosted workloads?

## Relevant links

- [Microsoft Learn: App Service Environment overview](https://learn.microsoft.com/en-us/azure/app-service/environment/overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- The platform description provided assumes ASE-based hosting rather than public multi-tenant App Service, so ASE sizing and network design have outsized architectural impact.
