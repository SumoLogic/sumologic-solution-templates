# Invalid VNet subnet ID format
# Should fail validation
eventhub_enable_network_security = true

eventhub_vnet_subnet_ids = [
  "invalid-subnet-id",
  "/subscriptions/bad-format"
]
