# Multiple valid metrics source filters with different filter types
target_resource_types = [{
  metric_namespace = "Microsoft.ServiceBus/Namespaces"
  metrics_source_filters = [
    {
      filter_type = "Include"
      name        = "Include production resources"
      regexp      = ".*\"resourceId\".*prod.*"
    },
    {
      filter_type = "Exclude"
      name        = "Exclude test resources"
      regexp      = ".*\"resourceId\".*test.*"
    },
    {
      filter_type = "Mask"
      name        = "Mask subscription IDs"
      regexp      = "(\"subscriptionId\"\\s*:\\s*\"[^\"]+\")"
      mask        = "MASKED_SUBSCRIPTION"
    },
  ]
}]
