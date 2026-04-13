# Azure Monitor alerting / monitor resources

- **Resource provider**: `Microsoft.Insights` / `Microsoft.Monitor` / `Microsoft.AlertsManagement`

## Region considerations

- Region selection matters because monitor resources, alert processing, and some signal types have regional characteristics. West US 2 is the likely primary monitoring region, and West Central US should be reflected explicitly in alert and incident design.
- Availability zones are usually not the primary architecture concern for alerting resources, but zonal workload failures should still be represented in alert coverage.
- Paired-region and DR considerations are important because monitoring must continue to detect issues during regional degradation or failover.
- Service-by-service regional validation is required for metric availability, log routing, action behavior, and supported alerting features across both target regions.
- Feature parity should not be assumed between West US 2 and West Central US for every monitoring signal or alerting capability.

## Purpose in the IEP

Azure Monitor alerting resources turn collected platform and application signals into actionable notifications, incidents, and operational visibility. They are the response layer that connects telemetry to human and automated action.

## Key design considerations

- Decide which signals are most important at launch: availability, latency, queue backlog, failed deployments, or security events.
- Avoid alert sprawl by defining clear severity, ownership, and routing standards.
- Align alerting with Log Analytics Workspace and Application Insights telemetry design.
- Ensure alert rules cover both West US 2 primary workloads and West Central US secondary or DR assets.
- Consider how automated remediation through Azure Automation or other platform services should be gated.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Log Analytics Workspace
- Application Insights
- Azure Automation / Runbooks
- Application Gateway
- Service Bus
- Azure Database for PostgreSQL Flexible Server

## Open questions

- Which critical service indicators must alert on day one?
- What severity model and on-call routing structure will be used?
- Which alerts should trigger automated remediation versus human response?
- How will alert coverage differ between primary and secondary regions?
- Who is accountable for alert tuning and periodic review?

## Relevant links

- [Microsoft Learn: Azure Monitor overview](https://learn.microsoft.com/en-us/azure/azure-monitor/overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- This page intentionally preserves the multi-provider mapping from the inventory because monitor and alerting capabilities are spread across several Azure resource provider namespaces.
