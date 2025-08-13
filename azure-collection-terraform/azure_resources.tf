# multiple location
# separate source module
# multiple namespace
# # Todo Create a policy

# Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create an Event Hub Namespace
resource "azurerm_eventhub_namespace" "namespace" {
  name                = var.eventhub_namespace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = var.throughput_units

  # Todo take tags from vars file and iterate over multiple tags
  tags = {
    version = local.solution_version
  }
}

# Create an Event Hub
# resource "azurerm_eventhub" "eventhub" {
#   name                = var.eventhub_name
#   namespace_id        = azurerm_eventhub_namespace.namespace.id
# 
#   # 1 partition = 1 MB/sec
#   partition_count     = 4
#   message_retention   = 7
# }


resource "azurerm_eventhub" "eventhub" {
  for_each = toset(var.target_resource_ids)

  # Generate a unique name for each Event Hub based on the resource ID.
  # We use the resource name (e.g., "TFtest001") as part of the Event Hub name.
  name = "eh-${replace(element(split("/", each.value), length(split("/", each.value)) - 3), ".", "-")}"

  namespace_id = azurerm_eventhub_namespace.namespace.id

  # You can keep these settings as they are, or parameterize them.
  partition_count   = 4
  message_retention = 7
}


# Create a Shared Access Policy with listen permissions
resource "azurerm_eventhub_namespace_authorization_rule" "sumo_collection_policy" {
  name                = var.policy_name
  namespace_name      = azurerm_eventhub_namespace.namespace.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = false
  manage              = false
}

