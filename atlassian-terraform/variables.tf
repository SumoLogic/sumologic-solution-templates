#Sumo Logic - Atlassian Terraform

variable "sumo_access_id" {}
variable "sumo_access_key" {}
variable "environment" {}
variable "sumo_api_endpoint" {}

variable "app_installation_folder" {}

#Apps
variable "install_jira_cloud" {}
variable "install_bitbucket_cloud" {}
variable "install_opsgenie" {}
variable "install_sumo_to_opsgenie_webhook" {}
variable "install_jira_on_prem" {}
variable "install_atlassian_app" {}
variable "install_sumo_to_jiracloud_webhook" {}
variable "install_sumo_to_jiraserver_webhook" {}


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


# Jira On Prem
variable "jira_on_prem_access_logs_sourcecategory" {}
variable "jira_on_prem_url" {}
variable "jira_on_prem_user" {}
variable "jira_on_prem_password" {}
variable "jira_on_prem_jql" {}
variable "jira_on_prem_events" {}

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
variable "opsgenie_api_url" {}

# Sumologic to Opsgenie Webhook
variable "opsgenie_priority" {}