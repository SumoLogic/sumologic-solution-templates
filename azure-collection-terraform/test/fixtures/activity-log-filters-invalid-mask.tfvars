# Invalid filter - mask string with colons (should fail)
enable_activity_logs = true

activity_log_filters = [
  {
    filter_type = "Mask"
    name        = "Invalid mask with colons"
    regexp      = "(\\\"password\\\"\\s*:\\s*\\\"[^\\\"]+\\\")"
    mask        = "\"password\":\"REDACTED\""  # Contains colons - should fail
  },
]
