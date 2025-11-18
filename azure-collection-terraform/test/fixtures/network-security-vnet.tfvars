# Network security with VNet integration (Advanced - Uncommon Scenario)
# Tests VNet subnet ID configuration for internal Azure services
# NOTE: Not typically needed for Sumo Logic integration
# Use only if you have Azure VMs/AKS/App Services pushing data to EventHub
eventhub_enable_network_security = true
eventhub_default_network_action  = "Deny"

eventhub_vnet_subnet_ids = [
  "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/app-subnet",
  "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/data-subnet"
]
