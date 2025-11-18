# Network security enabled with valid IP whitelist
# Tests IP whitelisting with valid CIDR blocks
eventhub_enable_network_security  = true
eventhub_public_network_enabled   = true
eventhub_default_network_action   = "Deny"
eventhub_trusted_services_enabled = true

sumologic_ip_whitelist = [
  "13.52.5.14/32",
  "13.52.80.64/32",
  "54.193.127.96/27"
]
