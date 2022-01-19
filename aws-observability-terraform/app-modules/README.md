## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 2.1 |
| <a name="requirement_sumologic"></a> [sumologic](#requirement\_sumologic) | >= 2.6.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_sumologic"></a> [sumologic](#provider\_sumologic) | >= 2.6.2 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb_app"></a> [alb\_app](#module\_alb\_app) | ./alb | n/a |
| <a name="module_apigateway_app"></a> [apigateway\_app](#module\_apigateway\_app) | ./apigateway | n/a |
| <a name="module_dynamodb_app"></a> [dynamodb\_app](#module\_dynamodb\_app) | ./dynamodb | n/a |
| <a name="module_ec2metrics_app"></a> [ec2metrics\_app](#module\_ec2metrics\_app) | ./ec2metrics | n/a |
| <a name="module_ecs_app"></a> [ecs\_app](#module\_ecs\_app) | ./ecs | n/a |
| <a name="module_elasticache_app"></a> [elasticache\_app](#module\_elasticache\_app) | ./elasticache | n/a |
| <a name="module_elb_app"></a> [elb\_app](#module\_elb\_app) | ./elb | n/a |
| <a name="module_lambda_app"></a> [lambda\_app](#module\_lambda\_app) | ./lambda | n/a |
| <a name="module_nlb_app"></a> [nlb\_app](#module\_nlb\_app) | ./nlb | n/a |
| <a name="module_overview_app"></a> [overview\_app](#module\_overview\_app) | ./overview | n/a |
| <a name="module_rce_app"></a> [rce\_app](#module\_rce\_app) | ./rce | n/a |
| <a name="module_rds_app"></a> [rds\_app](#module\_rds\_app) | ./rds | n/a |

## Resources

| Name | Type |
|------|------|
| [sumologic_folder.apps_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/folder) | resource |
| [sumologic_hierarchy.awso_hierarchy](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/hierarchy) | resource |
| [sumologic_monitor_folder.monitor_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/monitor_folder) | resource |
| [time_sleep.wait_for_5_minutes](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [sumologic_personal_folder.personalFolder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/data-sources/personal_folder) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_id"></a> [access\_id](#input\_access\_id) | Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_access_key"></a> [access\_key](#input\_access\_key) | Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_alb_monitors_disabled"></a> [alb\_monitors\_disabled](#input\_alb\_monitors\_disabled) | Indicates if the ALB Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_apigateway_monitors_disabled"></a> [apigateway\_monitors\_disabled](#input\_apigateway\_monitors\_disabled) | Indicates if the API Gateway Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_apps_folder_name"></a> [apps\_folder\_name](#input\_apps\_folder\_name) | Provide a folder name where all the apps will be installed under the Personal folder of the user whose access keys you have entered.<br>            Default value will be: AWS Observability Apps | `string` | `"AWS Observability Apps"` | no |
| <a name="input_connection_notifications"></a> [connection\_notifications](#input\_connection\_notifications) | Connection Notifications to be sent by the alert. | <pre>list(object(<br>    {<br>      connection_type       = string,<br>      connection_id         = string,<br>      payload_override      = string,<br>      run_for_trigger_types = list(string)<br>    }<br>  ))</pre> | `[]` | no |
| <a name="input_dynamodb_monitors_disabled"></a> [dynamodb\_monitors\_disabled](#input\_dynamodb\_monitors\_disabled) | Indicates if DynamoDB Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_ec2metrics_monitors_disabled"></a> [ec2metrics\_monitors\_disabled](#input\_ec2metrics\_monitors\_disabled) | Indicates if EC2 Metrics Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_ecs_monitors_disabled"></a> [ecs\_monitors\_disabled](#input\_ecs\_monitors\_disabled) | Indicates if ECS Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_elasticache_monitors_disabled"></a> [elasticache\_monitors\_disabled](#input\_elasticache\_monitors\_disabled) | Indicates if Elasticache Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_elb_monitors_disabled"></a> [elb\_monitors\_disabled](#input\_elb\_monitors\_disabled) | Indicates if the ALB Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_email_notifications"></a> [email\_notifications](#input\_email\_notifications) | Email Notifications to be sent by the alert. | <pre>list(object(<br>    {<br>      connection_type       = string,<br>      recipients            = list(string),<br>      subject               = string,<br>      time_zone             = string,<br>      message_body          = string,<br>      run_for_trigger_types = list(string)<br>    }<br>  ))</pre> | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Enter au, ca, de, eu, jp, us2, in, fed or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security | `string` | n/a | yes |
| <a name="input_group_notifications"></a> [group\_notifications](#input\_group\_notifications) | Whether or not to group notifications for individual items that meet the trigger condition. Defaults to true. | `bool` | `true` | no |
| <a name="input_json_file_directory_path"></a> [json\_file\_directory\_path](#input\_json\_file\_directory\_path) | Directory path where all the JSONs are present. | `string` | n/a | yes |
| <a name="input_lambda_monitors_disabled"></a> [lambda\_monitors\_disabled](#input\_lambda\_monitors\_disabled) | Indicates if Lambda Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_monitors_folder_name"></a> [monitors\_folder\_name](#input\_monitors\_folder\_name) | Provide a folder name where all the monitors will be installed under Monitor Folder.<br>            Default value will be: AWS Observability Monitors | `string` | `"AWS Observability Monitors"` | no |
| <a name="input_nlb_monitors_disabled"></a> [nlb\_monitors\_disabled](#input\_nlb\_monitors\_disabled) | Indicates if NLB Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_parent_folder_id"></a> [parent\_folder\_id](#input\_parent\_folder\_id) | Please provide a folder ID where you would like the apps to be installed. A folder with name provided in "apps\_folder\_name" will be created. If folder ID is empty, apps will be installed in Personal folder. | `string` | `""` | no |
| <a name="input_rds_monitors_disabled"></a> [rds\_monitors\_disabled](#input\_rds\_monitors\_disabled) | Indicates if RDS Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sumologic_content_alb"></a> [sumologic\_content\_alb](#output\_sumologic\_content\_alb) | This output contains alb App. |
| <a name="output_sumologic_content_apigateway"></a> [sumologic\_content\_apigateway](#output\_sumologic\_content\_apigateway) | This output contains apigateway App. |
| <a name="output_sumologic_content_dynamodb"></a> [sumologic\_content\_dynamodb](#output\_sumologic\_content\_dynamodb) | This output contains dynamodb App. |
| <a name="output_sumologic_content_ec2metrics"></a> [sumologic\_content\_ec2metrics](#output\_sumologic\_content\_ec2metrics) | This output contains EC2 Metrics App. |
| <a name="output_sumologic_content_ecs"></a> [sumologic\_content\_ecs](#output\_sumologic\_content\_ecs) | This output contains ecs App. |
| <a name="output_sumologic_content_elasticache"></a> [sumologic\_content\_elasticache](#output\_sumologic\_content\_elasticache) | This output contains elasticache App. |
| <a name="output_sumologic_content_elb"></a> [sumologic\_content\_elb](#output\_sumologic\_content\_elb) | This output contains classic elb App. |
| <a name="output_sumologic_content_lambda"></a> [sumologic\_content\_lambda](#output\_sumologic\_content\_lambda) | This output contains lambda App. |
| <a name="output_sumologic_content_nlb"></a> [sumologic\_content\_nlb](#output\_sumologic\_content\_nlb) | This output contains nlb App. |
| <a name="output_sumologic_content_overview"></a> [sumologic\_content\_overview](#output\_sumologic\_content\_overview) | This output contains overview App. |
| <a name="output_sumologic_content_rce"></a> [sumologic\_content\_rce](#output\_sumologic\_content\_rce) | This output contains rce Apps. |
| <a name="output_sumologic_content_rds"></a> [sumologic\_content\_rds](#output\_sumologic\_content\_rds) | This output contains rds App. |
| <a name="output_sumologic_field_alb"></a> [sumologic\_field\_alb](#output\_sumologic\_field\_alb) | This output contains fields required for alb app. |
| <a name="output_sumologic_field_apigateway"></a> [sumologic\_field\_apigateway](#output\_sumologic\_field\_apigateway) | This output contains fields required for apigateway app. |
| <a name="output_sumologic_field_dynamodb"></a> [sumologic\_field\_dynamodb](#output\_sumologic\_field\_dynamodb) | This output contains fields required for dynamodb app. |
| <a name="output_sumologic_field_ec2metrics"></a> [sumologic\_field\_ec2metrics](#output\_sumologic\_field\_ec2metrics) | This output contains fields required for EC2 Metrics app. |
| <a name="output_sumologic_field_ecs"></a> [sumologic\_field\_ecs](#output\_sumologic\_field\_ecs) | This output contains fields required for ecs app. |
| <a name="output_sumologic_field_elasticache"></a> [sumologic\_field\_elasticache](#output\_sumologic\_field\_elasticache) | This output contains fields required for elasticache app. |
| <a name="output_sumologic_field_elb"></a> [sumologic\_field\_elb](#output\_sumologic\_field\_elb) | This output contains fields required for classic elb app. |
| <a name="output_sumologic_field_extraction_rule_alb"></a> [sumologic\_field\_extraction\_rule\_alb](#output\_sumologic\_field\_extraction\_rule\_alb) | This output contains Field Extraction rules required for alb app. |
| <a name="output_sumologic_field_extraction_rule_apigateway"></a> [sumologic\_field\_extraction\_rule\_apigateway](#output\_sumologic\_field\_extraction\_rule\_apigateway) | This output contains Field Extraction rules required for apigateway app. |
| <a name="output_sumologic_field_extraction_rule_dynamodb"></a> [sumologic\_field\_extraction\_rule\_dynamodb](#output\_sumologic\_field\_extraction\_rule\_dynamodb) | This output contains Field Extraction rules required for dynamodb app. |
| <a name="output_sumologic_field_extraction_rule_ecs"></a> [sumologic\_field\_extraction\_rule\_ecs](#output\_sumologic\_field\_extraction\_rule\_ecs) | This output contains Field Extraction rules required for ecs app. |
| <a name="output_sumologic_field_extraction_rule_elasticache"></a> [sumologic\_field\_extraction\_rule\_elasticache](#output\_sumologic\_field\_extraction\_rule\_elasticache) | This output contains Field Extraction rules required for elasticache app. |
| <a name="output_sumologic_field_extraction_rule_elb"></a> [sumologic\_field\_extraction\_rule\_elb](#output\_sumologic\_field\_extraction\_rule\_elb) | This output contains Field Extraction rules required for classic elb app. |
| <a name="output_sumologic_field_extraction_rule_lambda"></a> [sumologic\_field\_extraction\_rule\_lambda](#output\_sumologic\_field\_extraction\_rule\_lambda) | This output contains Field Extraction rules required for lambda app. |
| <a name="output_sumologic_field_extraction_rule_rds"></a> [sumologic\_field\_extraction\_rule\_rds](#output\_sumologic\_field\_extraction\_rule\_rds) | This output contains Field Extraction rules required for rds app. |
| <a name="output_sumologic_field_lambda"></a> [sumologic\_field\_lambda](#output\_sumologic\_field\_lambda) | This output contains fields required for lambda app. |
| <a name="output_sumologic_field_nlb"></a> [sumologic\_field\_nlb](#output\_sumologic\_field\_nlb) | This output contains fields required for nlb app. |
| <a name="output_sumologic_field_overview"></a> [sumologic\_field\_overview](#output\_sumologic\_field\_overview) | This output contains fields required for overview app. |
| <a name="output_sumologic_field_rds"></a> [sumologic\_field\_rds](#output\_sumologic\_field\_rds) | This output contains fields required for rds app. |
| <a name="output_sumologic_metric_rules_nlb"></a> [sumologic\_metric\_rules\_nlb](#output\_sumologic\_metric\_rules\_nlb) | This output contains metric rules required for nlb app. |
| <a name="output_sumologic_metric_rules_rds"></a> [sumologic\_metric\_rules\_rds](#output\_sumologic\_metric\_rules\_rds) | This output contains metric rules required for rds app. |
