provider "sumologic" {
  access_id   = var.sumologic_access_id
  access_key  = var.sumologic_access_key
  base_url    = var.sumologic_environment_base_url
  environment = var.sumologic_environment_base_url == null ? var.sumologic_environment : null
}

provider "azurerm" {
  subscription_id = var.azure_subscription_id
  
  features {
    resource_group {
      prevent_deletion_if_contains_resources = var.prevent_deletion_if_contains_resources
    }
  }
}