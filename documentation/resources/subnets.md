# Subnets

- **Resource provider**: `Microsoft.Network`

## Region considerations

- Region selection matters because subnets are regional children of the virtual network. West US 2 is the likely primary placement, with a separate West Central US subnet strategy needed for DR.
- Availability zones are not assigned to subnets directly, but zonal services deployed into or alongside them may impose subnet sizing and placement constraints.
- Paired-region and DR planning are relevant because subnet purposes, address ranges, and delegated uses should usually be mirrored where failover is expected.
- Service-by-service regional validation is required for subnet delegation, private access models, and any service-specific network integration rules.
- Feature parity should not be assumed between West US 2 and West Central US for services that consume or depend on subnets.

## Purpose in the IEP

Subnets provide the internal segmentation model for the platform. They separate ingress, hosting, private access, and data service footprints so the environment can enforce clearer trust boundaries and operational ownership.

## Key design considerations

- Allocate dedicated subnets for the App Service Environment and other services with hard isolation requirements.
- Size subnets for future scale, especially for ASE infrastructure and private endpoint growth.
- Avoid overloading a single subnet with unrelated workloads or lifecycle patterns.
- Keep naming and purpose consistent across primary and DR regions.
- Validate subnet delegation and service constraints before finalizing address plans.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Virtual Network
- Network Security Groups
- Route Tables
- Private Endpoints
- Application Gateway
- App Service Environment
- Azure Database for PostgreSQL Flexible Server

## Open questions

- Which dedicated subnets are required at initial launch versus later growth stages?
- How much IP space should be reserved for private endpoints over time?
- Which services require delegated or isolated subnets?
- Should the West Central US subnet plan be a close mirror of West US 2 or a reduced DR footprint?
- What ownership model will govern subnet changes after go-live?

## Relevant links

- [Microsoft Learn: Manage Azure virtual networks and subnets](https://learn.microsoft.com/en-us/azure/virtual-network/manage-virtual-network)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- Subnet planning is one of the earliest decisions that can constrain later platform options.
