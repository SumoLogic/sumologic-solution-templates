# Hybrid configuration with both IP whitelist and VNet (Advanced - Uncommon Scenario)
# Tests combined security model: Sumo Logic (public IPs) + internal Azure services (VNet)
# NOTE: Typically not needed - most deployments only need IP whitelisting
# Use only if you have both:
# - Sumo Logic accessing from internet (requires public IPs)
# - Internal Azure services pushing data directly to EventHub (uncommon)
eventhub_enable_network_security = true
eventhub_default_network_action  = "Deny"

sumologic_ip_whitelist = [
  "13.52.5.14/32",
  "13.52.80.64/32",
  "54.193.127.96/27"
]

eventhub_vnet_subnet_ids = [
  "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/app-subnet",
  "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/data-subnet"
]
