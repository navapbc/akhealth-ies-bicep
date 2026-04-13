# Network Security Groups

- **Resource provider**: `Microsoft.Network`

## Region considerations

- Region selection matters indirectly because network security groups are applied to regional virtual network resources. West US 2 will likely host the primary rule sets, and West Central US should have equivalent controls for DR.
- Availability zones are not a direct network security group concern, but zonal services may change expected traffic paths and source or destination ranges.
- Paired-region and DR planning are relevant because failover is only useful if equivalent traffic filtering exists in the secondary region.
- Service-by-service regional validation is still needed where platform services have region-specific network behaviors or service tag differences.
- Feature parity should not be assumed between primary and secondary regions for all service integrations, so rule assumptions should be validated in both West US 2 and West Central US.

## Purpose in the IEP

Network security groups provide baseline L3 and L4 traffic filtering for subnets and, where applicable, individual interfaces. They help enforce trust boundaries inside the private-first platform.

## Key design considerations

- Prefer subnet-level policy where consistent enforcement is needed across a tier.
- Keep rules understandable and grouped by application, platform, or shared service purpose.
- Coordinate NSG design with route tables, private endpoints, and Application Gateway flows.
- Avoid overuse of broad allow rules that erode private segmentation.
- Plan rule portability so West Central US can implement comparable controls.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Virtual Network
- Subnets
- Route Tables
- Application Gateway
- App Service Environment
- Private Endpoints

## Open questions

- Which traffic flows must be explicitly allowed between ingress, app, data, and management segments?
- How will outbound internet and platform egress be controlled?
- What exception process is required for temporary or one-off network rule changes?
- How closely should West Central US security rules mirror West US 2?
- Which teams own approval, implementation, and review of NSG changes?

## Relevant links

- [Microsoft Learn: Azure network security groups overview](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- NSGs are often the first place reviewers look for whether private-first intent is reflected in actual traffic policy.
