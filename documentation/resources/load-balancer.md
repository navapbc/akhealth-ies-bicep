# Load Balancer

- **Resource provider**: `Microsoft.Network`

## Region considerations

- Region selection matters because Azure Load Balancer is a regional network service. West US 2 would be the likely primary region if introduced, and West Central US would need its own deployment for DR or secondary operations.
- Availability zones are relevant where zonal or zone-redundant frontend design is needed and supported.
- Paired-region and DR considerations are important because L4 traffic distribution does not fail over cross-region automatically.
- Service-by-service regional validation is required for SKU support, zone support, and frontend or backend behavior in both target regions.
- Feature parity should not be assumed between West US 2 and West Central US for all load balancing capabilities or capacity characteristics.

## Purpose in the IEP

Load Balancer would provide L4 traffic distribution if the platform needs it for scenarios not well served by Application Gateway. In an ASE-based web platform, it is optional and would usually be introduced only for specific network or protocol requirements.

## Key design considerations

- Confirm that a true L4 use case exists before introducing another ingress tier.
- Determine whether the need is internal, external, or both.
- Coordinate subnet, NSG, and route design with any new frontend exposure.
- Plan secondary-region duplication if DR requires equivalent network-level entry points.
- Avoid overlapping responsibility with Application Gateway unless there is a clear protocol or performance reason.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Virtual Network
- Subnets
- Network Security Groups
- Route Tables
- Application Gateway
- App Service Environment

## Open questions

- Is there a concrete non-HTTP or pure L4 traffic requirement in the platform?
- Would the load balancer be internal-only, external, or both?
- What gap would it solve that Application Gateway does not already cover?
- Is zone-redundant design required in both West US 2 and West Central US?
- Who would own this component operationally if it is introduced?

## Relevant links

- [Microsoft Learn: Azure Load Balancer overview](https://learn.microsoft.com/en-us/azure/load-balancer/load-balancer-overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- Introduce this resource only when a specific protocol, performance, or network design need justifies it.
