resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_eventhub_namespace" "namespace" {
  name                = var.eventhub_namespace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = var.throughput_units

  tags = {
    version = local.solution_version
  }
}

locals {
  event_hub_names = distinct([
    for res_id in var.target_resource_ids :
    "${replace(element(split("/", res_id), 6), ".", "-")}-${element(split("/", res_id), 7)}"
  ])
}

resource "azurerm_eventhub" "eventhub" {
  for_each = toset(local.event_hub_names)
  
  name            = each.value
  namespace_id    = azurerm_eventhub_namespace.namespace.id
  partition_count   = 4
  message_retention = 7
}

resource "azurerm_eventhub_namespace_authorization_rule" "sumo_collection_policy" {
  name                = var.policy_name
  namespace_name      = azurerm_eventhub_namespace.namespace.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = false
  manage              = false
}

resource "sumologic_collector" "sumo_collector" {
  name        = join("-", [var.sumo_collector_name, var.azure_subscription_id])
  description = "Azure Collector"

  fields = {
    tenant_name = "azure_account"
  }
}

resource "sumologic_azure_event_hub_log_source" "sumo_azure_event_hub_log_source" {
  for_each = azurerm_eventhub.eventhub
  
  name         = "Azure-Logs-Source-${replace(each.key, ".", "-")}"
  description  = "Azure Collector Log Source for ${each.key}"
  category     = "azure/${each.key}/logs"
  content_type = "AzureEventHubLog"
  collector_id = sumologic_collector.sumo_collector.id

  authentication {
    type                      = "AzureEventHubAuthentication"
    shared_access_policy_name = var.policy_name
    shared_access_policy_key  = azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy.primary_key
  }

  path {
    type           = "AzureEventHubPath"
    namespace      = azurerm_eventhub_namespace.namespace.name
    event_hub_name = each.value.name
    consumer_group = "$Default"
    region         = "Commercial"
  }
}

data "azurerm_eventhub_namespace_authorization_rule" "default_rule" {
 name              = "RootManageSharedAccessKey"
 namespace_name    = var.eventhub_namespace_name
 resource_group_name = azurerm_resource_group.rg.name
 depends_on = [azurerm_eventhub_namespace.namespace]
}

data "azurerm_monitor_diagnostic_categories" "all_categories" {
  for_each    = toset(var.target_resource_ids)
  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting_logs" {
  for_each = toset(var.target_resource_ids)

  name                         = "diag-${replace(element(split("/", each.value), 6), ".", "-")}-${element(split("/", each.value), 7)}"
  target_resource_id           = each.value
  eventhub_authorization_rule_id = data.azurerm_eventhub_namespace_authorization_rule.default_rule.id

  eventhub_name = azurerm_eventhub.eventhub["${replace(element(split("/", each.value), 6), ".", "-")}-${element(split("/", each.value), 7)}"].name

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.all_categories[each.value].log_category_types
    content {
      category = enabled_log.value
    }
  }
}