check "nested_config_validation" {
  assert {
    condition = length([
      for parent_type in keys(var.nested_namespace_configs) : parent_type
      if !contains(local.log_namespaces, parent_type)
    ]) == 0

    error_message = "ERROR: The following parent resource types from 'nested_namespace_configs' are missing in 'target_resource_types' log_namespace: ${join(", ", [
      for parent_type in keys(var.nested_namespace_configs) : parent_type
      if !contains(local.log_namespaces, parent_type)
    ])}. Please add them to 'target_resource_types' variable with a log_namespace."
  }
}

check "eventhub_sku_fallback_warning" {
  assert {
    condition = length([
      for location, config in local.eventhub_namespace_configs : location
      if config.sku != var.eventhub_namespace_sku
    ]) == 0

    error_message = "WARNING: The following regions do not support '${var.eventhub_namespace_sku}' SKU and will fallback to 'Standard' SKU: ${join(", ", [
      for location, config in local.eventhub_namespace_configs : location
      if config.sku != var.eventhub_namespace_sku
    ])}. This is expected behavior and the deployment will continue successfully. Check outputs 'eventhub_sku_fallback_info' and 'regions_with_sku_fallback' for details."
  }
}

check "premium_sku_regions_info" {
  assert {
    condition = var.eventhub_namespace_sku != "Premium" || length([
      for location in keys(local.resources_by_location_only) : location
      if contains(local.regions_without_premium_support, replace(lower(location), " ", ""))
    ]) == 0

    error_message = "INFO: You've selected Premium SKU, but some of your target regions (${join(", ", [
      for location in keys(local.resources_by_location_only) : location
      if contains(local.regions_without_premium_support, replace(lower(location), " ", ""))
    ])}) don't support Premium SKU. These regions will automatically use Standard SKU instead. This is handled gracefully and won't cause deployment failures."
  }
}
