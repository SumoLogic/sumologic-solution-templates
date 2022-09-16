locals {
  apps_folder_id_decimal = parseint(sumologic_folder.root_apps_folder.id, 16)
}
output "ApplicationComponentAppsFolder" {

  value       = "${local.sumologic_service_endpoint}/ui/#/library/folder/${local.apps_folder_id_decimal}"
  description = "Go to this link to view the apps folder"
}

output "ApplicationComponentMonitorsFolder" {
  value       = "${local.sumologic_service_endpoint}/ui/#/monitoring/unified-monitors/${sumologic_monitor_folder.root_monitor_folder.id}"
  description = "Go to this link to view the monitors folder"
}
