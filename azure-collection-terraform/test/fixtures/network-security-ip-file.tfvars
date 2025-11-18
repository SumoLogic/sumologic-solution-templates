# Network security with IP file-based whitelist
# Tests file-based IP whitelisting
eventhub_enable_network_security = true
eventhub_default_network_action  = "Deny"
sumologic_ip_whitelist_file      = "test/fixtures/test-sumologic-ips.txt"
