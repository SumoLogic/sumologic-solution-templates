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

#Jira Cloud
variable "jira_cloud_url" {}
variable "jira_cloud_user" {}
variable "jira_cloud_password" {}
variable "jira_cloud_jql" {}
variable "jira_cloud_events" {}

# #Jira On Prem - TBD
variable "jira_on_prem_access_logs_sourcecategory" {}
variable "jira_on_prem_url" {}
variable "jira_on_prem_user" {}
variable "jira_on_prem_password" {}
variable "jira_on_prem_jql" {}
variable "jira_on_prem_events" {}

#Bitbucket Cloud
variable "bitbucket_cloud_user" {}
variable "bitbucket_cloud_password" {}
variable "bitbucket_cloud_owner" {}
variable "bitbucket_cloud_repos" {}
variable "bitbucket_cloud_desc" {}
variable "bitbucket_cloud_events" {}

#OpsGenie
variable "opsgenie_key" {}
variable "opsgenie_api_url" {}