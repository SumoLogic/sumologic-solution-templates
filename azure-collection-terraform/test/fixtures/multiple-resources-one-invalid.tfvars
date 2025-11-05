# Multiple resource types with one invalid category test fixture
# Tests that one invalid category among multiple resources fails validation

azure_subscription_id   = "c088dc46-d692-42ad-a4b6-9a542d28ad2a"
azure_client_id         = "694b6dc4-52e4-45c5-bd8f-4120b99d8eea"
azure_client_secret     = "test-secret"
azure_tenant_id         = "a39bedba-be8f-4c0f-bfe2-b8c7913501ea"

resource_group_name     = "test-rg"
eventhub_namespace_name = "test-eventhub"
eventhub_namespace_sku  = "Standard"
location                = "East US"
policy_name             = "TestPolicy"

standard_throughput_units = 2
premium_throughput_units  = 4

enable_activity_logs         = false
activity_log_export_name     = "TestActivityLog"
activity_log_export_category = "azure/activity-logs"

target_resource_types = [
  {
    log_namespace    = "Microsoft.KeyVault/vaults"
    metric_namespace = "Microsoft.KeyVault/vaults"
    log_categories   = ["AuditEvent"]  # Valid
  },
  {
    log_namespace    = "Microsoft.DBforMySQL/flexibleServers"
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
    log_categories   = ["InvalidMySQLCategory"]  # Invalid - should fail
  }
]

required_resource_tags   = {}
nested_namespace_configs = {}

sumologic_access_id   = "test-access-id"
sumologic_access_key  = "test-access-key"
sumologic_environment = "us1"
sumo_collector_name   = "test-collector"

installation_apps_list = []

prevent_deletion_if_contains_resources = true
