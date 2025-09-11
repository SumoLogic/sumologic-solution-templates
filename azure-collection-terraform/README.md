## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.19.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |
| <a name="requirement_sumologic"></a> [sumologic](#requirement\_sumologic) | >= 3.0.2 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.7.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.43.0 |
| <a name="provider_sumologic"></a> [sumologic](#provider\_sumologic) | 3.1.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_eventhub.eventhub_for_activity_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) | resource |
| [azurerm_eventhub.eventhubs_by_type_and_location](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) | resource |
| [azurerm_eventhub_namespace.activity_logs_namespace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) | resource |
| [azurerm_eventhub_namespace.namespaces_by_location](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) | resource |
| [azurerm_eventhub_namespace_authorization_rule.activity_logs_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace_authorization_rule) | resource |
| [azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace_authorization_rule) | resource |
| [azurerm_monitor_diagnostic_setting.activity_logs_to_event_hub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.diagnostic_setting_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [sumologic_azure_event_hub_log_source.sumo_activity_log_source](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/azure_event_hub_log_source) | resource |
| [sumologic_azure_event_hub_log_source.sumo_azure_event_hub_log_source](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/azure_event_hub_log_source) | resource |
| [sumologic_azure_metrics_source.terraform_azure_metrics_source](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/azure_metrics_source) | resource |
| [sumologic_collector.sumo_collector](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/collector) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_monitor_diagnostic_categories.all_categories](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/monitor_diagnostic_categories) | data source |
| [azurerm_resources.all_target_resources](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resources) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_activity_log_export_category"></a> [activity\_log\_export\_category](#input\_activity\_log\_export\_category) | Activity Log Export Category | `string` | `"azure/activity-logs"` | no |
| <a name="input_activity_log_export_name"></a> [activity\_log\_export\_name](#input\_activity\_log\_export\_name) | Activity Log Export Name | `string` | `"activity_logs_export"` | no |
| <a name="input_apps_names_to_install"></a> [apps\_names\_to\_install](#input\_apps\_names\_to\_install) | Provide comma separated list of applications for which sumologic resources (collection and apps) needs to be created. Allowed values are "Azure Web Apps,Azure Service Bus,Azure Storage,Azure Load Balancer,Azure CosmosDB". | `string` | `"Azure Service Bus,Azure Key Vault,Azure Storage"` | no |
| <a name="input_azure_client_id"></a> [azure\_client\_id](#input\_azure\_client\_id) | The client id | `string` | `""` | no |
| <a name="input_azure_client_secret"></a> [azure\_client\_secret](#input\_azure\_client\_secret) | The client secret | `string` | `""` | no |
| <a name="input_azure_subscription_id"></a> [azure\_subscription\_id](#input\_azure\_subscription\_id) | The subscription id where your azure resources are present | `string` | `""` | no |
| <a name="input_azure_tenant_id"></a> [azure\_tenant\_id](#input\_azure\_tenant\_id) | The Tenant Id | `string` | `""` | no |
| <a name="input_enable_activity_logs"></a> [enable\_activity\_logs](#input\_enable\_activity\_logs) | Set to true to enable subscription-level activity log export. | `bool` | n/a | yes |
| <a name="input_eventhub_name"></a> [eventhub\_name](#input\_eventhub\_name) | The name of the Event Hub. | `string` | `"SUMO-267667-Hub-Logs-Collector"` | no |
| <a name="input_eventhub_namespace_name"></a> [eventhub\_namespace\_name](#input\_eventhub\_namespace\_name) | The name of the Event Hub Namespace. | `string` | `"SUMO-267667-Hub"` | no |
| <a name="input_index_value"></a> [index\_value](#input\_index\_value) | The \_index if the collection is configured with custom partition. | `string` | `"sumologic_default"` | no |
| <a name="input_location"></a> [location](#input\_location) | The location for the resources. | `string` | `"East US"` | no |
| <a name="input_policy_name"></a> [policy\_name](#input\_policy\_name) | The name of the Shared Access Policy. | `string` | `"SumoCollectionPolicy"` | no |
| <a name="input_required_resource_tags"></a> [required\_resource\_tags](#input\_required\_resource\_tags) | A map of tags to filter Azure resources by. | `map(string)` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the Resource Group. | `string` | `"SUMO-267667"` | no |
| <a name="input_sumo_collector_name"></a> [sumo\_collector\_name](#input\_sumo\_collector\_name) | Sumologic collector name | `string` | `"SUMO-267667-Collector"` | no |
| <a name="input_sumologic_access_id"></a> [sumologic\_access\_id](#input\_sumologic\_access\_id) | Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | `""` | no |
| <a name="input_sumologic_access_key"></a> [sumologic\_access\_key](#input\_sumologic\_access\_key) | Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | `""` | no |
| <a name="input_sumologic_environment"></a> [sumologic\_environment](#input\_sumologic\_environment) | Enter au, ca, de, eu, jp, us2, in, kr, fed or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security | `string` | `"us1"` | no |
| <a name="input_target_resource_types"></a> [target\_resource\_types](#input\_target\_resource\_types) | List of Azure resource types whose logs and metrics you want to collect. | `list(string)` | n/a | yes |
| <a name="input_throughput_units"></a> [throughput\_units](#input\_throughput\_units) | The number of throughput units for the Event Hub Namespace. | `number` | `5` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_activity_logs_policy_key"></a> [activity\_logs\_policy\_key](#output\_activity\_logs\_policy\_key) | The primary key for the activity logs authorization rule. |
| <a name="output_eventhub_for_activity_logs_id"></a> [eventhub\_for\_activity\_logs\_id](#output\_eventhub\_for\_activity\_logs\_id) | The ID of the Event Hub for activity logs. |
| <a name="output_eventhub_namespaces"></a> [eventhub\_namespaces](#output\_eventhub\_namespaces) | A map of Event Hub namespace names by location. |
| <a name="output_eventhub_namespaces_ids"></a> [eventhub\_namespaces\_ids](#output\_eventhub\_namespaces\_ids) | A map of Event Hub namespace IDs by location. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | The name of the main resource group. |
| <a name="output_sumo_activity_log_source_id"></a> [sumo\_activity\_log\_source\_id](#output\_sumo\_activity\_log\_source\_id) | The ID of the Sumo Logic activity log source. |
| <a name="output_sumo_collection_policy_keys"></a> [sumo\_collection\_policy\_keys](#output\_sumo\_collection\_policy\_keys) | A map of shared access policy primary keys by location. |
| <a name="output_sumo_collector_id"></a> [sumo\_collector\_id](#output\_sumo\_collector\_id) | The ID of the Sumo Logic Hosted Collector. |
| <a name="output_sumo_eventhub_log_sources"></a> [sumo\_eventhub\_log\_sources](#output\_sumo\_eventhub\_log\_sources) | A map of Sumo Logic Event Hub log source IDs by resource type and location. |
| <a name="output_sumo_metrics_sources"></a> [sumo\_metrics\_sources](#output\_sumo\_metrics\_sources) | A map of Sumo Logic metrics source IDs by namespace. |