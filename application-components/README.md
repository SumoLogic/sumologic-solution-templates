<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.5 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |
| <a name="requirement_sumologic"></a> [sumologic](#requirement\_sumologic) | >= 2.18.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.7.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | 3.1.1 |
| <a name="provider_sumologic"></a> [sumologic](#provider\_sumologic) | 2.18.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_Memcached-AuthenticationError"></a> [Memcached-AuthenticationError](#module\_Memcached-AuthenticationError) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Memcached-CacheHitRatio"></a> [Memcached-CacheHitRatio](#module\_Memcached-CacheHitRatio) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Memcached-CommandsError"></a> [Memcached-CommandsError](#module\_Memcached-CommandsError) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Memcached-ConnectionYields"></a> [Memcached-ConnectionYields](#module\_Memcached-ConnectionYields) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Memcached-CurrentConnections"></a> [Memcached-CurrentConnections](#module\_Memcached-CurrentConnections) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Memcached-HighMemoryUsage"></a> [Memcached-HighMemoryUsage](#module\_Memcached-HighMemoryUsage) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Memcached-ListenDisabled"></a> [Memcached-ListenDisabled](#module\_Memcached-ListenDisabled) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Memcached-Uptime"></a> [Memcached-Uptime](#module\_Memcached-Uptime) | SumoLogic/sumo-logic-monitor/sumologic | n/a |

## Resources

| Name | Type |
|------|------|
| [null_resource.install_app_component_app](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.install_memcached_app](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [sumologic_content_permission.share_with_org](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/content_permission) | resource |
| [sumologic_field.component](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.db_cluster](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.db_cluster_address](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.db_cluster_port](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.db_system](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.environment](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.pod_labels_db_cluster](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.pod_labels_db_cluster_address](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.pod_labels_db_cluster_port](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.pod_labels_db_system](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field_extraction_rule.SumoLogicFieldExtractionRulesForDatabase](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_folder.root_apps_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/folder) | resource |
| [sumologic_hierarchy.application_component_view](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/hierarchy) | resource |
| [sumologic_monitor_folder.memcached_monitor_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/monitor_folder) | resource |
| [sumologic_monitor_folder.root_monitor_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/monitor_folder) | resource |
| [sumologic_admin_recommended_folder.adminFolder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/data-sources/admin_recommended_folder) | data source |
| [sumologic_personal_folder.personalFolder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/data-sources/personal_folder) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apps_folder_installation_location"></a> [apps\_folder\_installation\_location](#input\_apps\_folder\_installation\_location) | Indicates where to install the app folder. Enter "Personal Folder" for installing in "Personal" folder and "Admin Recommended Folder" for installing in "Admin Recommended" folder. | `string` | `"Personal Folder"` | no |
| <a name="input_apps_folder_name"></a> [apps\_folder\_name](#input\_apps\_folder\_name) | Provide a folder name where all the apps will be installed under the Personal folder of the user whose access keys you have entered.<br>            Default value will be: Applications Component Solutions | `string` | `"Applications Component Solution - Apps"` | no |
| <a name="input_connection_notifications"></a> [connection\_notifications](#input\_connection\_notifications) | Connection Notifications to be sent by the alert. | <pre>list(object(<br>    {<br>      connection_type       = string,<br>      connection_id         = string,<br>      payload_override      = string,<br>      run_for_trigger_types = list(string)<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_database_deployment_type"></a> [database\_deployment\_type](#input\_database\_deployment\_type) | Provide the deployment type where your databases are running.Allowed values are Kubernetes,Non-Kubernetes,Both. | `string` | `"Both"` | no |
| <a name="input_database_engines"></a> [database\_engines](#input\_database\_engines) | Provide comma separated list of database components for which sumologic resources needs to be created. Allowed values are "memcached,cassandra,elasticsearch,sqlserver,mongodb,mysql,postgresql,redis,mariadb,couchbase,oracle. | `string` | `""` | no |
| <a name="input_email_notifications"></a> [email\_notifications](#input\_email\_notifications) | Email Notifications to be sent by the alert. | <pre>list(object(<br>    {<br>      connection_type       = string,<br>      recipients            = list(string),<br>      subject               = string,<br>      time_zone             = string,<br>      message_body          = string,<br>      run_for_trigger_types = list(string)<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_group_notifications"></a> [group\_notifications](#input\_group\_notifications) | Whether or not to group notifications for individual items that meet the trigger condition. Defaults to true. | `bool` | `true` | no |
| <a name="input_memcached_data_source"></a> [memcached\_data\_source](#input\_memcached\_data\_source) | Sumo Logic Memcached cluster Filter. For eg: db\_cluster=memcached.prod.01 | `string` | `"db_system=memcached"` | no |
| <a name="input_memcached_monitor_folder"></a> [memcached\_monitor\_folder](#input\_memcached\_monitor\_folder) | Folder where monitors will be created. | `string` | `"Memcached"` | no |
| <a name="input_monitors_disabled"></a> [monitors\_disabled](#input\_monitors\_disabled) | Whether the monitors are enabled or not? | `bool` | `true` | no |
| <a name="input_monitors_folder_name"></a> [monitors\_folder\_name](#input\_monitors\_folder\_name) | Provide a folder name where all the apps will be installed under the Personal folder of the user whose access keys you have entered.<br>            Default value will be: Applications Component Solutions | `string` | `"Applications Component Solution - Monitors"` | no |
| <a name="input_share_apps_folder_with_org"></a> [share\_apps\_folder\_with\_org](#input\_share\_apps\_folder\_with\_org) | Indicates if Apps folder should be shared (view access) with entire organization. true to enable; false to disable. | `bool` | `true` | no |
| <a name="input_sumologic_access_id"></a> [sumologic\_access\_id](#input\_sumologic\_access\_id) | Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_sumologic_access_key"></a> [sumologic\_access\_key](#input\_sumologic\_access\_key) | Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_sumologic_environment"></a> [sumologic\_environment](#input\_sumologic\_environment) | Enter au, ca, de, eu, jp, us2, in, fed or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security | `string` | n/a | yes |
| <a name="input_sumologic_organization_id"></a> [sumologic\_organization\_id](#input\_sumologic\_organization\_id) | You can find your org on the Preferences page in the Sumo Logic UI. For more information, see the Preferences Page topic. Your org ID will be used to configure the IAM Role for Sumo Logic AWS Sources."<br>            For more details, visit https://help.sumologic.com/01Start-Here/05Customize-Your-Sumo-Logic-Experience/Preferences-Page | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ApplicationComponentAppsFolder"></a> [ApplicationComponentAppsFolder](#output\_ApplicationComponentAppsFolder) | Go to this link to view the apps folder |
| <a name="output_ApplicationComponentMonitorsFolder"></a> [ApplicationComponentMonitorsFolder](#output\_ApplicationComponentMonitorsFolder) | Go to this link to view the monitors folder |
<!-- END_TF_DOCS -->