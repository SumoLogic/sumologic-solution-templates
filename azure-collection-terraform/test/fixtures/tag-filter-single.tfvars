# Test fixture: Single tag filter
# Tests single tag filtering behavior
# Inherits other configuration from test.tfvars

target_resource_types = [{
  log_namespace    = "Microsoft.KeyVault/vaults"
  metric_namespace = "Microsoft.KeyVault/vaults"
  required_resource_tags = {
    "environment" = "production"
  }
}]
