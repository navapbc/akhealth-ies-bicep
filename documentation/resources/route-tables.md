# Route Tables

- **Resource provider**: `Microsoft.Network`

## Region considerations

- Region selection matters because route tables are applied to regional subnets. West US 2 is likely the primary route domain, with West Central US requiring its own routing design for DR.
- Availability zones are not a direct route table feature, but zonal ingress and egress patterns can affect next-hop strategy and failure behavior.
- Paired-region and DR considerations are important because secondary-region routing often diverges unless it is intentionally mirrored.
- Service-by-service regional validation is required when Azure services have specific route support limitations or asymmetric behaviors.
- Feature parity should not be assumed between West US 2 and West Central US for all dependent services, so forced-routing patterns should be revalidated in both regions.

## Purpose in the IEP

Route tables define how traffic leaves or traverses selected subnets. They shape egress, inspection paths, and private routing behavior for the private-first platform.

## Key design considerations

- Coordinate route design with NSGs so security intent and actual pathing stay aligned.
- Validate whether the App Service Environment and other managed services support planned custom routes.
- Keep route intent consistent across primary and secondary regions where failover is expected.
- Plan for troubleshooting visibility when private endpoints and service-specific network paths are introduced.
- Avoid adding route complexity that provides little security or operational value.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Virtual Network
- Subnets
- Network Security Groups
- Application Gateway
- App Service Environment
- Private Endpoints

## Open questions

- Which subnets require custom routes versus default Azure routing?
- Is forced tunneling required for any workload classes in this platform?
- Which managed services impose route limitations that must be accommodated?
- What routing model should be replicated in West Central US for DR?
- How will route effectiveness be validated after deployment changes?

## Relevant links

- [Microsoft Learn: Azure virtual network traffic routing](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- Route tables matter most when the team wants to turn private-first networking into enforceable traffic paths rather than default behavior.
