# Non-existent IP file
# Tests graceful handling of missing file (should use empty string)
eventhub_enable_network_security = true
sumologic_ip_whitelist_file      = "test/fixtures/non-existent-file.txt"
