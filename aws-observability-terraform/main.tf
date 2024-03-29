#
# The below module is used to install apps, metric rules, Field extraction rules, Fields and Monitors.
# NOTE - The "app-modules" should be installed per Sumo Logic organization.
#
module "sumo-module" {
  source                   = "./app-modules"
  access_id                = var.sumologic_access_id
  access_key               = var.sumologic_access_key
  environment              = var.sumologic_environment
  json_file_directory_path = dirname(path.cwd)
  folder_installation_location = var.sumologic_folder_installation_location
  folder_share_with_org    = var.sumologic_folder_share_with_org
  sumologic_organization_id = var.sumologic_organization_id
}

#
# The below module is used to install AWS and Sumo Logic resources to collect logs and metrics from AWS into Sumo Logic.
# NOTE - For multi account and multi region deployment, copy the module and provide different aws provider for region and account.
#
module "collection-module" {
  source = "./source-module"

  aws_account_alias         = var.aws_account_alias
  sumologic_organization_id = var.sumologic_organization_id
  access_id                 = var.sumologic_access_id
  access_key                = var.sumologic_access_key
  environment               = var.sumologic_environment  
}