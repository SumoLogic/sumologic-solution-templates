## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.42.0, < 4.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |
| <a name="requirement_sumologic"></a> [sumologic](#requirement\_sumologic) | >= 2.13.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.7.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_sumologic"></a> [sumologic](#provider\_sumologic) | 2.16.2 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.7.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_sumo-module"></a> [sumo-module](#module\_sumo-module) | ../../app-modules | n/a |

## Resources

| Name | Type |
|------|------|
| [sumologic_field.account](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.accountid](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.apiname](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.cacheclusterid](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.clustername](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.dbclusteridentifier](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.dbidentifier](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.dbinstanceidentifier](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.functionname](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.instanceid](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.loadbalancer](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.loadbalancername](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.namespace](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.networkloadbalancer](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.region](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.tablename](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.topicname](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityAlbAccessLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityApiGatewayCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityDynamoDBCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityEC2CloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityECSCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityElastiCacheCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityElbAccessLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityFieldExtractionRule](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityGenericCloudWatchLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityLambdaCloudWatchLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityRdsCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilitySNSCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilitySQSCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [time_sleep.wait_for_10_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_monitors"></a> [alb\_monitors](#input\_alb\_monitors) | Indicates if the ALB Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_apps_folder"></a> [apps\_folder](#input\_apps\_folder) | Provide a folder name where all the apps will be installed under the Personal folder of the user whose access keys you have entered.<br>            Default value will be: AWS Observability Apps | `string` | `"AWS Observability Apps"` | no |
| <a name="input_aws_account_alias"></a> [aws\_account\_alias](#input\_aws\_account\_alias) | Provide the Name/Alias for the AWS environment from which you are collecting data. This name will appear in the Sumo Logic Explorer View, metrics, and logs.<br>            If you are going to deploy the solution in multiple AWS accounts then this value has to be overidden at main.tf file.<br>            Do not include special characters in the alias. | `string` | n/a | yes |
| <a name="input_ec2metrics_monitors"></a> [ec2metrics\_monitors](#input\_ec2metrics\_monitors) | Indicates if EC2 Metrics Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_ecs_monitors"></a> [ecs\_monitors](#input\_ecs\_monitors) | Indicates if ECS Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_elasticache_monitors"></a> [elasticache\_monitors](#input\_elasticache\_monitors) | Indicates if Elasticache Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_monitors_folder"></a> [monitors\_folder](#input\_monitors\_folder) | Provide a folder name where all the monitors will be installed under Monitor Folder.<br>            Default value will be: AWS Observability Monitors | `string` | `"AWS Observability Monitors"` | no |
| <a name="input_sumo_api_endpoint"></a> [sumo\_api\_endpoint](#input\_sumo\_api\_endpoint) | n/a | `string` | n/a | yes |
| <a name="input_sumologic_access_id"></a> [sumologic\_access\_id](#input\_sumologic\_access\_id) | Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_sumologic_access_key"></a> [sumologic\_access\_key](#input\_sumologic\_access\_key) | Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_sumologic_environment"></a> [sumologic\_environment](#input\_sumologic\_environment) | Enter au, ca, de, eu, jp, us2, in, fed or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security | `string` | n/a | yes |
| <a name="input_sumologic_folder_installation_location"></a> [sumologic\_folder\_installation\_location](#input\_sumologic\_folder\_installation\_location) | Indicates where to install the app folder. Enter "Personal Folder" for installing in "Personal" folder and "Admin Recommended Folder" for installing in "Admin Recommended" folder. | `string` | `"Personal Folder"` | no |
| <a name="input_sumologic_folder_share_with_org"></a> [sumologic\_folder\_share\_with\_org](#input\_sumologic\_folder\_share\_with\_org) | Indicates if AWS Observability folder should be shared (view access) with entire organization. true to enable; false to disable. | `bool` | `true` | no |
| <a name="input_sumologic_organization_id"></a> [sumologic\_organization\_id](#input\_sumologic\_organization\_id) | You can find your org on the Preferences page in the Sumo Logic UI. For more information, see the Preferences Page topic. Your org ID will be used to configure the IAM Role for Sumo Logic AWS Sources."<br>            For more details, visit https://help.sumologic.com/01Start-Here/05Customize-Your-Sumo-Logic-Experience/Preferences-Page | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_apps_folder_id"></a> [alb\_apps\_folder\_id](#output\_alb\_apps\_folder\_id) | This output contains sumologic ALB apps folder. |
| <a name="output_apigateway_apps_folder_id"></a> [apigateway\_apps\_folder\_id](#output\_apigateway\_apps\_folder\_id) | This output contains sumologic API Gateway apps folder. |
| <a name="output_apps_folder_id"></a> [apps\_folder\_id](#output\_apps\_folder\_id) | This output contains sumologic apps folder. |
| <a name="output_clb_apps_folder_id"></a> [clb\_apps\_folder\_id](#output\_clb\_apps\_folder\_id) | This output contains sumologic CLB apps folder. |
| <a name="output_dynamodb_apps_folder_id"></a> [dynamodb\_apps\_folder\_id](#output\_dynamodb\_apps\_folder\_id) | This output contains sumologic DynamoDB apps folder. |
| <a name="output_ec2CWmetrics_apps_folder_id"></a> [ec2CWmetrics\_apps\_folder\_id](#output\_ec2CWmetrics\_apps\_folder\_id) | This output contains sumologic EC2 CW metrics apps folder. |
| <a name="output_ec2metrics_apps_folder_id"></a> [ec2metrics\_apps\_folder\_id](#output\_ec2metrics\_apps\_folder\_id) | This output contains sumologic EC2 host metrics apps folder. |
| <a name="output_ecs_apps_folder_id"></a> [ecs\_apps\_folder\_id](#output\_ecs\_apps\_folder\_id) | This output contains sumologic ECS apps folder. |
| <a name="output_elasticache_apps_folder_id"></a> [elasticache\_apps\_folder\_id](#output\_elasticache\_apps\_folder\_id) | This output contains sumologic ElastiCacheApp apps folder. |
| <a name="output_hierarchy_id"></a> [hierarchy\_id](#output\_hierarchy\_id) | This output contains sumologic hierarchy id. |
| <a name="output_lambda_apps_folder_id"></a> [lambda\_apps\_folder\_id](#output\_lambda\_apps\_folder\_id) | This output contains sumologic Lambda apps folder. |
| <a name="output_monitors_folder_id"></a> [monitors\_folder\_id](#output\_monitors\_folder\_id) | This output contains sumologic monitors folder. |
| <a name="output_nlb_apps_folder_id"></a> [nlb\_apps\_folder\_id](#output\_nlb\_apps\_folder\_id) | This output contains sumologic NLB apps folder. |
| <a name="output_overview_apps_folder_id"></a> [overview\_apps\_folder\_id](#output\_overview\_apps\_folder\_id) | This output contains sumologic Overview apps folder. |
| <a name="output_rds_apps_folder_id"></a> [rds\_apps\_folder\_id](#output\_rds\_apps\_folder\_id) | This output contains sumologic RDS apps folder. |
| <a name="output_sns_apps_folder_id"></a> [sns\_apps\_folder\_id](#output\_sns\_apps\_folder\_id) | This output contains sumologic SNS apps folder. |
| <a name="output_sqs_apps_folder_id"></a> [sqs\_apps\_folder\_id](#output\_sqs\_apps\_folder\_id) | This output contains sumologic SQS apps folder. |
| <a name="output_sumologic_field_account"></a> [sumologic\_field\_account](#output\_sumologic\_field\_account) | This output contains sumologic Account field id. |
| <a name="output_sumologic_field_accountid"></a> [sumologic\_field\_accountid](#output\_sumologic\_field\_accountid) | This output contains sumologic accountid field id. |
| <a name="output_sumologic_field_apiname"></a> [sumologic\_field\_apiname](#output\_sumologic\_field\_apiname) | This output contains sumologic apiname field id. |
| <a name="output_sumologic_field_cacheclusterid"></a> [sumologic\_field\_cacheclusterid](#output\_sumologic\_field\_cacheclusterid) | This output contains sumologic cacheclusterid field id. |
| <a name="output_sumologic_field_clustername"></a> [sumologic\_field\_clustername](#output\_sumologic\_field\_clustername) | This output contains sumologic clustername field id. |
| <a name="output_sumologic_field_dbclusteridentifier"></a> [sumologic\_field\_dbclusteridentifier](#output\_sumologic\_field\_dbclusteridentifier) | This output contains sumologic dbclusteridentifier field id. |
| <a name="output_sumologic_field_dbidentifier"></a> [sumologic\_field\_dbidentifier](#output\_sumologic\_field\_dbidentifier) | This output contains sumologic dbidentifier field id. |
| <a name="output_sumologic_field_dbinstanceidentifier"></a> [sumologic\_field\_dbinstanceidentifier](#output\_sumologic\_field\_dbinstanceidentifier) | This output contains sumologic dbinstanceidentifier field id. |
| <a name="output_sumologic_field_extraction_rule_alb"></a> [sumologic\_field\_extraction\_rule\_alb](#output\_sumologic\_field\_extraction\_rule\_alb) | This output contains sumologic ALB field extraction rule id. |
| <a name="output_sumologic_field_extraction_rule_apigateway"></a> [sumologic\_field\_extraction\_rule\_apigateway](#output\_sumologic\_field\_extraction\_rule\_apigateway) | This output contains sumologic API gateway field extraction rule id. |
| <a name="output_sumologic_field_extraction_rule_cw"></a> [sumologic\_field\_extraction\_rule\_cw](#output\_sumologic\_field\_extraction\_rule\_cw) | This output contains sumologic CloudWatch logs generic field extraction rule id. |
| <a name="output_sumologic_field_extraction_rule_dynamodb"></a> [sumologic\_field\_extraction\_rule\_dynamodb](#output\_sumologic\_field\_extraction\_rule\_dynamodb) | This output contains sumologic dynamoDB field extraction rule id. |
| <a name="output_sumologic_field_extraction_rule_ec2metrics"></a> [sumologic\_field\_extraction\_rule\_ec2metrics](#output\_sumologic\_field\_extraction\_rule\_ec2metrics) | This output contains sumologic EC2 field extraction rule id. |
| <a name="output_sumologic_field_extraction_rule_ecs"></a> [sumologic\_field\_extraction\_rule\_ecs](#output\_sumologic\_field\_extraction\_rule\_ecs) | This output contains sumologic ECS field extraction rule id. |
| <a name="output_sumologic_field_extraction_rule_elasticache"></a> [sumologic\_field\_extraction\_rule\_elasticache](#output\_sumologic\_field\_extraction\_rule\_elasticache) | This output contains sumologic Elasticache field extraction rule id. |
| <a name="output_sumologic_field_extraction_rule_elb"></a> [sumologic\_field\_extraction\_rule\_elb](#output\_sumologic\_field\_extraction\_rule\_elb) | This output contains sumologic CLB field extraction rule id. |
| <a name="output_sumologic_field_extraction_rule_lambda"></a> [sumologic\_field\_extraction\_rule\_lambda](#output\_sumologic\_field\_extraction\_rule\_lambda) | This output contains sumologic Lambda cloudtrail field extraction rule id. |
| <a name="output_sumologic_field_extraction_rule_lambda_cw"></a> [sumologic\_field\_extraction\_rule\_lambda\_cw](#output\_sumologic\_field\_extraction\_rule\_lambda\_cw) | This output contains sumologic Lambda cloudwatch field extraction rule id. |
| <a name="output_sumologic_field_extraction_rule_rds"></a> [sumologic\_field\_extraction\_rule\_rds](#output\_sumologic\_field\_extraction\_rule\_rds) | This output contains sumologic RDS field extraction rule id. |
| <a name="output_sumologic_field_extraction_rule_sns"></a> [sumologic\_field\_extraction\_rule\_sns](#output\_sumologic\_field\_extraction\_rule\_sns) | This output contains sumologic SNS field extraction rule id. |
| <a name="output_sumologic_field_extraction_rule_sqs"></a> [sumologic\_field\_extraction\_rule\_sqs](#output\_sumologic\_field\_extraction\_rule\_sqs) | This output contains sumologic SQS field extraction rule id. |
| <a name="output_sumologic_field_functionname"></a> [sumologic\_field\_functionname](#output\_sumologic\_field\_functionname) | This output contains sumologic functionname field id. |
| <a name="output_sumologic_field_instanceid"></a> [sumologic\_field\_instanceid](#output\_sumologic\_field\_instanceid) | This output contains sumologic instanceid field id. |
| <a name="output_sumologic_field_loadbalancer"></a> [sumologic\_field\_loadbalancer](#output\_sumologic\_field\_loadbalancer) | This output contains sumologic loadbalancer field id. |
| <a name="output_sumologic_field_loadbalancername"></a> [sumologic\_field\_loadbalancername](#output\_sumologic\_field\_loadbalancername) | This output contains sumologic loadbalancername field id. |
| <a name="output_sumologic_field_namespace"></a> [sumologic\_field\_namespace](#output\_sumologic\_field\_namespace) | This output contains sumologic namespace field id. |
| <a name="output_sumologic_field_networkloadbalancer"></a> [sumologic\_field\_networkloadbalancer](#output\_sumologic\_field\_networkloadbalancer) | This output contains sumologic networkloadbalancer field id. |
| <a name="output_sumologic_field_region"></a> [sumologic\_field\_region](#output\_sumologic\_field\_region) | This output contains sumologic Region field id. |
| <a name="output_sumologic_field_tablename"></a> [sumologic\_field\_tablename](#output\_sumologic\_field\_tablename) | This output contains sumologic tablename field id. |
| <a name="output_sumologic_field_topicname"></a> [sumologic\_field\_topicname](#output\_sumologic\_field\_topicname) | This output contains sumologic topicname field id. |
| <a name="output_sumologic_metric_rule_nlb"></a> [sumologic\_metric\_rule\_nlb](#output\_sumologic\_metric\_rule\_nlb) | This output contains sumologic NLB metric rule name. |
| <a name="output_sumologic_metric_rule_rds_cluster"></a> [sumologic\_metric\_rule\_rds\_cluster](#output\_sumologic\_metric\_rule\_rds\_cluster) | This output contains sumologic RDS cluster metric rule name. |
| <a name="output_sumologic_metric_rule_rds_instance"></a> [sumologic\_metric\_rule\_rds\_instance](#output\_sumologic\_metric\_rule\_rds\_instance) | This output contains sumologic RDS instance metric rule name. |
