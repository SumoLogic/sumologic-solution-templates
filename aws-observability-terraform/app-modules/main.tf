data "sumologic_personal_folder" "personalFolder" {}

# Create a folder in the folder ID provided. If no folder ID is provided, create the folder in personal folder
resource "sumologic_folder" "apps_folder" {
  description = "This folder contains all the apps for AWS Observability solution."
  name        = var.apps_folder_name
  parent_id   = var.parent_folder_id != "" ? format("%x", var.parent_folder_id) : data.sumologic_personal_folder.personalFolder.id
}

# Create a folder to install all monitors.
resource "sumologic_monitor_folder" "monitor_folder" {
  name        = var.monitors_folder_name
  description = "This folder contains all the monitors for AWS Observability solution."
}

# Install the overview app and resources.
module "overview_app" {
  source     = "./overview"

  access_id                = var.access_id
  access_key               = var.access_key
  environment              = var.environment
  app_folder_id            = sumologic_folder.apps_folder.id
}

# Install the alb app and resources.
module "alb_app" {
  source     = "./alb"

  access_id                = var.access_id
  access_key               = var.access_key
  environment              = var.environment
  app_folder_id            = sumologic_folder.apps_folder.id
  monitor_folder_id        = sumologic_monitor_folder.monitor_folder.id
  monitors_disabled        = var.alb_monitors_disabled
  connection_notifications = var.connection_notifications
  email_notifications      = var.email_notifications
  group_notifications      = var.group_notifications
}

# Install the apigateway app and resources.
module "apigateway_app" {
  depends_on = [module.overview_app]
  source     = "./apigateway"

  access_id                = var.access_id
  access_key               = var.access_key
  environment              = var.environment
  app_folder_id            = sumologic_folder.apps_folder.id
  monitor_folder_id        = sumologic_monitor_folder.monitor_folder.id
  monitors_disabled        = var.apigateway_monitors_disabled
  connection_notifications = var.connection_notifications
  email_notifications      = var.email_notifications
  group_notifications      = var.group_notifications
}

# Install the dynamodb app and resources.
module "dynamodb_app" {
  depends_on = [module.alb_app]
  source     = "./dynamodb"

  access_id                = var.access_id
  access_key               = var.access_key
  environment              = var.environment
  app_folder_id            = sumologic_folder.apps_folder.id
  monitor_folder_id        = sumologic_monitor_folder.monitor_folder.id
  monitors_disabled        = var.dynamodb_monitors_disabled
  connection_notifications = var.connection_notifications
  email_notifications      = var.email_notifications
  group_notifications      = var.group_notifications
}

# Install the ec2metrics app and resources.
module "ec2metrics_app" {
  depends_on = [module.apigateway_app]
  source     = "./ec2metrics"

  access_id                = var.access_id
  access_key               = var.access_key
  environment              = var.environment
  app_folder_id            = sumologic_folder.apps_folder.id
  monitor_folder_id        = sumologic_monitor_folder.monitor_folder.id
  monitors_disabled        = var.ec2metrics_monitors_disabled
  connection_notifications = var.connection_notifications
  email_notifications      = var.email_notifications
  group_notifications      = var.group_notifications
}

# Install the ecs app and resources.
module "ecs_app" {
  depends_on = [module.dynamodb_app]
  source     = "./ecs"

  access_id                = var.access_id
  access_key               = var.access_key
  environment              = var.environment
  app_folder_id            = sumologic_folder.apps_folder.id
  monitor_folder_id        = sumologic_monitor_folder.monitor_folder.id
  monitors_disabled        = var.ecs_monitors_disabled
  connection_notifications = var.connection_notifications
  email_notifications      = var.email_notifications
  group_notifications      = var.group_notifications
}

# Install the elasticache app and resources.
module "elasticache_app" {
  depends_on = [module.ec2metrics_app]
  source     = "./elasticache"

  access_id                = var.access_id
  access_key               = var.access_key
  environment              = var.environment
  app_folder_id            = sumologic_folder.apps_folder.id
  monitor_folder_id        = sumologic_monitor_folder.monitor_folder.id
  monitors_disabled        = var.elasticache_monitors_disabled
  connection_notifications = var.connection_notifications
  email_notifications      = var.email_notifications
  group_notifications      = var.group_notifications
}

# Install the lambda app and resources.
module "lambda_app" {
  depends_on = [module.ecs_app]
  source     = "./lambda"

  access_id                = var.access_id
  access_key               = var.access_key
  environment              = var.environment
  app_folder_id            = sumologic_folder.apps_folder.id
  monitor_folder_id        = sumologic_monitor_folder.monitor_folder.id
  monitors_disabled        = var.lambda_monitors_disabled
  connection_notifications = var.connection_notifications
  email_notifications      = var.email_notifications
  group_notifications      = var.group_notifications
}

# Install the nlb app and resources.
module "nlb_app" {
  depends_on = [module.elasticache_app]
  source     = "./nlb"

  access_id                = var.access_id
  access_key               = var.access_key
  environment              = var.environment
  app_folder_id            = sumologic_folder.apps_folder.id
  monitor_folder_id        = sumologic_monitor_folder.monitor_folder.id
  monitors_disabled        = var.nlb_monitors_disabled
  connection_notifications = var.connection_notifications
  email_notifications      = var.email_notifications
  group_notifications      = var.group_notifications
}

# Install the RDS app and resources.
module "rds_app" {
  depends_on = [module.lambda_app]
  source     = "./rds"

  access_id                = var.access_id
  access_key               = var.access_key
  environment              = var.environment
  app_folder_id            = sumologic_folder.apps_folder.id
  monitor_folder_id        = sumologic_monitor_folder.monitor_folder.id
  monitors_disabled        = var.rds_monitors_disabled
  connection_notifications = var.connection_notifications
  email_notifications      = var.email_notifications
  group_notifications      = var.group_notifications
}

# Install the rce app and resources.
module "rce_app" {
  depends_on = [module.nlb_app]
  source     = "./rce"

  access_id                = var.access_id
  access_key               = var.access_key
  environment              = var.environment
  app_folder_id            = sumologic_folder.apps_folder.id
}
