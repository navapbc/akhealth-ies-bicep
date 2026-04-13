# Cosmos DB

- **Resource provider**: `Microsoft.DocumentDB`

## Region considerations

- Region selection matters strongly because Cosmos DB is designed around regional placement and, when needed, multi-region distribution. West US 2 would be the likely primary region if introduced, and West Central US should be evaluated explicitly for secondary or replicated use.
- Availability zones may be relevant depending on account configuration and regional support, so zonal expectations should be validated directly.
- Paired-region and DR considerations are significant because consistency, multi-region writes, failover priority, and replication costs are central design choices.
- Service-by-service regional validation is required for API availability, private networking, multi-region options, and consistency-related capabilities in both regions.
- Feature parity should not be assumed between West US 2 and West Central US for every API, feature, or replication option.

## Purpose in the IEP

Cosmos DB would provide a globally distributed or schema-flexible data platform if the application portfolio develops a clear need for it. It is optional and should be introduced only when workload characteristics justify a non-relational, multi-model database service.

## Key design considerations

- Confirm that workload requirements genuinely justify Cosmos DB rather than PostgreSQL or another simpler option.
- Choose API, consistency, partitioning, and replication models deliberately.
- Align private access and identity with the platform's private-first architecture.
- Plan DR and secondary-region use in West Central US based on data consistency and failover expectations.
- Understand cost implications of throughput, storage, and multi-region replication before adoption.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- App Service / Web App / API App
- Azure Functions / Function App
- Private Endpoints
- Managed Identity
- Key Vault
- Azure Monitor alerting / monitor resources

## Open questions

- What workload requirement justifies Cosmos DB instead of PostgreSQL?
- Which API and consistency model would the platform need?
- Is multi-region replication required, or would a single-region deployment be sufficient?
- Will West Central US be a read replica, a failover target, or unused for this service?
- How will cost and partition design be governed over time?

## Relevant links

- [Microsoft Learn: Azure Cosmos DB overview](https://learn.microsoft.com/en-us/cosmos-db/overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- Introduce this resource only when a workload truly needs distributed, schema-flexible storage characteristics that the in-scope services do not provide.
