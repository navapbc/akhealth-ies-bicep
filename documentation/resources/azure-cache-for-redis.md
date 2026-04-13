# Azure Cache for Redis

- **Resource provider**: `Microsoft.Cache`

## Region considerations

- Region selection matters strongly because Redis is a regional stateful dependency. West US 2 would be the likely primary region if introduced, and West Central US would need explicit DR or secondary-cache planning.
- Availability zones may be relevant depending on SKU and regional support, so zonal resiliency should be validated directly.
- Paired-region and DR considerations are important because cache state, failover behavior, and reconnection patterns must be designed intentionally.
- Service-by-service regional validation is required for SKU availability, private access options, zone support, and failover features in both regions.
- Feature parity should not be assumed between West US 2 and West Central US for supported SKUs or resiliency options.

## Purpose in the IEP

Azure Cache for Redis would provide low-latency caching if application performance, session handling, or repeat-read reduction justifies it. It is optional and should be introduced only for a clear workload need.

## Key design considerations

- Confirm there is a measurable caching use case before adding a new stateful dependency.
- Decide whether cache content is disposable, reconstructable, or operationally critical.
- Align network access, identity, and secret handling with the private-first design.
- Plan application behavior for cache misses, stale data, and regional failover.
- Determine whether West Central US needs its own cache or can tolerate cold-start behavior during DR.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- App Service / Web App / API App
- Azure Functions / Function App
- Virtual Network
- Private Endpoints
- Managed Identity
- Azure Monitor alerting / monitor resources

## Open questions

- Which workloads have a proven caching requirement?
- Is the cache an optimization layer only, or does application behavior depend on it?
- Will all cache access stay on private network paths?
- Is secondary-region cache continuity required in West Central US?
- What operational thresholds would justify scaling or tier changes?

## Relevant links

- [Microsoft Learn: Azure Cache for Redis overview](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- Introduce this resource only when performance data shows a clear need for a shared cache layer.
