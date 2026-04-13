# Logic Apps

- **Resource provider**: `Microsoft.Logic`

## Region considerations

- Region selection matters because Logic Apps is a regional integration service. West US 2 would be the likely primary region if introduced, and West Central US would need its own design if DR execution is required.
- Availability zones may be relevant depending on Logic Apps hosting model and regional support, so zonal assumptions should be validated.
- Paired-region and DR considerations are important because connectors, workflows, and callback endpoints may require explicit duplication across regions.
- Service-by-service regional validation is required for connector availability, networking options, private access behavior, and regional feature support.
- Feature parity should not be assumed between West US 2 and West Central US, especially for connectors and hosting characteristics.

## Purpose in the IEP

Logic Apps would provide low-code or workflow-centric integration capabilities if the platform needs them. It is optional because Function Apps, Data Factory, and application code may already cover many integration patterns.

## Key design considerations

- Introduce Logic Apps only when connector-driven or workflow-centric use cases justify another integration runtime.
- Decide how it fits relative to Function Apps and Data Factory to avoid overlapping patterns.
- Align network and identity design with the private-first platform stance.
- Plan for secrets, callback endpoints, and connector governance.
- Determine whether secondary-region workflow execution is required in West Central US.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- API Management
- Azure Functions / Function App
- Azure Data Factory
- Service Bus
- Event Grid
- Key Vault

## Open questions

- Are there workflow or connector scenarios that cannot be addressed cleanly with existing in-scope services?
- Should Logic Apps be reserved for external integrations rather than internal platform flows?
- What hosting and networking model would satisfy private-first requirements?
- Does the DR strategy require Logic Apps in West Central US?
- Who would govern connector approval and workflow lifecycle?

## Relevant links

- [Microsoft Learn: Azure Logic Apps overview](https://learn.microsoft.com/en-us/azure/logic-apps/logic-apps-overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- Introduce this resource when workflow speed and connector breadth outweigh the cost of another integration platform.
