# Sumo Logic Provider
provider "sumologic" {
  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment
}

#Sumo Logic SLO Folder
resource "sumologic_slo_folder" "AWS" {
  name        = var.folder
  description = "Folder for SLOs created for AWS"
}