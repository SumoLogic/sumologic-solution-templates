# Invalid resource group name that's too long (over 90 characters)
azure_subscription_id = ""
azure_client_id       = ""
azure_client_secret   = ""
azure_tenant_id       = ""
resource_group_name      = "test-sumo-rg-with-a-very-long-name-that-exceeds-the-maximum-allowed-length-of-90-characters-for-azure-resource-groups"  # Invalid: 120+ characters
location                = "East US"
eventhub_namespace_name = "SUMO-VALID-HUB"
policy_name             = "SumoLogicCollectionPolicy"
throughput_units        = 10
activity_log_export_name     = "SumoActivityLogExport"
activity_log_export_category = "Administrative"
enable_activity_logs         = true
target_resource_types    = ["Microsoft.KeyVault/vaults"]
required_resource_tags   = {
  "logs-collection-destination" = "sumologic"
}
nested_namespace_configs = {
  "Microsoft.KeyVault/vaults" = ["logs", "metrics"]
}
sumologic_access_id    = "test-access-id"
sumologic_access_key   = "test-access-key"
sumologic_environment  = "us2"
sumo_collector_name    = "Azure-Test-Collector"
installation_apps_list = []
index_value           = "test-index"