# Configuration that would create Event Hub resources if Azure resources existed
eventhub_namespace_name = "SUMO-EVENTHUB-TEST"
target_resource_types = [
  "Microsoft.KeyVault/vaults",
  "Microsoft.Storage/storageAccounts",
  "Microsoft.Sql/servers"
]
required_resource_tags = {
  "environment"                 = "test"
  "logs-collection-destination" = "sumologic"
}
nested_namespace_configs = {
  "Microsoft.KeyVault/vaults"         = ["logs", "metrics"]
  "Microsoft.Storage/storageAccounts" = ["logs", "metrics"]
}
sumo_collector_name = "Azure-EventHub-Test-Collector"
installation_apps_list = [
  {
    uuid    = "53376d23-2687-4500-b61e-4a2e2a119658"
    name    = "Azure Storage"
    version = "1.0.3"
    parameters = {
      "index_value" = "azure_logs"
    }
  },
  {
    uuid    = "b20abced-0122-4c7a-8833-c68c3c29c3d3"
    name    = "Azure Key Vault"
    version = "1.0.2"
    parameters = {
      "index_value" = "azure_logs"
    }
  }
]