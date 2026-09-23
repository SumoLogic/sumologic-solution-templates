# Invalid resource type format test (should fail validation)
target_resource_types = [
  {
    log_namespace    = "InvalidFormat" # Missing required slash
    metric_namespace = "InvalidFormat"
  },
  {
    log_namespace    = "NoSlash" # Missing required slash
    metric_namespace = "NoSlash"
  },
  {
    log_namespace    = "Microsoft." # Ends with dot (invalid format)
    metric_namespace = "Microsoft."
  }
]