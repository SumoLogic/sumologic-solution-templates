output "atlassian_collector_id" {
  value = sumologic_collector.atlassian_collector.id
}

output "jira_cloud_source_id" {
  value = sumologic_http_source.jira_cloud.*.id
}

output "bitbucket_cloud_source_id" {
  value = sumologic_http_source.bitbucket_cloud.*.id
}

output "jira_server_source_id" {
  value = sumologic_http_source.jira_server.*.id
}

output "opsgenie_source_id" {
  value = sumologic_http_source.opsgenie.*.id
}

output "pagerduty_source_id" {
  value = sumologic_http_source.pagerduty.*.id
}

output "github_source_id" {
  value = sumologic_http_source.github.*.id
}

output "folder_id" {
  value = sumologic_folder.folder.id
}

# output "folder_path" {
#   value = sumologic_folder.folder.path
# }

output "sumo_pagerduty_webhook_id" {
  value = sumologic_connection.pagerduty_connection.*.id
}

output "sumo_opsgenie_webhook_id" {
  value = sumologic_connection.opsgenie_connection.*.id
}

output "sumo_jiracloud_webhook_id" {
  value = sumologic_connection.jira_cloud_connection.*.id
}

output "sumo_jiraserver_webhook_id" {
  value = sumologic_connection.jira_server_connection.*.id
}

output "sumo_jiraservicedesk_webhook_id" {
  value = sumologic_connection.jira_service_desk_connection.*.id
}

output "bitbucket_webhook_id" {
  value = bitbucket_hook.sumo_bitbucket.*.id
}

output "opsgenie_webhook_id" {
  value = restapi_object.ops_to_sumo_webhook.*.id
}
