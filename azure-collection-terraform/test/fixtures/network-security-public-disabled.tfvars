# Network security with public access disabled (Advanced - Uncommon Scenario)
# Tests public_network_access_enabled = false (private only, VNet required)
# NOTE: This configuration is NOT compatible with Sumo Logic (external SaaS)
# Only use if EventHub is accessed exclusively by internal Azure services
eventhub_enable_network_security = true
eventhub_public_network_enabled  = false
eventhub_default_network_action  = "Deny"

eventhub_vnet_subnet_ids = [
  "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/app-subnet"
]
