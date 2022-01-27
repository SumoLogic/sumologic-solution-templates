# Sumo Logic Provider
provider "sumologic" {
  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment
  admin_mode  = var.folder_installation_location == "Personal" ? false : true
}