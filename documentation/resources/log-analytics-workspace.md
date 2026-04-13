# Log Analytics Workspace

- **Resource provider**: `Microsoft.OperationalInsights`

## Region considerations

- Region selection matters because the workspace defines where much operational log data is stored and queried. West US 2 is the likely primary monitoring region, and West Central US should be considered if secondary-region isolation or DR observability is required.
- Availability zones are not typically a direct planning feature for the workspace.
- Paired-region and DR considerations are relevant because monitoring architecture must still work when workloads shift regions.
- Service-by-service regional validation is required for workspace-linked services, data residency expectations, and cross-region ingestion patterns.
- Feature parity should not be assumed between West US 2 and West Central US for all monitoring integrations or regional onboarding timelines.

## Purpose in the IEP

The Log Analytics Workspace is the central store for platform logs, query-based monitoring, and many Azure Monitor integrations. It is the operational evidence base for troubleshooting, alerting, and security review.

## Key design considerations

- Decide whether one shared workspace is sufficient or whether multiple workspaces are needed for isolation.
- Set retention and access patterns based on operational and compliance needs.
- Align workspace placement with likely primary and secondary workload regions.
- Ensure critical services are configured consistently to send telemetry to the intended workspace.
- Plan for monitoring continuity during partial or full regional failover scenarios.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Application Insights
- Azure Monitor alerting / monitor resources
- Application Gateway
- API Management
- Azure Automation / Runbooks
- Key Vault

## Open questions

- Will the platform use one shared workspace or multiple workspaces by boundary or environment?
- What retention period is required for operations, security review, and audits?
- Should West Central US send telemetry to the primary workspace, a secondary workspace, or both?
- Which services must be onboarded to centralized logging on day one?
- Who owns query standards, retention settings, and workspace cost management?

## Relevant links

- [Microsoft Learn: Log Analytics workspace overview](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-workspace-overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- Monitoring design is easiest to standardize early, before each service team chooses its own diagnostics pattern.
