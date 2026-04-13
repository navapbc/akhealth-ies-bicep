# WAF Policy for Application Gateway

- **Resource provider**: `Microsoft.Network`

## Region considerations

- Region selection matters through its association with regional Application Gateway deployments. West US 2 will likely host the primary WAF policy attachment points, and West Central US should have equivalent policy coverage if secondary ingress is deployed.
- Availability zones are not a direct WAF policy feature, but zonal Application Gateway designs may influence policy deployment and testing strategy.
- Paired-region and DR considerations are relevant because secondary-region ingress should not operate with weaker or inconsistent protections.
- Service-by-service regional validation is required for managed rule set availability, exclusions behavior, and feature support where regional rollouts lag.
- Feature parity should not be assumed between West US 2 and West Central US, so policy compatibility should be validated in both regions.

## Purpose in the IEP

The WAF policy provides centralized HTTP request inspection and protection for workloads exposed through Application Gateway. It is the main L7 security enforcement layer for internet-facing or externally consumed application traffic.

## Key design considerations

- Decide whether one shared policy or multiple app-specific policies are needed.
- Tune exclusions and custom rules carefully to avoid unnecessary production impact.
- Align policy mode, rule set version, and exception process with application release practices.
- Replicate policy intent across West US 2 and West Central US if regional ingress exists.
- Coordinate logging strategy with centralized monitoring and security review workflows.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Application Gateway
- Log Analytics Workspace
- Application Insights
- Azure Monitor alerting / monitor resources

## Open questions

- Will the platform use one shared WAF policy or multiple policies by application boundary?
- Which endpoints are most likely to need tuned exclusions or custom rules?
- What approval path is required for WAF rule changes in production?
- How will West Central US WAF configuration be kept aligned with West US 2?
- What blocked-request telemetry must be routed to security monitoring?

## Relevant links

- [Microsoft Learn: Azure Web Application Firewall overview](https://learn.microsoft.com/en-us/azure/web-application-firewall/overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- This resource is only effective when it is managed as an actively tuned control, not as a one-time deployment artifact.
