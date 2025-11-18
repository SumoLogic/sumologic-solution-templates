# Invalid default_network_action value
# Should fail validation (only "Allow" or "Deny" permitted)
eventhub_enable_network_security = true
eventhub_default_network_action  = "Block"  # Invalid value
