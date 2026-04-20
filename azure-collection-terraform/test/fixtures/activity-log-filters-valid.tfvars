# Activity log filters configuration
enable_activity_logs = true

activity_log_filters = [
  {
    filter_type = "Include"
    name        = "Include Write operations"
    regexp      = ".*\"operationName\"\\s*:\\s*\"[^\"]*write[^\"]*\".*"
  },
  {
    filter_type = "Mask"
    name        = "Mask sensitive data"
    regexp      = "(\\\"password\\\"\\s*:\\s*\\\"[^\\\"]+\\\")"
    mask        = "***REDACTED***"
  },
]
