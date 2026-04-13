# Application Insights

- **Resource provider**: `Microsoft.Insights`

## Region considerations

- Region selection matters because Application Insights stores application telemetry in a regional context, usually through a workspace-based design. West US 2 is the likely primary telemetry region, and West Central US should be considered for secondary-region observability planning.
- Availability zones are not typically a direct feature consideration for Application Insights.
- Paired-region and DR considerations are relevant because application observability must continue to work when workloads fail over or run in both regions.
- Service-by-service regional validation is required for workspace-based configuration, ingestion behavior, and cross-region telemetry routing expectations.
- Feature parity should not be assumed between West US 2 and West Central US for all telemetry features or regional rollout timing.

## Purpose in the IEP

Application Insights provides application-level telemetry for web apps, APIs, and functions. It helps teams understand performance, failures, dependency behavior, and user-facing reliability across the ASE-hosted application estate.

## Key design considerations

- Standardize telemetry configuration across App Services and Function Apps.
- Decide what level of sampling is acceptable for cost versus diagnostic fidelity.
- Align Application Insights with the chosen Log Analytics Workspace design.
- Ensure telemetry covers dependencies such as Service Bus, PostgreSQL, and external integrations where practical.
- Plan for consistent instrumentation in both West US 2 and West Central US workloads.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Log Analytics Workspace
- App Service / Web App / API App
- Azure Functions / Function App
- API Management
- Azure Monitor alerting / monitor resources
- Service Bus

## Open questions

- Which workloads must emit full telemetry from day one?
- What sampling and retention strategy balances cost and diagnostic needs?
- Will all application telemetry be workspace-based and centrally governed?
- How will telemetry dashboards differ for platform teams versus application teams?
- What secondary-region observability is required during West Central US failover?

## Relevant links

- [Microsoft Learn: Application Insights overview](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- Application Insights is most effective when instrumentation standards are treated as part of the platform contract, not as optional app-level extras.
