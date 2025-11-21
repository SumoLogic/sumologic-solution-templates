# Invalid metrics source filters - mask with colons
# This should fail Sumo Logic API validation
target_resource_types = [{
  metric_namespace = "Microsoft.ServiceBus/Namespaces"
  metrics_source_filters = [
    {
      filter_type = "Mask"
      name        = "Invalid mask with colons"
      regexp      = "(\\d{16})"
      mask        = "INVALID:MASK:VALUE"  # Colons not allowed in mask strings
    },
  ]
}]
