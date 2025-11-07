# Test fixture: Omitted required_resource_tags field
# Tests that omitted field results in no filtering (discovers all resources)
# Inherits other configuration from test.tfvars

target_resource_types = [{
  log_namespace    = "Microsoft.KeyVault/vaults"
  metric_namespace = "Microsoft.KeyVault/vaults"
  # required_resource_tags field completely omitted - should discover all resources
}]
