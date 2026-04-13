# Azure Functions / Function App

- **Resource provider**: `Microsoft.Web`

## Region considerations

- Region selection matters because Function Apps are regional workloads. West US 2 is the likely primary deployment region, and West Central US should be treated as a separate secondary hosting target if DR or regional failover is required.
- Availability zones are not generally handled directly at the function app resource level, so resiliency depends on the underlying hosting design and supporting services.
- Paired-region and DR considerations are important because event sources, storage dependencies, and trigger behavior need explicit regional design.
- Service-by-service regional validation is required for Microsoft.Web function capabilities, storage dependencies, networking behavior, and supported hosting patterns in both regions.
- Feature parity should not be assumed between West US 2 and West Central US, especially where runtime features or scale characteristics vary by region.

## Purpose in the IEP

Function Apps provide event-driven and integration-focused compute for the platform. They are a natural fit for background processing, message handling, scheduled tasks, and workflow steps in an environment expected to become increasingly integration-heavy over time.

## Key design considerations

- Align trigger design with Service Bus, Event Grid, Storage, or timer-based processing patterns.
- Plan cold-start, concurrency, and scaling behavior according to workload criticality.
- Use managed identity, Key Vault, and private network access for dependent services.
- Ensure hosting and configuration are compatible with ASE-based, private-first constraints.
- Design DR carefully so triggers, queues, and event subscriptions do not double-process or silently stop during regional failover.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- App Service Environment
- App Service Plan
- Azure Container Registry
- Storage Account
- Service Bus
- Event Grid

## Open questions

- Which workloads are best handled as functions instead of long-running web services?
- Which triggers will be used at launch, and how are retries or dead-letter flows handled?
- Do any function workloads require dedicated compute isolation from other Microsoft.Web apps?
- How will image-based function deployments be promoted and recovered across regions?
- What regional failover behavior is required for event-driven processing in West Central US?

## Relevant links

- [Microsoft Learn: Azure Functions documentation](https://learn.microsoft.com/en-us/azure/azure-functions/)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- Function Apps are often the fastest path to growing integration capability, but they still need disciplined DR and security design.
