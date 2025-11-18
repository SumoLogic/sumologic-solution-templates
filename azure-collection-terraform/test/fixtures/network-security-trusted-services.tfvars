# Network security with trusted services enabled
# Tests trusted_service_access_enabled configuration
eventhub_enable_network_security  = true
eventhub_default_network_action   = "Deny"
eventhub_trusted_services_enabled = true

sumologic_ip_whitelist = [
  "13.52.5.14/32"
]
