# Invalid Sumo Logic apps configuration - invalid UUID
azure_subscription_id = "c088dc46-d692-42ad-a4b6-e02d56cc5596"
azure_client_id       = "11111111-2222-3333-4444-555555555555"
azure_client_secret   = "test-client-secret"
azure_tenant_id       = "66666666-7777-8888-9999-aaaaaaaaaaaa"
resource_group_name      = "test-sumo-rg"
location                = "East US"
eventhub_namespace_name = "SUMO-TEST-HUB"
policy_name             = "SumoLogicCollectionPolicy"
throughput_units        = 5
activity_log_export_name     = "SumoActivityLogExport"
activity_log_export_category = "Administrative"
enable_activity_logs         = false
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
installation_apps_list = [
  {
    uuid = "invalid-uuid"
    name = "Test App"
    version = "1.0.0"
  }
]
index_value           = "test-index"