# Test fixture: Empty required_resource_tags map
# Tests that empty map results in no filtering (discovers all resources)
# Inherits other configuration from test.tfvars

target_resource_types = [{
  log_namespace    = "Microsoft.KeyVault/vaults"
  metric_namespace = "Microsoft.KeyVault/vaults"
  required_resource_tags = {}
}]
