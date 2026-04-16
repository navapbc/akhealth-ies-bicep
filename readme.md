# README


This folder contains a local and reorganized  version of the App Service LZA template set with only the dependencies it needs.
(from here https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/app-service-lza/hosting-environment)

Modules are organized by deployment area and deployment order to keep flow obvious and legibile:

- 01-network
- 02-monitoring
- 03-app-hosting
- 04-application
- 05-identity
- 06-secrets
- 07-edge
- shared

Deployment Example:

az deployment sub create --location westus2 --template-file ./main.bicep --parameters ./params/main.dev.bicepparam


# Naming scheme

Resource names should flow and be readable from broad resource type to specific instance:

1. resource abbreviation
2. system abbreviation
3. region abbeviation
4. environment abbreviation
5. workload description (when it is relevant)
6. instance number

resourceAbbreviation-systemAbbreviation-regionAbbreviation-environmentAbbreviation-workloadDescription-instanceNumber

Resource Abbreviation - https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
System Abbreviation - Abbreviation representing the authorized system the resouce belongs to
Region Abbreviation - WestUS/wus, WestUS2/wus
Environment Abbreviation - Development/dev, Test/tst, Staging/stg, User Acceptance Testing/uat, Production/prd 
Workload Description (optional) - A short description of the workload the resource is supporting (only when it adds meaning to the name)
Instance Number - to denote the instance number for uniqueness

If naming is very restictive you may remove dashes. You may also remove region abbeviation only if you must do so to comply with naming length restrictions. You may also remove a 0 from the instance numbering (001 to 01) only if you must do so. You would handle these accomodations in the resource specific module when it is assembling the resource name.

When workloadDescription is not defined, the segment should be not included. It should not leave an empty segment or a double dash.

example for this template set: kv-iep-wus2-dev-001, app-iep-wus2-dev-tasks-001

## Naming implementation

This template should keep naming consistent globally, while keeping final name creation close to the resource that owns the name.

- Shared naming components should be declared explicitly in .bicepparams.
- Shared naming components should flow through main into the modules that need them.
- Resource abbreviations should stay local to the module that creates that specific resource.
- Region abbreviation uses a shared map (because all resources are defined with a more fixed set of regions)
- Resource specific naming schemes should be handled in the module for that resource.

This keeps naming readable and predictable without adding an extra abstraction layer that users have to mentally work through.

## Repo-Local Abbreviations

Considerations: Use Microsoft CAF abbreviations where Microsoft publishes one. Microsoft mixes abbreviations for the Microsoft.CDN provider between cdnp, cdne, fde, and afd. They use fde to convery frontdoor product vs where i would prefer to be technically honest and convery the actual resource type (cdn). But, for end user legibility purposes, afd and fd are sufficiently communicative. 


For resource types that don't have an official CAF abbreviation, this repo uses the following local conventions:

- fdsecp for Microsoft.Cdn/profiles/securityPolicies
- fder for Microsoft.Cdn/profiles/afdEndpoints/routes
- fdog for Microsoft.Cdn/profiles/originGroups
- fdorg for Microsoft.Cdn/profiles/originGroups/origins
- fdrset for Microsoft.Cdn/profiles/ruleSets
- fdrul for Microsoft.Cdn/profiles/ruleSets/rules
- fdcdom for Microsoft.Cdn/profiles/customDomains
- fdsecr for Microsoft.Cdn/profiles/secrets


TODO:
- Add staged/layered testing to test modules in layers, and respective layers by module, to enable

## Resource Groups and Naming

For resource groups, we will adjust the naming the scheme just a small bit, because resource groups are moreso containers and less dedicated resources.

resourceAbbreviation-systemAbbreviation-regionAbbreviation-environmentAbbreviation-workloadDescription-instanceNumber (e.x. rg-iep-wus2-dev-network-01)
resourceAbbreviation-systemAbbreviation-regionAbbreviation-environmentAbbreviation-workloadDescription-subWorkloadDescription-instanceNumber (rg-iep-wus2-dev-network-edge-01)

This is a non-exhaustive list of example values for these:
resourceAbbreviation = rg
systemAbbreviation = iep
regionAbbreviation = wus, wus2, wus3, wcus, eus, eus2
environmentAbbreviation = dev, tst, sit, stg, uat, prd
workloadDescription = network, hosting, data, operations

## Resource Group Names Examples

rg-iep-wus2-dev-network-01
rg-iep-wus2-dev-network-edge-01
rg-iep-wus2-dev-hosting-01
rg-iep-wus2-dev-data-01
rg-iep-wus2-dev-operations-01



## Resource Group Organizing

### `rg-iep-wus2-env-network-01`
Base network and private connectivity resources:
- Virtual Network
- Subnets
- NSGs
- Route Tables
- Private Endpoints
- Private endpoint NICs
- Private DNS zone groups / related private DNS resources

Platform behavior note:
For delegated service subnets, this solution intentionally leaves `privateEndpointNetworkPolicies` unset. Those subnets are not modeled as private endpoint hosting subnets, and Azure may still surface a concrete policy value on the live resource after deployment. That live value is treated as platform-managed state, not as an operator-managed contract in this repo.

### `rg-iep-wus2-env-network-edge-01`
Traffic entry and API access group:
- Application Gateway
- WAF Policy/Resources
- API Management
- Load Balancer

### `rg-iep-wus2-env-hosting-01`
Primary workload hosting:
- App Service Environment
- App Service Plans
- Web Apps / API Apps
- Function Apps
- Function Apps used mainly as glue/orchestration
- App Service plans dedicated to integration workloads
- Hosted workflow/runtime components that support app to app integration
- Azure Container Registry
- Managed identities closely tied to hosting/runtime

### `rg-iep-wus2-env-data-01`
Persistent data group:
- PostgreSQL
- Storage Accounts
- Redis
- SQL
- Cosmos DB
- Data Factory
- ETL / ELT pipelines
- ingestion/transformation jobs
- data-processing Functions if primarily data-oriented


### `rg-iep-wus2-env-operations-01`
General support resource group:
- miscellaneous support resources
- small admin utilities
- things that do not yet justify a clearer subcategory
- Log Analytics
- Application Insights
- alerts
- action groups
- dashboards/workbooks
- monitor-focused automation
- Key Vault
- certificate-related resources
- security-focused support utilities
- many miscellaneous identity-adjacent support resources
- User assignment managed identity
- Federated credentials
- Identity/auth resources




Decision rule
When choosing a resource group for a resource, ask:

Is this a base connectivity resource? network
Is this a traffic entry or API access resource? network-edge
Is this private networking attachment to another service? network
Is this where the main workload runs, including hosted glue/orchestration for application integrations? hosting
Is this where business or platform data lives, including data movement and transformation resources? data
Is this an operational, administrative, monitoring, diagnostics, alerting, security, identity, or other support resource? operations

## Resource Placement Defaults

Some resource types support multiple purposes, but still need a default home for consistency purposes.

These defaults exist to reduce classification drift. Exceptions are allowed when there is a clear operational reason, but the default placement should be used unless the resource is clearly acting in another role.

### Default by function

- Virtual Network (`Microsoft.Network`): `network`
- Subnets (`Microsoft.Network`): `network`
- Network Security Groups (`Microsoft.Network`): `network`
- Route Tables (`Microsoft.Network`): `network`
- Private Endpoints (`Microsoft.Network`): `network`
- Private DNS zone / private DNS networking objects (`Microsoft.Network`): `network`
- Application Gateway (`Microsoft.Network`): `network-edge`
- WAF Policy for Application Gateway (`Microsoft.Network`): `network-edge`
- Load Balancer (`Microsoft.Network`): `network-edge`
- API Management (`Microsoft.ApiManagement`): `network-edge`
- App Service Environment (`Microsoft.Web`): `hosting`
- App Service Plan (`Microsoft.Web`): `hosting`
- App Service / Web App / API App (`Microsoft.Web`): `hosting`
- Log Analytics Workspace (`Microsoft.OperationalInsights`): `operations`
- Application Insights (`Microsoft.Insights`): `operations`
- Azure Monitor alerting / monitor resources (`Microsoft.Insights` / `Microsoft.Monitor` / `Microsoft.AlertsManagement`): `operations`
- Key Vault (`Microsoft.KeyVault`): `operations`
- Managed Identity (`Microsoft.ManagedIdentity`): `operations`
- Azure Automation / Runbooks (`Microsoft.Automation`): `operations`

### Default placement by broad resource type

These resource types are broad enough that placing them only by immediate use case can make the system harder to understand. They should have a stable default home.

- Storage Account (`Microsoft.Storage`): `data`
- Azure Database for PostgreSQL (`Microsoft.DBforPostgreSQL`): `data`
- Azure Cache for Redis (`Microsoft.Cache`): `data`
- Cosmos DB (`Microsoft.DocumentDB`): `data`
- Azure Data Factory (`Microsoft.DataFactory`): `data`
- Service Bus (`Microsoft.ServiceBus`): `hosting`
- Event Grid (`Microsoft.EventGrid`): `hosting`
- Azure Functions / Function App (`Microsoft.Web`): `hosting`
- Logic Apps (`Microsoft.Logic`): `hosting`

### Exceptions

Exceptions should be made only when the resource is clearly operating in another role.

Examples:
- Azure Functions / Function App (`Microsoft.Web`): use `operations` when the function is clearly an admin or support automation component rather than a workload runtime.
- Logic Apps (`Microsoft.Logic`): use `operations` when the logic app is clearly an admin or support automation component rather than workload orchestration.
- Azure Data Factory (`Microsoft.DataFactory`): reconsider placement only if it becomes a distinct operations capability with its own operational boundary.
- Service Bus (`Microsoft.ServiceBus`) / Event Grid (`Microsoft.EventGrid`): use `operations` only when they are clearly platform-admin or support messaging/eventing resources vs application runtime support.

The goal is to keep placement predictable for admins while still allowing deliberate exceptions when a resource is clearly serving another role.

Is this a distinct class of support resource important enough to deserve clearer visibility? Define it as <workload>-<subworkload> and add its evaluation criteria to the list above. Keep in mind microsofts recommendations for resource groups: the resources in the group should share a lifecycle management pattern that is distinct enough to justify a separate resource group. 

## Subnet Plan for a /21 block
## Note: Azure reserves 5 IPs in each subnet
Subnet Address	Range of Addresses	Usable IPs (Azure)	Hosts	Note Split/Join
10.0.0.0/23	10.0.0.0 - 10.0.1.255	10.0.0.4 - 10.0.1.254 App Service Hosting Environment Subnet	507		/23
10.0.2.0/24	10.0.2.0 - 10.0.2.255	10.0.2.4 - 10.0.2.254 App Gateway Subnet	251		/24
10.0.3.0/24	10.0.3.0 - 10.0.3.255	10.0.3.4 - 10.0.3.254 APIM Subnet	251		/24
10.0.4.0/24	10.0.4.0 - 10.0.4.255	10.0.4.4 - 10.0.4.254 Private Endpoint Subnet	251		/24
10.0.5.0/25	10.0.5.0 - 10.0.5.127	10.0.5.4 - 10.0.5.126 Function Apps Subnet	123		/25
10.0.5.128/26	10.0.5.128 - 10.0.5.191	10.0.5.132 - 10.0.5.190	59 Logic Apps Subnet		/26
10.0.5.192/27	10.0.5.192 - 10.0.5.223	10.0.5.196 - 10.0.5.222	27 PGSQL Subnet		/27
10.0.5.224/27	10.0.5.224 - 10.0.5.255	10.0.5.228 - 10.0.5.254	27		/27
10.0.6.0/24	10.0.6.0 - 10.0.6.255	10.0.6.4 - 10.0.6.254	251		/24
10.0.7.0/25	10.0.7.0 - 10.0.7.127	10.0.7.4 - 10.0.7.126	123		/25
10.0.7.128/26	10.0.7.128 - 10.0.7.191	10.0.7.132 - 10.0.7.190	59		/26
10.0.7.192/27	10.0.7.192 - 10.0.7.223	10.0.7.196 - 10.0.7.222	27		/27
10.0.7.224/27	10.0.7.224 - 10.0.7.255	10.0.7.228 - 10.0.7.254	27		/27

