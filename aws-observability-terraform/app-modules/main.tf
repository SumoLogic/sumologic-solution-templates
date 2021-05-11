data "sumologic_personal_folder" "personalFolder" {}

# Create a folder in the folder ID provided. If no folder ID is provided, create the folder in personal folder
resource "sumologic_folder" "apps_folder" {
  description = "This folder contains all the apps for AWS Observability solution."
  name        = var.apps_folder_name
  parent_id   = var.parent_folder_id != "" ? var.parent_folder_id : data.sumologic_personal_folder.personalFolder.id
}

# Create a folder to install all monitors.
resource "sumologic_monitor_folder" "monitor_folder" {
  name        = var.monitors_folder_name
  description = "This folder contains all the monitors for AWS Observability solution."
}

# Create common fields and Explorer hierarchy
module "common" {
  source = "./common"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  managed_fields = {
    "Account" = {
      field_name = "account"
      data_type  = "String"
      state      = true
    },
    "Region" = {
      field_name = "region"
      data_type  = "String"
      state      = true
    },
    "Namespace" = {
      field_name = "namespace"
      data_type  = "String"
      state      = true
    }
  }
}

# Install the RDS app and resources.
module "rds_app" {
  depends_on = [module.common]
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