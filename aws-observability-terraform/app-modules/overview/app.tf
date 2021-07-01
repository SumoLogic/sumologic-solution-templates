module "overview_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** No Metric Rules for Overview ********************** #

  # ********************** Fields ********************** #
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

  # ********************** No FERs for Overview ********************** #
  
  # ********************** Apps - Account and Region Level dashboards only ********************** #
  managed_apps = {
    "OverviewApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/Overview-App.json"])
      folder_id    = var.app_folder_id
    }
  }

  # ********************** Monitors ********************** #
}