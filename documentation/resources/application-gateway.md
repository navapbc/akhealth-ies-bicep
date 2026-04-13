# Application Gateway

- **Resource provider**: `Microsoft.Network`

## Region considerations

- Region selection matters strongly because Application Gateway is a regional ingress service. West US 2 is the likely primary ingress region, with West Central US requiring a separate deployment if DR or regional failover is expected.
- Availability zones are relevant where supported because zonal or zone-redundant deployment can improve regional resiliency for internet or private ingress paths.
- Paired-region and DR considerations are important because listener configuration, certificates, routing rules, and backend health definitions usually need explicit duplication in the secondary region.
- Service-by-service regional validation is required for WAF v2 capabilities, zone support, private frontend needs, and any integration assumptions with the App Service Environment or API Management.
- Feature parity should not be assumed between West US 2 and West Central US, especially for zone availability, capacity, and newer feature support.

## Purpose in the IEP

Application Gateway provides the L7 ingress tier for HTTP and HTTPS traffic into the platform. In this architecture, it is a likely control point for routing, TLS handling, and exposing ASE-hosted applications without making the application tier broadly public.

## Key design considerations

- Determine whether Application Gateway fronts direct web applications, API Management, or both.
- Validate subnet sizing, dedicated placement, and network pathing inside the virtual network.
- Decide whether public ingress, private ingress, or both are required.
- Align backend routing with ASE-hosted App Services and Function Apps deployed from ACR images.
- Plan certificate handling, hostname strategy, and failover behavior across regions.

## Security considerations

- Stub for potential use later.

## Operational considerations

- Stub for potential use later.

## Dependencies and relationships

- Virtual Network
- Subnets
- Network Security Groups
- WAF Policy for Application Gateway
- API Management
- App Service / Web App / API App

## Open questions

- Will Application Gateway be the primary public ingress for all web and API traffic?
- Does the target design require public, private, or split frontend listeners?
- Should API Management sit behind Application Gateway, beside it, or serve a different ingress role?
- Is zone-redundant deployment required and supported in both West US 2 and West Central US?
- How will certificate lifecycle management be handled across regions?

## Relevant links

- [Microsoft Learn: Azure Application Gateway overview](https://learn.microsoft.com/en-us/azure/application-gateway/overview)
- [Microsoft Learn: Azure regions overview](https://learn.microsoft.com/en-us/azure/reliability/regions-overview)
- [Microsoft Learn: Azure availability zones overview](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

## Notes

- In an ASE-based platform, Application Gateway often becomes the most visible north-south control plane for both security and availability reviews.
