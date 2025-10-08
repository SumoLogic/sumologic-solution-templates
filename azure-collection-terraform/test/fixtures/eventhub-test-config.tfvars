# Configuration that would create Event Hub resources if Azure resources existed
azure_subscription_id = "your-real-subscription-id"
azure_client_id       = "your-real-client-id"
azure_client_secret   = "your-real-client-secret"
azure_tenant_id       = "your-real-tenant-id"
resource_group_name      = "test-sumo-rg"
location                = "East US"
eventhub_namespace_name = "SUMO-EVENTHUB-TEST"
policy_name             = "SumoLogicCollectionPolicy"
throughput_units        = 10
activity_log_export_name     = "SumoActivityLogExport"
activity_log_export_category = "Administrative"
enable_activity_logs         = true
target_resource_types    = [
  "Microsoft.KeyVault/vaults",
  "Microsoft.Storage/storageAccounts",
  "Microsoft.Sql/servers"
]
required_resource_tags   = {
  "environment" = "test"
  "logs-collection-destination" = "sumologic"
}
nested_namespace_configs = {
  "Microsoft.KeyVault/vaults" = ["logs", "metrics"]
  "Microsoft.Storage/storageAccounts" = ["logs", "metrics"]
}
sumologic_access_id    = "your-sumologic-access-id"
sumologic_access_key   = "your-sumologic-access-key"
sumologic_environment  = "us2"
sumo_collector_name    = "Azure-EventHub-Test-Collector"
installation_apps_list = [
  {
    uuid = "53376d23-2687-4500-b61e-4a2e2a119658"
    name = "Azure Storage"
    version = "1.0.3"
  },
  {
    uuid = "b20abced-0122-4c7a-8833-c68c3c29c3d3"
    name = "Azure Key Vault"
    version = "1.0.2"
  }
]
index_value           = "azure_logs"