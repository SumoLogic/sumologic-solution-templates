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
  # The AzureRM Provider supports authenticating using Azure CLI or Managed Identity.
  # More information on the authentication methods supported by the AzureRM Provider
  # can be found here:
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure
  # We recommend authenticating using the Azure CLI when running Terraform locally.

  # The features block allows changing the behaviour of the Azure Provider, more
  # information can be found here:
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block

  # Use Azure CLI authentication with explicit subscription ID
  subscription_id = var.azure_subscription_id

  features {
    resource_group {
      # Parameterized so the default behavior (prevent deletion if resource group contains resources)
      # remains unchanged for normal use. Tests can override this variable to `false` when they
      # need to delete resource groups containing nested resources.
      prevent_deletion_if_contains_resources = var.prevent_deletion_if_contains_resources
    }
  }
}