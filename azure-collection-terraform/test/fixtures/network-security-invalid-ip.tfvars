# Invalid IP CIDR format (missing /prefix)
# Should fail validation
eventhub_enable_network_security = true

sumologic_ip_whitelist = [
  "13.52.5.14",  # Missing /32
  "192.168.1.0/24"
]
