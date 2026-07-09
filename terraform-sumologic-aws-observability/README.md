# AWS Observability Terraform Module

This Terraform module deploys the [Sumo Logic AWS Observability Solution](https://help.sumologic.com/docs/observability/aws/) — a full-stack observability solution for AWS environments. It configures AWS collection infrastructure and installs Sumo Logic apps, monitors, dashboards, and field extraction rules for the following AWS services:

- Application Load Balancer (ALB)
- Classic Load Balancer (ELB)
- Network Load Balancer (NLB)
- API Gateway
- CloudTrail
- DynamoDB
- EC2
- ECS
- ElastiCache
- Lambda
- RDS
- SNS
- SQS

## Usage

```hcl
provider "sumologic" {
  environment = var.sumologic_environment
  access_id   = var.sumologic_access_id
  access_key  = var.sumologic_access_key
}

provider "aws" {
  region = "us-east-1"
}

module "aws_observability" {
  source  = "SumoLogic/aws-observability/sumologic"
  version = ">= 1.0.0"

  sumologic_environment     = "us2"
  sumologic_access_id       = var.sumologic_access_id
  sumologic_access_key      = var.sumologic_access_key
  sumologic_organization_id = var.sumologic_organization_id
  aws_account_alias         = "prod"
}
```

For multi-account or multi-region deployments, use the submodules directly:

```hcl
# Install apps once per Sumo Logic org
module "apps" {
  source  = "SumoLogic/aws-observability/sumologic//modules/apps"
  version = ">= 1.0.0"
  ...
}

# Install collection once per AWS account/region
module "collection" {
  source  = "SumoLogic/aws-observability/sumologic//modules/collection"
  version = ">= 1.0.0"
  ...
}
```

See the [`examples/`](./examples) directory for complete working configurations.

## Submodules

| Name | Description |
|------|-------------|
| [modules/apps](./modules/apps) | Installs Sumo Logic apps, monitors, metric rules, FERs, and the AWS Observability hierarchy. Deploy once per Sumo Logic organization. |
| [modules/collection](modules/collections) | Creates AWS collection infrastructure (CloudTrail, ELB, CloudWatch, Kinesis Firehose sources) and Sumo Logic collector. Deploy once per AWS account/region. |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.7 |
| aws | >= 5.16.2, < 7.0.0 |
| sumologic | >= 3.2.9, < 4.0.0 |
| time | >= 0.11.1 |
| random | >= 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| [sumologic](https://registry.terraform.io/providers/SumoLogic/sumologic/latest) | >= 3.2.9, < 4.0.0 |
| [aws](https://registry.terraform.io/providers/hashicorp/aws/latest) | >= 5.16.2, < 7.0.0 |
| [time](https://registry.terraform.io/providers/hashicorp/time/latest) | >= 0.11.1 |

## Modules

| Name | Source |
|------|--------|
| [sumo-module](./modules/apps) | ./modules/apps |
| [collection-module](modules/collections) | ./modules/collection |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| sumologic\_environment | Sumo Logic deployment region (au, ca, ch, de, eu, esc, fed, jp, kr, us1, us2) | `string` | n/a | yes |
| sumologic\_access\_id | Sumo Logic Access ID | `string` | n/a | yes |
| sumologic\_access\_key | Sumo Logic Access Key | `string` | n/a | yes |
| sumologic\_organization\_id | Sumo Logic Organization ID | `string` | n/a | yes |
| aws\_account\_alias | Alias for the AWS account (lowercase letters and numbers only) | `string` | n/a | yes |
| sumologic\_folder\_installation\_location | Where to install the app folder (`"Personal Folder"` or `"Admin Recommended Folder"`) | `string` | `"Personal Folder"` | no |
| sumologic\_folder\_share\_with\_org | Share the AWS Observability folder with the entire org | `bool` | `true` | no |
| aws\_resource\_tags | Tags to apply to all AWS resources created by this module | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| Apps | All outputs related to apps. |
| Collection | All outputs related to collection and sources. |
