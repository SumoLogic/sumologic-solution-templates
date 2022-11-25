
This Terraform script configures pre-packaged Sumo Logic SLOs and associated monitors for AWS ELB using Terraform modules.

## License

This Terraform script is licensed under the apache v2.0 license.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_sumologic"></a> [sumologic](#requirement\_sumologic) | >= 2.14.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_sumologic"></a> [sumologic](#provider\_sumologic) | 2.16.2 |


## Inputs

Required in the aws_slo.auto.tfvars file.

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_id"></a> [access\_id](#access\_id) | Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_access_key"></a> [access\_key](#access\_key) | Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#environment) | Enter au, ca, de, eu, jp, us2, in, fed or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security | `string` | n/a | yes |
| <a name="input_folder"></a> [folder](#folder) | Indicates the SLO installation folder. | `string` | `"AWS"` | no |
| <a name="input_aws_elb_data_filter"></a> [aws\_elb\_data\_filter](#aws\_elb\_data\_filter) | AWS ELB Data Filter. For eg: account=prod | `string` | `""` | yes |
| <a name="input_time_zone"></a> [time\_zone](#time\_zone) | Time zone for the SLO compliance. Follow the format in the IANA Time Zone Database. | `string` | `"Asia/Kolkata"` | yes |
| <a name="input_monitors_disabled"></a> [input\_monitors\_disabled](#input\_monitors\_disabled) | This flag determines whether to enable all monitors or not. | `bool` | true | yes |

Required in the aws_slo_notifications.auto.tfvars file.

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="connection_notifications_critical"></a> [connection\_notifications\_critical](#connection\_notifications\_critical) | If you want the alerts to send email or connection notifications, edit the aws_slo_notifications.auto.tfvars file to populate the connection_notifications and email_notifications sections. Examples are provided below. | `object` | n/a | no |
| <a name="connection_notifications_warning"></a> [connection\_notifications\_warning](#connection\_notifications\_warning) | If you want the alerts to send email or connection notifications, edit the aws_slo_notifications.auto.tfvars file to populate the connection_notifications and email_notifications sections. Examples are provided below. | `object` | n/a | yes |
| <a name="connection_notifications_missingdata"></a> [connection\_notifications\_missingdata](#connection\_notifications\_missingdata) | If you want the alerts to send email or connection notifications, edit the aws_slo_notifications.auto.tfvars file to populate the connection_notifications and email_notifications sections. Examples are provided below. | `object` | n/a | yes |
| <a name="email_notifications_critical"></a> [email\_notifications\_critical](#email\_notifications\_critical) | If you want the alerts to send email or connection notifications, edit the aws_slo_notifications.auto.tfvars file to populate the connection_notifications and email_notifications sections. Examples are provided below. | `object` | n/a | no |
| <a name="email_notifications_warning"></a> [email\_notifications\_warning](#email\_notifications\_warning) | If you want the alerts to send email or connection notifications, edit the aws_slo_notifications.auto.tfvars file to populate the connection_notifications and email_notifications sections. Examples are provided below. | `object` | n/a | yes |
| <a name="email_notifications_missingdata"></a> [email\_notifications\_missingdata](#email\_notifications\_missingdata) | If you want the alerts to send email or connection notifications, edit the aws_slo_notifications.auto.tfvars file to populate the connection_notifications and email_notifications sections. Examples are provided below. | `object` | n/a | yes |

Examples:


## Installation

### Terraform Installation

1. Generate an access key and access ID for a user that has the Manage Monitors role capability. For instructions see [Access Keys](https://help.sumologic.com/docs/manage/Security/Access-Keys/#Create_an_access_key_on_Preferences_page).

2. Download [Terraform 0.13](https://www.terraform.io/downloads.html) or later, and install it.

3. Clone the Sumo Logic Terraform package for [AWS ELB Slos](https://github.com/SumoLogic/sumologic-solution-templates/slo-packages/aws) using the git clone command.

4. Configuration: After extracting the package, navigate to the `sumologic-solution-templates/slo-packages/aws directory`.

> Edit the `aws_slo.auto.tfvars` file and add the Sumo Logic Access Key and Access ID from Step 1 and your Sumo Logic deployment. If you're not sure of your deployment, see [Sumo Logic Endpoints and Firewall Security](https://help.sumologic.com/docs/api/getting-started/#sumo-logic-endpoints-by-deployment-and-firewall-security).

```
access_id   = "<SUMOLOGIC ACCESS ID>"
access_key  = "<SUMOLOGIC ACCESS KEY>"
environment = "<SUMOLOGIC DEPLOYMENT>"
```

5. The Terraform script installs the slos without any scope filters. If you would like to restrict the alerts to specific accounts or source categories, update the `aws_elb_data_filter` variable. For example:
> To configure alerts for a specific account and source category, set `aws_elb_data_filter` to something like `account=prod _sourceCategory=ind/prod_servers`

6. By default, the slos will be located in a `"AWS"` folder on the SLOs page. To change the name of the folder, update the slo folder name in the `folder` variable in the `aws_slo.auto.tfvars` file.

7. All monitors created for slos are disabled by default on installation. To enable all of the monitors, set the monitors_disabled parameter to false. 

8. If you want the alerts to send email or connection notifications, edit the `aws_slos_notifications.auto.tfvars` file to populate the connection_notifications and email_notifications sections. Examples are provided below.

> In the variable definition below, replace `<CONNECTION_ID>` with the connection ID of the Webhook connection. You can obtain the Webhook connection ID by calling the [Connections API](https://api.sumologic.com/docs/#operation/listConnections).

> Pagerduty connection example

```
connection_notifications = [
    {
      connection_type       = "PagerDuty",
      connection_id         = "<CONNECTION_ID>",
      payload_override      = "{\"service_key\": \"your_pagerduty_api_integration_key\",\"event_type\": \"trigger\",\"description\": \"Alert: Triggered {{TriggerType}} for Monitor {{Name}}\",\"client\": \"Sumo Logic\",\"client_url\": \"{{QueryUrl}}\"}",
      run_for_trigger_types = ["Critical", "ResolvedCritical"]
    },
    {
      connection_type       = "Webhook",
      connection_id         = "<CONNECTION_ID>",
      payload_override      = "",
      run_for_trigger_types = ["Critical", "ResolvedCritical"]
    }
  ]
```

> For information about overriding the payload for different connection types, see [Set Up Webhook Connections](https://help.sumologic.com/docs/manage/connections-integrations/Webhook-Connections/Set-Up-Webhook-Connections/).

> Email notifications example
```
email_notifications = [
    {
      connection_type       = "Email",
      recipients            = ["abc@example.com"],
      subject               = "Monitor Alert: {{TriggerType}} on {{Name}}",
      time_zone             = "PST",
      message_body          = "Triggered {{TriggerType}} Alert on {{Name}}: {{QueryURL}}",
      run_for_trigger_types = ["Critical", "ResolvedCritical"]
    }
  ]
```

**Install slos.**

1. Navigate to the `sumologic-solution-templates/slo-packages/aws directory` and run `terraform init`. This will initialize Terraform and download the required components.
2. Run `terraform plan` to view the slos that Terraform will create or modify.
3. Run `terraform apply`.

### Manual Installation

* Modify the `aws_slo.json` as per requirement. Add filters in the queries and update the Time Zone.
* Navigate to `Manage Data > Monitoring > SLOs`
* Click on `Add > Import`
* Paste the modified JSON and click Import
* Note: This method only creates SLOs. You will need to add monitors manually.

## Issues

Raise issues at [Issues](https://github.com/SumoLogic/sumologic-solution-templates/issues)

## Contributing

* Fork the project on [Github](https://github.com/SumoLogic/sumologic-solution-templates).
* Make your feature addition or fix bug, write tests and commit.
* Create a pull request with one of the maintainer as Reviewer.