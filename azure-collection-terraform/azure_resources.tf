resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Use the `azurerm_resources` data source to dynamically get all resources of the specified types.
data "azurerm_resources" "all_target_resources" {
  for_each = toset(var.target_resource_types)
  type     = each.key
}

locals {
  # This map correctly groups all discovered resources by their ID.
  resources_by_location = {
    for res in flatten([
      for type, resources in data.azurerm_resources.all_target_resources : resources.resources
    ]) : res.id => res
  }

  # This map groups all discovered resources by a composite key of type and location,
  # producing a map where each key contains a LIST of resources. This is necessary for
  # creating unique event hubs per type-location combination.
  resources_by_type_and_location = {
    for res in flatten([
      for type, resources in data.azurerm_resources.all_target_resources : resources.resources
    ]) : "${res.type}-${res.location}" => res...
  }

  # This map now groups resources by location only.
  resources_by_location_only = {
    for res in values(local.resources_by_location) :
    res.location => res...
  }

  # This creates a unique list of all regions where the resources exist.
  unique_locations = distinct([for res in values(local.resources_by_location) : res.location])

  # Groups resources by their parent resource to simplify metric filtering logic.
  grouped_filters = {
    for filter in local.tag_filters :
    (length(split("/", filter.namespace)) > 2 ? join("/", slice(split("/", filter.namespace), 0, length(split("/", filter.namespace)) - 1)) : filter.namespace) => filter...
  }

  metrics_source_groups = {
    for parent_namespace, filters in local.grouped_filters : parent_namespace => {
      namespaces  = [for filter in filters : filter.namespace]
      tag_filters = filters
    }
  }

  tag_filters = [
    {
      type      = "AzureTagFilters"
      namespace = "Microsoft.ServiceBus/Namespaces"
      tags = {
        name   = "test-name-1"
        values = ["value1", "value2"]
      }
    },
    {
      type      = "AzureTagFilters"
      namespace = "Microsoft.Storage/storageAccounts/blobServices"
      tags = {
        name   = "test-name-2"
        values = ["value3"]
      }
    },
    {
      type      = "AzureTagFilters"
      namespace = "Microsoft.Storage/storageAccounts/fileServices"
      tags = {
        name   = "test-name-2"
        values = ["value3"]
      }
    },
    {
      type      = "AzureTagFilters"
      namespace = "Microsoft.Storage/storageAccounts/tableServices"
      tags = {
        name   = "test-name-2"
        values = ["value3"]
      }
    },
    {
      type      = "AzureTagFilters"
      namespace = "Microsoft.Storage/storageAccounts/queueServices"
      tags = {
        name   = "test-name-2"
        values = ["value3"]
      }
    },
    {
      type      = "AzureTagFilters"
      namespace = "Microsoft.KeyVault/vaults"
      tags = {
        name   = "test-name-2"
        values = ["value3"]
      }
    }
  ]
}

# Dynamically create a single Event Hub Namespace for each unique location.
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

# Dynamically create a single Event Hub for each unique resource type and location.
resource "azurerm_eventhub" "eventhubs_by_type_and_location" {
  for_each = local.resources_by_type_and_location

  name              = "eventhub-${replace(each.key, "/", "-")}"
  namespace_id      = azurerm_eventhub_namespace.namespaces_by_location[each.value[0].location].id
  partition_count   = 4
  message_retention = 7
}

# Create an authorization rule for each Event Hub Namespace.
resource "azurerm_eventhub_namespace_authorization_rule" "sumo_collection_policy" {
  for_each = azurerm_eventhub_namespace.namespaces_by_location

  name                = var.policy_name
  namespace_name      = each.value.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = false
}

resource "sumologic_collector" "sumo_collector" {
  name        = join("-", [var.sumo_collector_name, var.azure_subscription_id])
  description = "Azure Collector"
  fields = {
    tenant_name = "azure_account"
  }
}

# Create a Sumo Logic log source for each Event Hub, ensuring the names match.
resource "sumologic_azure_event_hub_log_source" "sumo_azure_event_hub_log_source" {
  for_each = azurerm_eventhub.eventhubs_by_type_and_location

  name         = each.value.name
  description  = "Azure Logs Source for ${each.key}"
  category     = "azure/logs/${each.key}"
  content_type = "AzureEventHubLog"
  collector_id = sumologic_collector.sumo_collector.id

  authentication {
    type                      = "AzureEventHubAuthentication"
    shared_access_policy_name = azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy[local.resources_by_type_and_location[each.key][0].location].name
    shared_access_policy_key  = azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy[local.resources_by_type_and_location[each.key][0].location].primary_key
  }

  path {
    type           = "AzureEventHubPath"
    namespace      = azurerm_eventhub_namespace.namespaces_by_location[local.resources_by_type_and_location[each.key][0].location].name
    event_hub_name = each.value.name
    consumer_group = "$Default"
    region         = "Commercial"
  }
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

resource "sumologic_azure_metrics_source" "terraform_azure_metrics_source" {
  for_each = local.metrics_source_groups

  name         = replace(replace(each.key, "/", "-"), ".", "-")
  description  = "Metrics for ${each.key}"
  category     = "azure/${lower(replace(replace(each.key, "/", "-"), ".", "-"))}/metrics"
  content_type = "AzureMetrics"
  collector_id = sumologic_collector.sumo_collector.id

  authentication {
    type          = "AzureClientSecretAuthentication"
    tenant_id     = var.azure_tenant_id
    client_id     = var.azure_client_id
    client_secret = var.azure_client_secret
  }

  path {
    type              = "AzureMetricsPath"
    environment       = "Azure"
    limit_to_namespaces = each.value.namespaces

    dynamic "azure_tag_filters" {
      for_each = each.value.tag_filters
      content {
        type      = azure_tag_filters.value.type
        namespace = azure_tag_filters.value.namespace
        tags {
          name   = azure_tag_filters.value.tags.name
          values = azure_tag_filters.value.tags.values
        }
      }
    }
  }
}

data "azurerm_client_config" "current" {}

# resource "azurerm_eventhub" "eventhub_for_activity_logs" {
#   name              = var.activity_log_export_name
#   namespace_id      = azurerm_eventhub_namespace.namespaces_by_location[lower(replace(var.location, " ", ""))].id
#   partition_count   = 4
#   message_retention = 7
# }

# resource "azurerm_monitor_diagnostic_setting" "activity_logs_to_event_hub" {
#   name                         = var.activity_log_export_name
#   target_resource_id           = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
#   eventhub_name                = azurerm_eventhub.eventhub_for_activity_logs.name
#   eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy[lower(replace(var.location, " ", ""))].id

  # Manually define the categories for activity logs
#   enabled_log {
#     category = "Administrative"
#   }
#   enabled_log {
#     category = "Security"
#   }
#   enabled_log {
#     category = "ServiceHealth"
#   }
#   enabled_log {
#     category = "Alert"
#   }
#   enabled_log {
#     category = "Recommendation"
#   }
#   enabled_log {
#     category = "Policy"
#   }
#   enabled_log {
#     category = "Autoscale"
#   }
# }

# resource "sumologic_azure_event_hub_log_source" "sumo_activity_log_source" {
#   name         = var.activity_log_export_name
#   description  = "Azure Subscription Activity Logs"
#   category     = var.activity_log_export_category
#   content_type = "AzureEventHubLog"
#   collector_id = sumologic_collector.sumo_collector.id

#   authentication {
#     type                      = "AzureEventHubAuthentication"
#     shared_access_policy_name = azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy[lower(replace(var.location, " ", ""))].name
#     shared_access_policy_key  = azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy[lower(replace(var.location, " ", ""))].primary_key
#   }

#   path {
#    type           = "AzureEventHubPath"
#     namespace      = azurerm_eventhub_namespace.namespaces_by_location[lower(replace(var.location, " ", ""))].name
#     event_hub_name = azurerm_eventhub.eventhub_for_activity_logs.name
#     consumer_group = "$Default"
#     region         = "Commercial"
#   }
# }