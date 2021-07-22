# Sumo Logic Provider
provider "sumologic" {
  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment
}