# Private Endpoints

- **Resource provider**: `Microsoft.Network`

## Region considerations

- Region selection matters because private endpoints are regional network interfaces for private service access. West US 2 will likely host the primary private endpoint set, and West Central US should be evaluated for parallel endpoints to support DR.
- Availability zones are not typically exposed through private endpoints directly, but the zonal and regional behavior of the backing service still affects resiliency planning.
- Paired-region and DR considerations are significant because private connectivity usually must be recreated in the secondary region rather than assumed to fail over automatically.
- Service-by-service regional validation is required because Private Link support, supported subresources, DNS behavior, and network restrictions vary by service and by region.
- Feature parity should not be assumed between West US 2 and West Central US, especially for newly released private networking capabilities.

## Purpose in the IEP

Private endpoints provide private IP-based access from the virtual network to Azure platform services. They are central to enforcing private access for data, secrets, registry, and other managed services in this environment.

## Key design considerations

- Determine which services must require private endpoints versus public access with restrictions.
- Plan DNS carefully so clients resolve service names to private addresses consistently.
- Account for subnet capacity and endpoint sprawl as integrations increase over time.
- Validate DR behavior for each private-linked service, including secondary-region connection models.
- Review whether consumer and provider resources need to be co-located by region for acceptable latency and recovery.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Virtual Network
- Subnets
- Private DNS zone / private DNS networking objects
- Key Vault
- Storage Account
- Azure Container Registry
- Service Bus

## Open questions

- Which managed services must be reachable only through private endpoints at launch?
- What private DNS design will support both West US 2 and West Central US cleanly?
- How will secondary-region private endpoints be provisioned and tested for DR?
- Which services in the inventory use alternative private networking models instead of Private Link?
- What approval and ownership model will govern creation of new private endpoints over time?

## Relevant links

- [Microsoft Learn: Azure Private Endpoint overview](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- Private endpoints usually become more numerous as integration-heavy platforms mature, so governance should be planned early.
