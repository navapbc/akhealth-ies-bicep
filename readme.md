# README


TODO:
- Add staged/layered testing to test modules in layers, and respective layers by module, to enable

This folder contains a local and reorganized  version of the App Service LZA template set with only the dependencies it needs.
(from here https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/app-service-lza/hosting-environment)

Modules are organized by deployment area and deployment order to keep flow obvious and legibile:

- `01-network`
- `02-monitoring`
- `03-app-hosting`
- `04-application`
- `05-identity`
- `06-secrets`
- `07-edge`
- `shared`

Deployment Example:

az deployment sub create --location eastus --template-file ./main.bicep --parameters ./main.dev.bicepparam


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

example for this template set: kv-iep-wus-dev-001, app-iep-eus-dev-tasks-001

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

- `fdsecp` for `Microsoft.Cdn/profiles/securityPolicies`
- `fder` for `Microsoft.Cdn/profiles/afdEndpoints/routes`
- `fdog` for `Microsoft.Cdn/profiles/originGroups`
- `fdorg` for `Microsoft.Cdn/profiles/originGroups/origins`
- `fdrset` for `Microsoft.Cdn/profiles/ruleSets`
- `fdrul` for `Microsoft.Cdn/profiles/ruleSets/rules`
- `fdcdom` for `Microsoft.Cdn/profiles/customDomains`
- `fdsecr` for `Microsoft.Cdn/profiles/secrets`
