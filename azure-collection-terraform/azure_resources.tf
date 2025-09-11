resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

data "azurerm_resources" "all_target_resources" {
  for_each = toset(var.target_resource_types)
  type     = each.key
  required_tags = var.required_resource_tags
}

resource "azurerm_eventhub_namespace" "namespaces_by_location" {
  for_each = local.resources_by_location_only
  name                = "${var.eventhub_namespace_name}-${replace(lower(each.key), " ", "")}"
  location            = each.key
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = var.throughput_units
  tags = {
    version = local.solution_version
  }
}

resource "azurerm_eventhub" "eventhubs_by_type_and_location" {
  for_each = local.resources_by_type_and_location
  name              = "eventhub-${replace(each.key, "/", "-")}"
  namespace_id      = azurerm_eventhub_namespace.namespaces_by_location[each.value[0].location].id
  partition_count   = 4
  message_retention = 7
}

resource "azurerm_eventhub_namespace_authorization_rule" "sumo_collection_policy" {
  for_each = azurerm_eventhub_namespace.namespaces_by_location
  name                = var.policy_name
  namespace_name      = each.value.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = false
}

data "azurerm_monitor_diagnostic_categories" "all_categories" {
  for_each    = local.resources_by_location
  resource_id = each.value.id
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting_logs" {
  for_each = local.resources_by_location
  name                         = "diag-${replace(replace(each.value.name, "/", "-"), ".", "-")}"
  target_resource_id           = each.value.id
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy[each.value.location].id
  eventhub_name = azurerm_eventhub.eventhubs_by_type_and_location["${each.value.type}-${each.value.location}"].name

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.all_categories[each.key].log_category_types
    content {
      category = enabled_log.value
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_eventhub_namespace" "activity_logs_namespace" {
  count               = var.enable_activity_logs ? 1 : 0
  name                = "${var.eventhub_namespace_name}-activity-logs"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = var.throughput_units
}

resource "azurerm_eventhub_namespace_authorization_rule" "activity_logs_policy" {
  count               = var.enable_activity_logs ? 1 : 0
  name                = var.policy_name
  namespace_name      = azurerm_eventhub_namespace.activity_logs_namespace[0].name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = false
}

resource "azurerm_eventhub" "eventhub_for_activity_logs" {
  count             = var.enable_activity_logs ? 1 : 0
  name              = var.activity_log_export_name
  namespace_id      = azurerm_eventhub_namespace.activity_logs_namespace[0].id
  partition_count   = 4
  message_retention = 7
}

resource "azurerm_monitor_diagnostic_setting" "activity_logs_to_event_hub" {
  count                        = var.enable_activity_logs ? 1 : 0
  name                         = var.activity_log_export_name
  target_resource_id           = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  eventhub_name                = azurerm_eventhub.eventhub_for_activity_logs[0].name
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.activity_logs_policy[0].id

  enabled_log {
    category = "Administrative"
  }
  enabled_log {
    category = "Security"
  }
  enabled_log {
    category = "ServiceHealth"
  }
  enabled_log {
    category = "Alert"
  }
  enabled_log {
    category = "Recommendation"
  }
  enabled_log {
    category = "Policy"
  }
  enabled_log {
    category = "Autoscale"
  }
}
