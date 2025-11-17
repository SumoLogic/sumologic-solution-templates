# Valid log source filters configuration
target_resource_types = [{
  log_namespace    = "Microsoft.ServiceBus/namespaces"
  metric_namespace = "Microsoft.ServiceBus/Namespaces"
  log_source_filters = [
    {
      filter_type = "Include"
      name        = "Include specific resources"
      regexp      = ".*\"resourceId\"\\s*:\\s*\"[^\"]*test[^\"]*\".*"
      regions     = ["East US"]
    },
    {
      filter_type = "Mask"
      name        = "Mask credit cards"
      regexp      = "(\\d{16})"
      mask        = "XXXX-XXXX-XXXX-XXXX"
    },
  ]
}]
