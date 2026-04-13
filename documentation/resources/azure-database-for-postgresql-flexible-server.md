# Azure Database for PostgreSQL Flexible Server

- **Resource provider**: `Microsoft.DBforPostgreSQL`

## Region considerations

- Region selection matters strongly because the database is a regional stateful dependency. West US 2 is the likely primary database region, and West Central US should be evaluated deliberately for secondary or DR data strategy.
- Availability zones are relevant where supported because Flexible Server offers HA patterns that may depend on zonal placement and regional support.
- Paired-region and DR considerations are significant because backups, replicas, failover, and recovery point expectations must be designed explicitly.
- Service-by-service regional validation is required for HA modes, private access patterns, maintenance options, storage performance, and replica capabilities in both regions.
- Feature parity should not be assumed between West US 2 and West Central US, especially for high availability and regional replica features.

## Purpose in the IEP

Azure Database for PostgreSQL Flexible Server provides the primary relational database platform for workloads that need managed PostgreSQL. It is likely to support transactional application data, integration state, and shared service data stores in the platform.

## Key design considerations

- Choose the right private access model and subnet placement for the service.
- Validate storage sizing, IOPS, compute scaling, and maintenance windows against workload needs.
- Plan HA and DR separately, including backup retention, replica strategy, and failover expectations.
- Externalize credentials and use managed identity where application patterns support it.
- Confirm whether all intended workloads truly fit a shared PostgreSQL platform or need separate databases.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Virtual Network
- Subnets
- App Service / Web App / API App
- Azure Functions / Function App
- Managed Identity
- Key Vault

## Open questions

- Which workloads will use PostgreSQL Flexible Server at launch?
- What HA and DR objectives are required for databases in West US 2 and West Central US?
- Which private networking model will be used for database access?
- How will schema change management and database ownership be handled?
- Are there workloads that need separate database instances for security or performance isolation?

## Relevant links

- [Microsoft Learn: Azure Database for PostgreSQL Flexible Server overview](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- This page assumes PostgreSQL Flexible Server is the intended managed relational default where the inventory marks PostgreSQL in scope.
