#
# The below module is used to install apps, metric rules, Field extraction rules, Fields and Monitors.
# NOTE - The "app-modules" should be installed per Sumo Logic organization.
#
module "app-module" {
  source                         = "./modules/apps"
  sumologic_access_id            = var.sumologic_access_id
  sumologic_access_key           = var.sumologic_access_key
  sumologic_environment          = var.sumologic_environment
  sumologic_environment_base_url = var.sumologic_environment_base_url
}

#
# The below module is used to install AWS and Sumo Logic resources to collect logs and metrics from AWS into Sumo Logic.
# NOTE - For multi account and multi region deployment, copy the module and provide different aws provider for region and account.
#
module "collection-module" {
  source = "./modules/collections"

  providers = {
    aws                     = aws
    lambda-invoke-extension = lambda-invoke-extension
  }

  aws_account_alias         = var.aws_account_alias
  sumologic_organization_id = var.sumologic_organization_id
  sumologic_access_id       = var.sumologic_access_id
  sumologic_access_key      = var.sumologic_access_key
  sumologic_environment     = var.sumologic_environment
  aws_resource_tags         = var.aws_resource_tags
}
