provider "sumologic" {
  environment = var.sumologic_environment
  access_id   = var.sumologic_access_id
  access_key  = var.sumologic_access_key
  admin_mode  = true
  alias       = "admin"
}

provider "sumologic" {
  environment = var.sumologic_environment
  access_id   = var.sumologic_access_id
  access_key  = var.sumologic_access_key
}
