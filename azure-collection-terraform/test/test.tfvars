# Test configuration tfvars file
# This file contains working test values for CI/CD

# Azure Authentication (use environment variables for real values)
azure_subscription_id = ""
azure_client_id       = ""
azure_client_secret   = ""
azure_tenant_id       = ""

# Azure Resource Configuration
resource_group_name      = "test-sumo-rg"
location                = "East US"
eventhub_namespace_name = "SUMO-TEST-HUB"
policy_name             = "SumoLogicCollectionPolicy"
throughput_units        = 5

# Activity Log Configuration
activity_log_export_name     = "SumoActivityLogExport"
activity_log_export_category = "Administrative"
enable_activity_logs         = false

# Resource Targeting
target_resource_types    = ["Microsoft.KeyVault/vaults", "Microsoft.Storage/storageAccounts"]
required_resource_tags   = {
  "logs-collection-destination" = "sumologic"
}
nested_namespace_configs = {
  "Microsoft.KeyVault/vaults" = ["logs", "metrics"]
}

# Sumo Logic Configuration
sumologic_access_id    = "test-access-id"
sumologic_access_key   = "test-access-key"
sumologic_environment  = "us2"
sumo_collector_name    = "Azure-Test-Collector"
installation_apps_list = []
index_value           = "test-index"