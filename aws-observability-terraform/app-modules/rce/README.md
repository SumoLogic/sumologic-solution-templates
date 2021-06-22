## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_rce_module"></a> [rce\_module](#module\_rce\_module) | SumoLogic/sumo-logic-integrations/sumologic//sumologic | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_id"></a> [access\_id](#input\_access\_id) | Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_access_key"></a> [access\_key](#input\_access\_key) | Sumo Logic Access Key. | `string` | n/a | yes |
| <a name="input_app_folder_id"></a> [app\_folder\_id](#input\_app\_folder\_id) | Please provide a folder ID where you would like the app to be installed. | `string` | `""` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Enter au, ca, de, eu, jp, us2, in, fed or us1. Visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sumologic_content"></a> [sumologic\_content](#output\_sumologic\_content) | This output contains rce Apps. |
