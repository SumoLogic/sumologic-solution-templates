# Configuration that would create Event Hub resources if Azure resources existed
eventhub_namespace_name = "SUMO-EVENTHUB-TEST"
target_resource_types = [
  "Microsoft.Network/loadBalancers",
  "Microsoft.Storage/storageAccounts"
]
required_resource_tags = {
  "environment"                 = "test"
  "logs-collection-destination" = "sumologic"
}
nested_namespace_configs = {
  "Microsoft.Network/loadBalancers"         = ["logs", "metrics"]
  "Microsoft.Storage/storageAccounts" = ["logs", "metrics"]
}
sumo_collector_name = "Azure-EventHub-Test-Collector"
installation_apps_list = [{
  uuid    = "63e4bd6d-8e15-41c4-a65d-74589574adf2"
  name    = "Azure Load Balancer"
  version = "1.0.4"
  parameters = {
    "index_value" = "sumologic_default"
  }
},{
    uuid    = "53376d23-2687-4500-b61e-4a2e2a119658"
    name    = "Azure Storage"
    version = "1.0.3"
    parameters = {
      "index_value" = "sumologic_default"
    }
}]