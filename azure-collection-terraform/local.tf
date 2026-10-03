locals {
  sumologic_service_endpoint = var.sumologic_environment == "us1" ? "https://service.sumologic.com" : (contains(["stag", "long"], var.sumologic_environment) ? "https://${var.sumologic_environment}.sumologic.net" : "https://service.${var.sumologic_environment}.sumologic.com")
  sumologic_api_endpoint     = var.sumologic_environment == "us1" ? "https://api.sumologic.com/api" : (contains(["stag", "long"], var.sumologic_environment) ? "https://${var.sumologic_environment}-api.sumologic.net/api" : "https://api.${var.sumologic_environment}.sumologic.com/api")

  # is_adminMode = var.apps_folder_installation_location == "Admin Recommended Folder" ? true : false

  apps_to_install = compact([for s in split(",", var.apps_names_to_install) : trimspace(s)])

  solution_version = "v1.0.0"

}
