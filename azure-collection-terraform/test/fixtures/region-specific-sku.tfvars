# Test fixture for region-specific Event Hub SKU overrides
# This demonstrates how to override the global SKU settings for specific regions

azure_subscription_id = "c088dc46-d692-42ad-a4b6-9a542d28ad2a"
azure_client_id       = "694b6dc4-52e4-45c5-bd8f-4120b99d8eea"
azure_client_secret   = "test-secret"
azure_tenant_id       = "a39bedba-be8f-4c0f-bfe2-b8c7913501ea"

resource_group_name     = "test-region-specific-sku-rg"
location                = "East US"
eventhub_namespace_name = "test-region-sku-hub"
policy_name             = "TestRegionSpecificPolicy"

# Global defaults: Standard SKU with 2 throughput units
eventhub_namespace_sku    = "Standard"
default_throughput_units = 2

# Override for East US: Use Premium SKU with 8 throughput units
region_specific_eventhub_skus = {
  "East US" = {
    sku              = "Premium"
    throughput_units = 8
  }
}

# Activity Log Configuration
activity_log_export_name     = "TestActivityLogExport"
activity_log_export_category = "test/activity-logs"
enable_activity_logs         = false

# Resource Configuration
target_resource_types = [{
  log_namespace    = "Microsoft.KeyVault/vaults"
  metric_namespace = "Microsoft.KeyVault/vaults"
}]

nested_namespace_configs           = {}
required_resource_tags             = {}
prevent_deletion_if_contains_resources = false

# Sumo Logic Configuration
sumologic_access_id    = "test-access-id"
sumologic_access_key   = "test-access-key"
sumologic_environment  = "us1"
sumo_collector_name    = "test-collector"
installation_apps_list = []
