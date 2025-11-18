# Duplicate IPs across file and variable sources
# Tests that duplicates are removed
eventhub_enable_network_security = true
sumologic_ip_whitelist_file      = "test/fixtures/test-sumologic-ips.txt"

sumologic_ip_whitelist = [
  "13.52.5.14/32",  # Duplicate from file
  "203.0.113.0/24"  # New IP
]
