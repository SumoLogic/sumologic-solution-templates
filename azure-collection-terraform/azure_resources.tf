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
resource "azurerm_eventhub" "eventhub" {
  name                = var.eventhub_name
  namespace_id        = azurerm_eventhub_namespace.namespace.id

  # 1 partition = 1 MB/sec
  partition_count     = 4
  message_retention   = 7
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

# Sumo Collection sources
resource "sumologic_collector" "sumo_collector" {
  # Todo collector name from the variable
  # Todo add tenant subscription in collector to uniquely identify
  name          =  "Azure Observability Collector"
  description = "created via terraform"

  # name        = local.collector_name
  # description = var.sumologic_collector_details.description
  # fields      = var.sumologic_collector_details.fields
  # timezone    = "UTC"
  fields  = {
    tenant_name = "azure_account"
  }
}

resource "sumologic_azure_event_hub_log_source" "sumo_azure_event_hub_log_source" {
    # Todo separate
    name          =  "Azure Logs Source"
    description = "created via terraform uses ${var.eventhub_name}"
    category      = "azure/eventhub/logs"
    content_type  = "AzureEventHubLog"
    collector_id  = "${sumologic_collector.sumo_collector.id}"
    depends_on = [azurerm_eventhub.eventhub]
    authentication {
      type = "AzureEventHubAuthentication"
      shared_access_policy_name = var.policy_name
      shared_access_policy_key = azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy.primary_key
    }
    path {
      type = "AzureEventHubPath"
      namespace     = azurerm_eventhub_namespace.namespace.name
      event_hub_name = var.eventhub_name
      consumer_group = "$Default"
      # Todo test for US Gov, take it as separate variable
      region = "Commercial"
    }
}

data "azurerm_client_config" "current" {}

resource "sumologic_azure_metrics_source" "sumo_azure_event_hub_metrics_source" {
    # one source for all regions
    # Todo take region as input
    # Todo take namespaces as input
    name          =  "Azure Metrics Source"
    description = "created via terraform uses Azure Monitor API"
    category      = "azure/eventhub/metrics"
    content_type  = "AzureMetrics"
    collector_id  = "${sumologic_collector.sumo_collector.id}"
    authentication {
      type = "AzureClientSecretAuthentication"
      tenant_id = data.azurerm_client_config.current.tenant_id
      # Todo create client id and client secret with contributors role and use service using script and use the same in providers and below
      # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret
      client_id = var.azure_client_id
      client_secret = var.azure_client_secret
    }
    path {
      type = "AzureMetricsPath"
      limit_to_namespaces = ["Microsoft.Web/sites"]
    }
    lifecycle {
      ignore_changes = [authentication.0.client_secret]
    }
}


data "azurerm_eventhub_namespace_authorization_rule" "default_rule" {
 name                = "RootManageSharedAccessKey"
 namespace_name      = var.eventhub_namespace_name
 resource_group_name = azurerm_resource_group.rg.name
 depends_on = [azurerm_eventhub_namespace.namespace]
}

# Todo for each for each target resource
data "azurerm_monitor_diagnostic_categories" "function_app_category" {
  # Todo take in variable
  resource_id = var.target_resource_ids[0]
}

# Todo Create a autosubscribe function to create diagnostic settings
# Create a Diagnostic Setting for Function App logs
resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting_logs" {
  name               = "sumo_export_logs"
  eventhub_name = var.eventhub_name
  target_resource_id = var.target_resource_ids[0]
  eventhub_authorization_rule_id  = data.azurerm_eventhub_namespace_authorization_rule.default_rule.id

  # Select the resource from the list https://learn.microsoft.com/en-gb/azure/azure-monitor/platform/resource-logs-schema#service-specific-schemas
  # Select the category from the link opened from above link for example for function app it opens this link - https://learn.microsoft.com/en-us/azure/azure-functions/monitor-functions-reference?tabs=consumption-plan#resource-logs


  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.function_app_category.log_category_types

    content {
      category = enabled_log.value
    }
  }


  metric {
    category = "AllMetrics"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  # dynamic log {
  #   for_each = sort(data.azurerm_monitor_diagnostic_categories.default.logs)
  #   content {
  #     category = log.value
  #     enabled  = true

  #     retention_policy {
  #       enabled = true
  #       days    = 30
  #     }
  #   }
  # }

  # # this needs to be here with enabled = false to prevent TF from showing changes happening with each plan/apply
  # dynamic metric {
  #   for_each = sort(data.azurerm_monitor_diagnostic_categories.default.metrics)
  #   content {
  #     category = metric.value
  #     enabled  = false

  #     retention_policy {
  #       enabled = false
  #       days    = 0
  #     }
  #   }
  # }

  # metric {
  #   category = "AllMetrics"
  # }

  # logs {
  #   category = "Function Application Logs"
  #   enabled  = true
  #   retention_policy {
  #     enabled = false
  #   }
  # }

  # metrics {
  #   category = "AllMetrics"
  #   enabled  = true
  #   retention_policy {
  #     enabled = false
  #   }
  # }
}

# data "azurerm_storage_account" "main" {
#   name                = "allbloblogseastus"
#   resource_group_name = azurerm_resource_group.rg.name
# }

# resource "azurerm_monitor_diagnostic_setting" "main" {
#    name               = "sumo_export_logs"
#   eventhub_name = var.eventhub_name
#    target_resource_id = "${data.azurerm_storage_account.main.id}/blobServices/default"
#    eventhub_authorization_rule_id  = data.azurerm_eventhub_namespace_authorization_rule.default_rule.id
#    enabled_log {
#     category = "StorageRead"
#    }

#    enabled_log {
#     category = "StorageWrite"
#    }

#    enabled_log {
#     category = "StorageDelete"
#    }
#  }

