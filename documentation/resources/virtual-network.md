# Virtual Network

- **Resource provider**: `Microsoft.Network`

## Region considerations

- Region selection matters because the virtual network is the regional network boundary for the platform. West US 2 is the likely primary deployment region, and West Central US should be planned as a separate secondary or DR network footprint rather than an extension of the primary network.
- Availability zones are not a direct virtual network feature, but subnet placement and the zonal capabilities of attached services need to be planned inside the regional network design.
- Paired-region and DR considerations are significant. If workloads fail over to West Central US, equivalent address space, routing intent, private name resolution, and service connectivity patterns will usually be needed there as well.
- Service-by-service regional validation is still required because private networking features, quota availability, and dependent platform services may differ between West US 2 and West Central US.
- Feature parity should not be assumed between primary and secondary regions, especially for zonal services, private access patterns, and service capacity.

## Purpose in the IEP

The virtual network provides the core private network boundary for the environment. In this private-first architecture, it is the foundation for ASE-hosted applications, private endpoints, segmented subnets, and controlled east-west and north-south traffic paths.

## Key design considerations

- Reserve enough address space for the App Service Environment, application subnets, private endpoints, and future integration-heavy growth.
- Keep subnet allocation structured so primary and DR regions can be mapped consistently.
- Plan routing and security boundaries together with route tables and network security groups.
- Determine whether the topology is single virtual network, hub-and-spoke, or another segmented model.
- Align private DNS, private endpoints, and any forced-tunneling decisions with the network design.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Subnets
- Network Security Groups
- Route Tables
- Private Endpoints
- Application Gateway
- App Service Environment

## Open questions

- What address space is required for West US 2 at day one and for long-term expansion?
- How closely should West Central US mirror the primary network layout for DR?
- Will the environment use a flat network, hub-and-spoke, or another segmentation model?
- What egress controls and route inspection points are required?
- Which services must be reachable only through private paths inside the network?

## Relevant links

- [Microsoft Learn: Azure Virtual Network overview](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- This page assumes the network is being designed around an ASE-centric hosting model rather than public multi-tenant App Service.
