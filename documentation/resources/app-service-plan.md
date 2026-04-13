# App Service Plan

- **Resource provider**: `Microsoft.Web`

## Region considerations

- Region selection matters because App Service Plans are regional compute containers for Microsoft.Web workloads. West US 2 is the likely primary placement, and West Central US would need its own plans if DR hosting is implemented there.
- Availability zones are not typically managed directly at the App Service Plan layer in the same way as other services, so resiliency depends largely on the ASE and regional hosting design.
- Paired-region and DR considerations are relevant because plan capacity and scale settings do not transfer automatically across regions.
- Service-by-service regional validation is required for supported SKUs, ASE alignment, quotas, and any regional hosting constraints.
- Feature parity should not be assumed between West US 2 and West Central US for scale options, quotas, or related Microsoft.Web features.

## Purpose in the IEP

The App Service Plan provides the compute and scaling boundary for App Services and, where applicable, Function Apps running in the ASE-hosted platform.

## Key design considerations

- Decide how to segment workloads across plans for isolation, cost, and scaling independence.
- Align plan sizing with application runtime characteristics, not only initial traffic.
- Avoid mixing unrelated workloads that scale differently or require different maintenance handling.
- Ensure plan design matches ASE capacity and subnet planning.
- Mirror the plan structure in West Central US if DR requires rapid workload activation there.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- App Service Environment
- App Service / Web App / API App
- Azure Functions / Function App
- Azure Container Registry
- Managed Identity
- Azure Monitor alerting / monitor resources

## Open questions

- How many App Service Plans are needed to separate critical workloads?
- Which applications require dedicated scaling versus shared compute?
- What minimum standby capacity is needed to support safe deployments and failover?
- Should West Central US mirror the primary plan layout or use a reduced DR footprint?
- What operational thresholds will trigger scale changes?

## Relevant links

- [Microsoft Learn: Azure App Service plans overview](https://learn.microsoft.com/en-us/azure/app-service/overview-hosting-plans)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- App Service Plan boundaries often become long-lived architecture decisions because they shape both cost and operational blast radius.
