# AWS Observability Terraform

The AWS Observability terraform is used to deploy Apps and AWS sources for multiple accounts and Regions.

For Multi account and regions use provider aliases as shown below

```terraform
# Region US-EAST-1, Account Production
provider "aws" {
  profile = "production"
  region  = "us-east-1"
  alias   = "production-us-east-1"
}

module "production-us-east-1" {
  source    = "../source-module"
  providers = { aws = aws.production-us-east-1 }

  aws_account_alias         = "production"
  sumologic_organization_id = "0000000000123456"
}

# Region US-EAST-2, Account Production
provider "aws" {
  profile = "production"
  region  = "us-east-2"
  alias   = "production-us-east-2"
}

module "production-us-east-2" {
  source    = "../source-module"
  providers = { aws = aws.production-us-east-2 }

  aws_account_alias         = "production"
  sumologic_organization_id = "0000000000123456"

  # Use the same collector created for Prodcution account.
  sumologic_existing_collector_details = {
    create_collector = false
    collector_id     = module.production-us-east-1.sumologic_collector["collector"].id
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0 |
| aws | >= 3.42.0 |
| random | >=3.1.0 |
| sumologic | >= 2.9.0 |
| time | >=0.7.1 |

## Required Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws\_account\_alias | Provide an Alias for AWS account for identification in Sumo Logic Explorer View, metrics and logs. Please do not include special characters. | `string` | n/a | yes |
| sumologic\_access\_id | Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| sumologic\_access\_key | Sumo Logic Access Key. | `string` | n/a | yes |
| sumologic\_environment | Enter au, ca, de, eu, jp, us2, in, fed or us1. Visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security | `string` | n/a | yes |
| sumologic\_organization\_id | Appears on the Account Overview page that displays information about your Sumo Logic organization. Used for IAM Role in Sumo Logic AWS Sources. | `string` | n/a | yes |

## Optional Inputs

##### SumoLogic Module
Please [visit](./app-modules/README.md) for details on additional inputs.

##### Collection Module
Please [visit](./source-module/README.md) for details on additional inputs.

## Outputs

| Name | Description |
|------|-------------|
| Apps | All outputs related to apps. |
| Collection | All outputs related to collection and sources. |

