## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ec2metrics_module"></a> [ec2metrics\_module](#module\_ec2metrics\_module) | SumoLogic/sumo-logic-integrations/sumologic//sumologic | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_id"></a> [access\_id](#input\_access\_id) | Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_access_key"></a> [access\_key](#input\_access\_key) | Sumo Logic Access Key. | `string` | n/a | yes |
| <a name="input_app_folder_id"></a> [app\_folder\_id](#input\_app\_folder\_id) | Please provide a folder ID where you would like the app to be installed. | `string` | `""` | no |
| <a name="input_connection_notifications"></a> [connection\_notifications](#input\_connection\_notifications) | Connection Notifications to be sent by the alert. | <pre>list(object(<br>    {<br>      connection_type       = string,<br>      connection_id         = string,<br>      payload_override      = string,<br>      run_for_trigger_types = list(string)<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_email_notifications"></a> [email\_notifications](#input\_email\_notifications) | Email Notifications to be sent by the alert. | <pre>list(object(<br>    {<br>      connection_type       = string,<br>      recipients            = list(string),<br>      subject               = string,<br>      time_zone             = string,<br>      message_body          = string,<br>      run_for_trigger_types = list(string)<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Enter au, ca, de, eu, fed, in, jp, kr, us1 or us2. Visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security | `string` | n/a | yes |
| <a name="input_group_notifications"></a> [group\_notifications](#input\_group\_notifications) | Whether or not to group notifications for individual items that meet the trigger condition. Defaults to true. | `bool` | `true` | no |
| <a name="input_json_file_directory_path"></a> [json\_file\_directory\_path](#input\_json\_file\_directory\_path) | Directory path where all the JSONs are present. | `string` | n/a | yes |
| <a name="input_monitor_folder_id"></a> [monitor\_folder\_id](#input\_monitor\_folder\_id) | Please provide a folder ID where you would like the monitors to be installed. | `string` | `""` | no |
| <a name="input_monitors_disabled"></a> [monitors\_disabled](#input\_monitors\_disabled) | Whether the monitors are enabled or not? | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sumologic_content"></a> [sumologic\_content](#output\_sumologic\_content) | This output contains EC2 Metrics App. |
| <a name="output_sumologic_field"></a> [sumologic\_field](#output\_sumologic\_field) | This output contains fields required for EC2 Metrics app. |
