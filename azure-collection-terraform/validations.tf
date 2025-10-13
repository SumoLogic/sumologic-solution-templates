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