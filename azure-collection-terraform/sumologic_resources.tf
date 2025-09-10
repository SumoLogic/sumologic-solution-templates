# have to use version as hardcoded because during apply command latest always tries to update app resource and fails if the app with latest version is already installed
# resource "sumologic_app" "azure_storage_app" {
#     uuid = "53376d23-2687-4500-b61e-4a2e2a119658"
#     version = "1.0.3"
#     count = contains(local.apps_to_install, "Azure Storage") ? 1 : 0
#     parameters = {
#         "index_value": var.index_value
#     }
# }

resource "sumologic_collector" "sumo_collector" {
  name   = join("-", [var.sumo_collector_name, var.azure_subscription_id])
  description = "Azure Collector"
  fields = {
    tenant_name = "azure_account"
  }
}

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

resource "sumologic_azure_metrics_source" "terraform_azure_metrics_source" {
  for_each = {
    for k, v in local.metrics_source_groups : k => v
    if length(data.azurerm_resources.all_target_resources[k].resources) > 0
  }

  name              = replace(replace(each.key, "/", "-"), ".", "-")
  description       = "Metrics for ${each.key}"
  category          = "azure/${lower(replace(replace(each.key, "/", "-"), ".", "-"))}/metrics"
  content_type      = "AzureMetrics"
  collector_id      = sumologic_collector.sumo_collector.id

  authentication {
    type          = "AzureClientSecretAuthentication"
    tenant_id     = var.azure_tenant_id
    client_id     = var.azure_client_id
    client_secret = var.azure_client_secret
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