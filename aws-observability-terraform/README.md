## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.16.2, < 6.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |
| <a name="requirement_sumologic"></a> [sumologic](#requirement\_sumologic) | >= 2.31.3, < 3.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.11.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_sumologic"></a> [sumologic](#provider\_sumologic) | 2.31.5 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.12.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_collection-module"></a> [collection-module](#module\_collection-module) | ./source-module | n/a |
| <a name="module_sumo-module"></a> [sumo-module](#module\_sumo-module) | ./app-modules | n/a |

## Resources

| Name | Type |
|------|------|
| [sumologic_field.account](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.accountid](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.apiid](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
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
| [sumologic_field.queuename](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.region](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.tablename](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.topicname](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityALBCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityAlbAccessLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityApiGatewayAccessLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityApiGatewayCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityCLBCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityDynamoDBCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityEC2CloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityECSCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityElastiCacheCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityElbAccessLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityFieldExtractionRule](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityGenericCloudWatchLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityLambdaCloudWatchLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityNLBCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityRdsCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilitySNSCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilitySQSCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [time_sleep.wait_for_10_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_alias"></a> [aws\_account\_alias](#input\_aws\_account\_alias) | Provide the Name/Alias for the AWS environment from which you are collecting data. This name will appear in the Sumo Logic Explorer View, metrics, and logs.<br/>            If you are going to deploy the solution in multiple AWS accounts then this value has to be overidden at main.tf file.<br/>            Do not include special characters in the alias. | `string` | n/a | yes |
| <a name="input_sumologic_access_id"></a> [sumologic\_access\_id](#input\_sumologic\_access\_id) | Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_sumologic_access_key"></a> [sumologic\_access\_key](#input\_sumologic\_access\_key) | Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_sumologic_environment"></a> [sumologic\_environment](#input\_sumologic\_environment) | Enter au, ca, de, eu, fed, in, jp, kr, us1 or us2. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security | `string` | n/a | yes |
| <a name="input_sumologic_folder_installation_location"></a> [sumologic\_folder\_installation\_location](#input\_sumologic\_folder\_installation\_location) | Indicates where to install the app folder. Enter "Personal Folder" for installing in "Personal" folder and "Admin Recommended Folder" for installing in "Admin Recommended" folder. | `string` | `"Personal Folder"` | no |
| <a name="input_sumologic_folder_share_with_org"></a> [sumologic\_folder\_share\_with\_org](#input\_sumologic\_folder\_share\_with\_org) | Indicates if AWS Observability folder should be shared (view access) with entire organization. true to enable; false to disable. | `bool` | `true` | no |
| <a name="input_sumologic_organization_id"></a> [sumologic\_organization\_id](#input\_sumologic\_organization\_id) | You can find your org on the Preferences page in the Sumo Logic UI. For more information, see the Preferences Page topic. Your org ID will be used to configure the IAM Role for Sumo Logic AWS Sources."<br/>            For more details, visit https://help.sumologic.com/01Start-Here/05Customize-Your-Sumo-Logic-Experience/Preferences-Page | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_Apps"></a> [Apps](#output\_Apps) | All outputs related to apps. |
| <a name="output_Collection"></a> [Collection](#output\_Collection) | All outputs related to collection and sources. |
