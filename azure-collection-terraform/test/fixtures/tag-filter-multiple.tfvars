# Test fixture: Multiple tags with AND logic
# Tests that multiple tags use AND logic (all must match)
# Inherits other configuration from test.tfvars

target_resource_types = [{
  log_namespace    = "Microsoft.KeyVault/vaults"
  metric_namespace = "Microsoft.KeyVault/vaults"
  required_resource_tags = {
    "environment" = "production"
    "team"        = "security"
    "managed-by"  = "terraform"
  }
}]
