
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

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_id"></a> [access\_id](#access\_id) | Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_access_key"></a> [access\_key](#access\_key) | Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#environment) | Enter au, ca, de, eu, jp, us2, in, fed or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security | `string` | n/a | yes |
| <a name="input_folder"></a> [folder](#folder\_installation\_location) | Indicates the SLO installation folder. | `string` | `"AWS"` | no |
| <a name="input_aws_elb_data_filter"></a> [aws\_elb\_data\_filter](#aws\_elb\_data\_filter) | AWS ELB Data Filter. For eg: account=prod | `string` | `""` | yes |
| <a name="input_time_zone"></a> [time\_zone](#time\_zone) | Time zone for the SLO compliance. Follow the format in the IANA Time Zone Database. | `string` | `"Asia/Kolkata"` | yes |
| <a name="input_monitors_disabled"></a> [input\_monitors\_disabled](#input\_monitors\_disabled) | This flag determines whether to enable all monitors or not. | `bool` | true | yes |

## Installation

### Terraform
```
* terraform init
* terraform apply
```

### Manual
```
* Modify the aws_slo.json as per requirement. Add filters in the queries and update the Time Zone.
* Navigate to Manage Data > Monitoring > SLOs
* Click on Add > Import
* Paste the modified JSON and click Import
* Note: This method only creates SLOs. You will need to add monitors manually.
```

## Issues

Raise issues at [Issues](https://github.com/SumoLogic/sumologic-solution-templates/issues)

## Contributing

* Fork the project on [Github](https://github.com/SumoLogic/sumologic-solution-templates).
* Make your feature addition or fix bug, write tests and commit.
* Create a pull request with one of the maintainer as Reviewer.