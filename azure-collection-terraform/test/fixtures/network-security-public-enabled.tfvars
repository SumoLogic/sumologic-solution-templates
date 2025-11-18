# Network security with public access enabled
# Tests public_network_access_enabled = true (IP restrictions apply)
eventhub_enable_network_security = true
eventhub_public_network_enabled  = true
eventhub_default_network_action  = "Deny"

sumologic_ip_whitelist = [
  "13.52.5.14/32"
]
