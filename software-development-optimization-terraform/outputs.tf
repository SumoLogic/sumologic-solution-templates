output "sdo_collector_id" {
  value = sumologic_collector.sdo_collector.id
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

output "gitlab_source_id" {
  value = sumologic_http_source.gitlab.*.id
}
output "folder_id" {
  value = data.external.folder_data_json.result.id
}

output "circleci_app_source_id" {
  value = sumologic_http_source.circleci.*.id
}

output "circleci_orb_job_source_id" {
  value = sumologic_http_source.circleci_orb_job.*.id
}

output "circleci_orb_workflow_source_id" {
  value = sumologic_http_source.circleci_orb_workflow.*.id
}

# output "folder_name" {
#   value = sumologic_folder.folder.name
# }

# output "folder_path" {
#   value = sumologic_folder.folder.path
# }

output "sumo_pagerduty_v2_webhook_id" {
  value = sumologic_connection.pagerduty_v2_connection.*.id
}

output "sumo_pagerduty_v3_webhook_id" {
  value = sumologic_connection.pagerduty_v3_connection.*.id
}

output "sumo_pagerduty_v2_webhook_integration_key" {
  value = pagerduty_service_integration.sumologic_v2_service.*.integration_key
}

output "sumo_pagerduty_v3_webhook_integration_key" {
  value = pagerduty_service_integration.sumologic_v3_service.*.integration_key
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

output "pagerduty_v2_webhook_id" {
  value = pagerduty_extension.sumologic_extension.*.id
}

output "pagerduty_v3_service_webhook_id" {
  value = pagerduty_webhook_subscription.service_webhook.*.id
}

output "pagerduty_v3_account_webhook_id" {
  value = pagerduty_webhook_subscription.account_webhook.*.id
}

output "pagerduty_v3_team_webhook_id" {
  value = pagerduty_webhook_subscription.team_webhook.*.id
}

# output "github_repo_webhook_id" {
#   value = "${zipmap(github_repository_webhook.github_sumologic_repo_webhook.*.repository, github_repository_webhook.github_sumologic_repo_webhook.*.id)}"
# }

# output "github_org_webhook_id" {
#   value = github_organization_webhook.github_sumologic_org_webhook.*.id
# }

output "sumo_github_field_id" {
  value = restapi_object.github_field.*.id
}

output "sumo_gitlab_field_id" {
  value = restapi_object.gitlab_field.*.id
}

output "sumo_bitbucket_field_id" {
  value = restapi_object.github_field.*.id
}

output "bitbucket_build_fer_id" {
  value = sumologic_field_extraction_rule.bitbucket_build_fer.*.id
}

output "bitbucket_push_fer_id" {
  value = sumologic_field_extraction_rule.bitbucket_push_fer.*.id
}

output "bitbucket_deploy_fer_id" {
  value = sumologic_field_extraction_rule.bitbucket_deploy_fer.*.id
}

output "jira_issues_fer_id" {
  value = sumologic_field_extraction_rule.jira_issues_fer.*.id
}

output "pagerduty_alerts_v2_fer_id" {
  value = sumologic_field_extraction_rule.pagerduty_alerts_v2_fer.*.id
}

output "pagerduty_alerts_v3_fer_id" {
  value = sumologic_field_extraction_rule.pagerduty_alerts_v3_fer.*.id
}

output "github_pr_fer_id" {
  value = sumologic_field_extraction_rule.github_pr_fer.*.id
}

output "github_push_fer_id" {
  value = sumologic_field_extraction_rule.github_push_fer.*.id
}

output "gitlab_pr_fer_id" {
  value = sumologic_field_extraction_rule.gitlab_pr_fer.*.id
}

output "gitlab_br_fer_id" {
  value = sumologic_field_extraction_rule.gitlab_build_fer.*.id
}

output "gitlab_deploy_fer_id" {
  value = sumologic_field_extraction_rule.gitlab_deploy_fer.*.id
}

output "gitlab_issue_fer_id" {
  value = sumologic_field_extraction_rule.gitlab_issue_fer.*.id
}

output "gitlab_push_fer_id" {
  value = sumologic_field_extraction_rule.gitlab_push_fer.*.id
}

output "jenkins_build_fer_id" {
  value = sumologic_field_extraction_rule.jenkins_build_fer.*.id
}

output "jenkins_deploy_fer_id" {
  value = sumologic_field_extraction_rule.jenkins_deploy_fer.*.id
}

output "opsgenie_alerts_fer_id" {
  value = sumologic_field_extraction_rule.opsgenie_alerts_fer.*.id
}

output "bitbucket_pr_fer_id" {
  value = sumologic_field_extraction_rule.bitbucket_pr_fer.*.id
}

output "circleci_build_fer_id" {
  value = sumologic_field_extraction_rule.circleci_orb_build_fer.*.id
}

output "circleci_deploy_fer_id" {
  value = sumologic_field_extraction_rule.circleci_orb_deploy_fer.*.id
}

output "circleci_app_source_url" {
  value = sumologic_http_source.circleci.*.url
}

output "circleci_orb_job_source_url" {
  value = sumologic_http_source.circleci_orb_job.*.url
}

output "circleci_orb_workflow_source_url" {
  value = sumologic_http_source.circleci_orb_workflow.*.url
}