# Storage Account

- **Resource provider**: `Microsoft.Storage`

## Region considerations

- Region selection matters strongly because storage accounts are regional and frequently used by multiple services. West US 2 is the likely primary region, and West Central US should be evaluated for replication or secondary storage needs tied to DR.
- Availability zones are relevant where zonal redundancy options are available and appropriate for the workload.
- Paired-region and DR considerations are significant because redundancy choices such as LRS, ZRS, GRS, and related options materially affect recovery behavior.
- Service-by-service regional validation is required for redundancy SKU availability, private endpoint behavior, and specialized storage features in both regions.
- Feature parity should not be assumed between West US 2 and West Central US for redundancy options, performance tiers, or network capabilities.

## Purpose in the IEP

Storage Account provides foundational object and service storage used by applications, functions, diagnostics, and integration workflows. It often becomes one of the most widely shared platform dependencies.

## Key design considerations

- Separate storage accounts by workload sensitivity, lifecycle, or performance needs when necessary.
- Choose redundancy and replication strategy based on DR expectations, not only cost.
- Prefer private access and disable unnecessary public network exposure.
- Define naming, lifecycle, and retention patterns early because storage sprawl is common.
- Validate how West Central US DR will use replicated versus region-local storage.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Azure Functions / Function App
- Azure Data Factory
- Event Grid
- Private Endpoints
- Azure Monitor alerting / monitor resources
- Key Vault

## Open questions

- Which storage use cases are required at launch versus later phases?
- Should application data, diagnostics, and integration artifacts be separated into different accounts?
- What redundancy option is appropriate for each storage workload?
- Will public network access be disabled for all storage accounts?
- How will West Central US consume or recover required storage data during DR?

## Relevant links

- [Microsoft Learn: Azure Storage account overview](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- Storage decisions often look simple at first but have wide-reaching effects on networking, DR, and application behavior.
