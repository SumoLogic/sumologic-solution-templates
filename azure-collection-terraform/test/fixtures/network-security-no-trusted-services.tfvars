# Network security with trusted services disabled
# Tests trusted_service_access_enabled = false
eventhub_enable_network_security  = true
eventhub_default_network_action   = "Deny"
eventhub_trusted_services_enabled = false

sumologic_ip_whitelist = [
  "13.52.5.14/32"
]
