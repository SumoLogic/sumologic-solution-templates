output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "sumologic_collector_id" {
  value       = sumologic_collector.sumo_collector.id
  description = "The ID of the Sumo Logic collector"
}

output "sumologic_activity_log_source_id" {
  value       = var.enable_activity_logs ? sumologic_azure_event_hub_log_source.sumo_activity_log_source[0].id : null
  description = "The ID of the Sumo Logic activity log source"
}

output "sumologic_metrics_source_id" {
  value       = length(sumologic_azure_metrics_source.terraform_azure_metrics_source) > 0 ? values(sumologic_azure_metrics_source.terraform_azure_metrics_source)[0].id : null
  description = "The ID of the first Sumo Logic metrics source"
}

output "eventhub_namespace_name" {
  value       = length(azurerm_eventhub_namespace.namespaces_by_location) > 0 ? values(azurerm_eventhub_namespace.namespaces_by_location)[0].name : null
  description = "The name of the first Event Hub namespace"
}

output "eventhub_names" {
  value       = { for k, v in azurerm_eventhub.eventhubs_by_type_and_location : k => v.name }
  description = "Map of Event Hub names by type and location"
}

output "sumologic_log_source_ids" {
  value       = { for k, v in sumologic_azure_event_hub_log_source.sumo_azure_event_hub_log_source : k => v.id }
  description = "Map of Sumo Logic log source IDs by Event Hub"
}

output "installed_apps" {
  value = { for k, v in sumologic_app.apps : k => {
    uuid = v.uuid
    name = k
    id   = v.id
  } }
  description = "Information about installed Sumo Logic apps"
}