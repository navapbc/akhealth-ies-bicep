# Service Bus

- **Resource provider**: `Microsoft.ServiceBus`

## Region considerations

- Region selection matters strongly because Service Bus namespaces are regional messaging backbones. West US 2 is the likely primary region, and West Central US should be considered explicitly for DR and message continuity.
- Availability zones may be relevant depending on SKU and regional support, so zone-related resiliency needs validation rather than assumption.
- Paired-region and DR considerations are significant because queue and topic topology, aliases, failover behavior, and message recovery need intentional design.
- Service-by-service regional validation is required for SKU support, private networking, zone support, and disaster recovery features in both target regions.
- Feature parity should not be assumed between West US 2 and West Central US, especially for premium capabilities and private access behavior.

## Purpose in the IEP

Service Bus provides durable messaging for decoupled application and integration workflows. It is likely to be an important backbone service as the platform grows more integration-heavy and needs reliable asynchronous processing.

## Key design considerations

- Choose between queue, topic, and subscription patterns based on integration needs.
- Decide whether Premium-level isolation, throughput, or private networking features are required.
- Align identity and access control with managed identity rather than broad shared keys where possible.
- Plan DR behavior for namespaces, aliases, message backlog, and replay requirements.
- Validate how ASE-hosted apps and Function Apps connect privately and reliably to the namespace.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Azure Functions / Function App
- App Service / Web App / API App
- Managed Identity
- Private Endpoints
- Azure Monitor alerting / monitor resources
- Event Grid

## Open questions

- Which integration flows require durable messaging rather than synchronous APIs?
- Is Premium tier required for isolation, throughput, or networking reasons?
- What message retention, replay, and dead-letter handling standards are needed?
- How should West Central US DR handle namespace failover and message continuity?
- Which teams own topic and queue lifecycle management after deployment?

## Relevant links

- [Microsoft Learn: Azure Service Bus overview](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- Service Bus is often the cleanest way to reduce tight coupling as the platform's integration surface grows.
