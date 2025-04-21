# provider "sumologic" {
#   environment = var.sumologic_environment
#   access_id   = var.sumologic_access_id
#   access_key  = var.sumologic_access_key
#   admin_mode  = true
#   alias       = "admin"
# }

provider "sumologic" {
  environment = var.sumologic_environment
  access_id   = var.sumologic_access_id
  access_key  = var.sumologic_access_key
  # base_url   = local.sumologic_service_endpoint
}

provider "azurerm" {
  # The AzureRM Provider supports authenticating using via the Azure CLI, a Managed Identity
  # and a Service Principal. More information on the authentication methods supported by
  # the AzureRM Provider can be found here:
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure
  # recommended authenticating using the Azure CLI when running Terraform locally.

  # The features block allows changing the behaviour of the Azure Provider, more
  # information can be found here:
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block
  subscription_id = var.azure_subscription_id
  features {

    resource_group {
      prevent_deletion_if_contains_resources = true
    }


  }
}