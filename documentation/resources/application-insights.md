# Application Insights

- **Resource provider**: `Microsoft.Insights`

## Purpose in the IEP

Application Insights provides application level  logging for web apps, APIs, and functions. It display application performance, failures and dependency behavior across the app service environmnet application hosting environment.


## Region considerations

- Region selection matters because Application Insights stores application logging in a regional context. West US 2 is the likely primary region, and West Central US should be considered for secondary region planning.
- Availability zones are not typically a direct feature consideration for Application Insights.
- Paired-region and DR considerations are relevant because application observability must continue to work when workloads fail over or run in both regions.
- Service-by-service regional validation is required for workspace-based configuration, ingestion behavior, and cross-region  logging routing expectations.
- Feature parity should not be assumed between West US 2 and West Central US for all  logging features or regional rollout timing.


## Key design considerations

- Standardize logging configuration across App Services and Function Apps.
- Decide what level of sampling is acceptable for cost versus diagnostic fidelity.
- Align Application Insights with the chosen Log Analytics Workspace design.
- Ensure logging covers dependencies such as Service Bus, PostgreSQL, and external integrations where practical.
- Plan for consistent instrumentation in both West US 2 and West Central US workloads.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Azure still creates new workspace-based Application Insights resources with legacy smart-detection behavior by default while smart-detection migration to alert rules remains preview.
- That legacy behavior can automatically create a global `Application Insights Smart Detection` action group to send notifications to `Monitoring Reader` and `Monitoring Contributor` role assignments unless proactive detection email behavior is explicitly managed.
- This repository keeps Application Insights workspace-based, but does not currently enforce proactive detection settings in Bicep. The direct `Microsoft.Insights/components/ProactiveDetectionConfigs` resource path appeared valid in the template reference and provider schema, but Azure rejected the emitted ARM template during deployment.
- The solution configuration now surfaces intended state for this behavior through `appInsightsConfig.sendSmartDetectionEmailsToSubscriptionOwners`, but that value is currently informational until a reliable post-deployment enforcement path is added.
- Until Azure's runtime behavior is clearer, treat proactive detection suppression as a post-deployment automation concern rather than a trusted declarative Bicep pattern in this solution.
- If the `Application Insights Smart Detection` action group reappears after deployment, treat it as Azure-created platform behavior and inspect proactive detection configuration before treating it as unmanaged drift.
- If that action group must be deleted manually, the Azure portal may fail with `UnsupportedApiVersion` when it attempts to call the action group delete path using a preview API version the backend does not accept. In that case, delete it through `az rest` or another direct ARM call using a supported `Microsoft.Insights/actionGroups` API version instead of relying on the portal.

## Dependencies and relationships

- Log Analytics Workspace
- App Service / Web App / API App
- Azure Functions / Function App
- API Management
- Azure Monitor alerting / monitor resources
- Service Bus

## Open questions

- Which workloads must emit full logging from day one?
- What sampling and retention strategy balances cost and diagnostic needs?
- Will all application logging be workspace-based and centrally governed?
- What secondary-region observability is required during West Central US failover?

## Relevant links

- [Microsoft Learn: Application Insights overview](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Microsoft Learn: Manage Application Insights smart detection rules with ARM templates](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/proactive-arm-config)
- [Microsoft Learn: Smart Detection e-mail notification change](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/proactive-email-notification)
- [Microsoft Learn: Migrate Azure Monitor Application Insights smart detection to alerts](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-smart-detections-migration)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- Application Insights is most effective when instrumentation standards are treated as part of the platform contract, not as optional app-level extras.
- Smart detection and smart-detection alert migration are a separate lifecycle concern from whether Application Insights itself is workspace-based. This solution treats the component as modern, but still has to account for Azure's legacy smart-detection defaults.
- Microsoft does not currently provide an Azure Verified Module for either `ProactiveDetectionConfigs` or `smartDetectorAlertRules`, which is another sign that this area still needs careful validation before it becomes a first-class template contract.
