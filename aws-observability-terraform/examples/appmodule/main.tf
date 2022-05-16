#
# The below module is used to install apps, metric rules, Field extraction rules, Fields and Monitors.
# NOTE - The "app-modules" should be installed per Sumo Logic organization.
#
module "sumo-module" {
  source                   = "../../app-modules"
  access_id                = var.sumologic_access_id
  access_key               = var.sumologic_access_key
  environment              = var.sumologic_environment
  json_file_directory_path = dirname(path.cwd)
  folder_installation_location = var.sumologic_folder_installation_location
  folder_share_with_org    = var.sumologic_folder_share_with_org
  sumologic_organization_id = var.sumologic_organization_id
  apps_folder_name = var.apps_folder
  monitors_folder_name = var.monitors_folder
  alb_monitors_disabled = var.alb_monitors
  ec2metrics_monitors_disabled = var.ec2metrics_monitors
  ecs_monitors_disabled = var.ecs_monitors
  elasticache_monitors_disabled = var.elasticache_monitors
}
