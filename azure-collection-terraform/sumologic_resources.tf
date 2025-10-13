resource "sumologic_app" "apps" {
  for_each = {
    for app in var.installation_apps_list : app.name => app
  }

  uuid    = each.value.uuid
  version = each.value.version

  parameters = {
    "index_value" = var.index_value
  }
}

resource "sumologic_collector" "sumo_collector" {
  name        = join("-", [var.sumo_collector_name, var.azure_subscription_id != null ? var.azure_subscription_id : data.azurerm_client_config.current.subscription_id])
  description = "Azure Collector"
  fields = {
    tenant_name = "azure_account"
  }
}

resource "sumologic_azure_event_hub_log_source" "sumo_azure_event_hub_log_source" {
  for_each = {
    for k, v in azurerm_eventhub.eventhubs_by_type_and_location : k => v
    if length([
      for config in var.target_resource_types :
      config if config.log_namespace == local.eventhub_key_to_log_namespace[k] &&
      config.log_namespace != null &&
      config.log_namespace != ""
    ]) > 0
  }

  name         = each.value.name
  description  = "Azure Logs Source for ${each.key}"
  category     = "azure/logs/${each.key}"
  content_type = "AzureEventHubLog"
  collector_id = sumologic_collector.sumo_collector.id

  authentication {
    type = "AzureEventHubAuthentication"
    shared_access_policy_name = azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy[
      local.resources_by_type_and_location[each.key][0].location
    ].name
    shared_access_policy_key = azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy[
      local.resources_by_type_and_location[each.key][0].location
    ].primary_key
  }

  path {
    type = "AzureEventHubPath"
    namespace = azurerm_eventhub_namespace.namespaces_by_location[
      local.resources_by_type_and_location[each.key][0].location
    ].name
    event_hub_name = each.value.name
    consumer_group = "$Default"
    region         = "Commercial"
  }
}

resource "sumologic_azure_metrics_source" "terraform_azure_metrics_source" {
  for_each = {
    for k, v in local.metrics_source_groups : k => v
    if v.enabled == true && length(flatten(v.regions)) > 0
  }

  name         = replace(replace(each.key, "/", "-"), ".", "-")
  description  = "Metrics for ${each.key}"
  category     = "azure/${lower(replace(replace(each.key, "/", "-"), ".", "-"))}/metrics"
  content_type = "AzureMetrics"
  collector_id = sumologic_collector.sumo_collector.id

  authentication {
    type          = "AzureClientSecretAuthentication"
    tenant_id     = var.azure_tenant_id != null ? var.azure_tenant_id : data.azurerm_client_config.current.tenant_id
    client_id     = var.azure_client_id != null ? var.azure_client_id : data.azurerm_client_config.current.client_id
    client_secret = var.azure_client_secret != null ? var.azure_client_secret : ""
  }

  path {
    type                = "AzureMetricsPath"
    environment         = "Azure"
    limit_to_regions    = flatten([for region in each.value.regions : [for r in region : lower(r)]])
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

resource "sumologic_azure_event_hub_log_source" "sumo_activity_log_source" {
  count = var.enable_activity_logs ? 1 : 0

  name         = var.activity_log_export_name
  description  = "Azure Subscription Activity Logs"
  category     = var.activity_log_export_category
  content_type = "AzureEventHubLog"
  collector_id = sumologic_collector.sumo_collector.id

  authentication {
    type                      = "AzureEventHubAuthentication"
    shared_access_policy_name = azurerm_eventhub_namespace_authorization_rule.activity_logs_policy[0].name
    shared_access_policy_key  = azurerm_eventhub_namespace_authorization_rule.activity_logs_policy[0].primary_key
  }

  path {
    type           = "AzureEventHubPath"
    namespace      = azurerm_eventhub_namespace.activity_logs_namespace[0].name
    event_hub_name = azurerm_eventhub.eventhub_for_activity_logs[0].name
    consumer_group = "$Default"
    region         = "Commercial"
  }
}