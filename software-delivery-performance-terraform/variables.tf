#Sumo Logic - SDP Terraform

variable "sumo_access_id" {}
variable "sumo_access_key" {}
variable "deployment" {}
variable "sumo_api_endpoint" {}
variable "app_installation_folder" {
  default = "Software Delivery Performance"
}
variable "collector_name" {
  default = "Software Delivery Performance"
}

#Apps
variable "install_jira_cloud" {}
variable "install_bitbucket_cloud" {}
variable "install_opsgenie" {}
variable "install_sumo_to_opsgenie_webhook" {}
variable "install_jira_server" {}
variable "install_atlassian_app" {}
variable "install_sumo_to_jiracloud_webhook" {}
variable "install_sumo_to_jiraserver_webhook" {}
variable "install_sumo_to_jiraservicedesk_webhook" {}


#Jira Cloud
variable "jira_cloud_url" {}
variable "jira_cloud_user" {}
variable "jira_cloud_password" {}
variable "jira_cloud_jql" {}
variable "jira_cloud_events" {}

# Sumologic to Jira Cloud Webhook
variable "jira_cloud_issuetype" {}
variable "jira_cloud_priority" {}
variable "jira_cloud_projectkey" {}
variable "jira_cloud_auth" {}

# Sumologic to Jira Service Desk Webhook
variable "jira_servicedesk_url" {}
variable "jira_servicedesk_issuetype" {}
variable "jira_servicedesk_priority" {}
variable "jira_servicedesk_projectkey" {}
variable "jira_servicedesk_auth" {}

# Jira Server
variable "jira_server_access_logs_sourcecategory" {}
variable "jira_server_url" {}
variable "jira_server_user" {}
variable "jira_server_password" {}
variable "jira_server_jql" {}
variable "jira_server_events" {}

# Sumologic to Jira Server Webhook
variable "jira_server_issuetype" {}
variable "jira_server_priority" {}
variable "jira_server_projectkey" {}
variable "jira_server_auth" {}

# Bitbucket Cloud
variable "bitbucket_cloud_user" {}
variable "bitbucket_cloud_password" {}
variable "bitbucket_cloud_owner" {}
variable "bitbucket_cloud_repos" {}
variable "bitbucket_cloud_desc" {}
variable "bitbucket_cloud_events" {}

# Opsgenie
variable "opsgenie_key" {}
variable "opsgenie_api_url" {
  default = "https://api.opsgenie.com"
}

# Sumologic to Opsgenie Webhook
variable "opsgenie_priority" {}

# Pagerduty
variable install_pagerduty      {}
variable pagerduty_api_endpoint {
  default = "https://api.pagerduty.com"
}
variable "pagerduty_api_key" {}
variable "pagerduty_services" {}
variable "install_sumo_to_pagerduty_webhook" {}

#Github
variable "install_github" {}
variable "github_token" {}
variable "github_organization" {}
variable "github_repository_names" {}
variable "github_repo_events" {}
variable "github_org_events" {}
variable "create_github_org_webhook" {}