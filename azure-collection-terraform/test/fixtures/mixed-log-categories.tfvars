# Mixed valid and invalid log categories test fixture
# Tests that mix of valid and invalid categories fails validation

azure_subscription_id   = "c088dc46-d692-42ad-a4b6-9a542d28ad2a"
azure_client_id         = "694b6dc4-52e4-45c5-bd8f-4120b99d8eea"
azure_client_secret     = "test-secret"
azure_tenant_id         = "a39bedba-be8f-4c0f-bfe2-b8c7913501ea"

resource_group_name     = "test-rg"
eventhub_namespace_name = "test-eventhub"
eventhub_namespace_sku  = "Standard"
default_throughput_units = 2
location                = "East US"
policy_name             = "TestPolicy"


enable_activity_logs         = false
activity_log_export_name     = "TestActivityLog"
activity_log_export_category = "azure/activity-logs"

target_resource_types = [{
  log_namespace    = "Microsoft.KeyVault/vaults"
  metric_namespace = "Microsoft.KeyVault/vaults"
  log_categories   = ["AuditEvent", "InvalidCategory", "AzurePolicyEvaluationDetails"]  # Mix: 2 valid, 1 invalid
}]

required_resource_tags   = {}
nested_namespace_configs = {}

sumologic_access_id   = "test-access-id"
sumologic_access_key  = "test-access-key"
sumologic_environment = "us1"
sumo_collector_name   = "test-collector"

installation_apps_list = []

prevent_deletion_if_contains_resources = true
