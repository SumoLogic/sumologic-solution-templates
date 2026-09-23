# Valid metrics source filters configuration
target_resource_types = [{
  metric_namespace = "Microsoft.ServiceBus/Namespaces"
  metrics_source_filters = [
    {
      filter_type = "Include"
      name        = "Include SBUS002 resources"
      regexp      = ".*\"resourceId\"\\s*:\\s*\"[^\"]*SBUS002[^\"]*\".*"
    },
    {
      filter_type = "Mask"
      name        = "Mask sensitive IDs"
      regexp      = "(\\d{16})"
      mask        = "MASKED_ID"
    },
  ]
}]
