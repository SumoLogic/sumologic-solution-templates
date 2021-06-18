module "rce_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** No Metric Rules for RCE ********************** #

  # ********************** No Fields for RCE ********************** #

  # ********************** No FERs for RCE ********************** #
  
  # ********************** Apps - RCE dashboards only ********************** #
  managed_apps = {
    "OverviewApp" = {
      content_json = join("", [dirname(dirname(path.cwd)), "/aws-observability/json/Rce-App.json"])
      folder_id    = var.app_folder_id
    }
  }

  # ********************** Monitors ********************** #
}