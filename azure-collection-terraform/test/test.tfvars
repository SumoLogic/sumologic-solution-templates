# Base Test Configuration
# This file provides default values for all tests
# Individual fixture files override specific values

# Azure Authentication (Test placeholders)
azure_subscription_id = "12345678-1234-1234-1234-123456789012"
azure_client_id       = "12345678-1234-1234-1234-123456789012"
azure_client_secret   = "test-client-secret"
azure_tenant_id       = "12345678-1234-1234-1234-123456789012"

# Azure Infrastructure
resource_group_name     = "test-sumologic-rg"
eventhub_namespace_name = "test-sumologic-eventhub"
policy_name             = "TestSumoLogicPolicy"
location                = "East US"

# Event Hub SKU
eventhub_namespace_sku   = "Standard"
default_throughput_units = 2

# Activity Logs (disabled for most tests)
enable_activity_logs         = false
activity_log_export_name     = "TestActivityLogs"
activity_log_export_category = "azure/test-activity-logs"

# Target Resources - Minimal for testing
target_resource_types = [
  {
    log_namespace    = "Microsoft.KeyVault/vaults"
    metric_namespace = "Microsoft.KeyVault/vaults"
  }
]

required_resource_tags   = {}
nested_namespace_configs = {}

# Sumo Logic Configuration (Test placeholders)
sumologic_access_id   = "test-access-id"
sumologic_access_key  = "test-access-key"
sumologic_environment = "us1"
sumo_collector_name   = "test-collector"

# No apps for testing
installation_apps_list = []

# Regional configs
region_specific_eventhub_skus            = {}
eventhub_namespace_limited_sku_locations = ["West India", "Mexico Central"]
eventhub_namespace_unsupported_locations = [
  "South Africa West",
  "Australia Central 2",
  "USGov Arizona",
  "USGov Texas",
  "USGov Virginia",
  "Brazil Southeast",
  "China East",
  "China East 2",
  "China East 3",
  "China North",
  "China North 2",
  "China North 3",
  "France South",
  "Germany North",
  "Norway West",
  "Sweden South",
  "Switzerland West",
  "Taiwan North",
  "UAE Central",
]

prevent_deletion_if_contains_resources = true

# Network Security - Disabled by default (backward compatibility)
eventhub_enable_network_security  = false
eventhub_public_network_enabled   = true
eventhub_default_network_action   = "Allow"
eventhub_trusted_services_enabled = false
sumologic_ip_whitelist_file       = ""
sumologic_ip_whitelist            = []
eventhub_vnet_subnet_ids          = []
eventhub_additional_ip_rules      = []
