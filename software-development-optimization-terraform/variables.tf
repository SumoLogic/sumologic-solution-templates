#Sumo Logic - SDO Terraform

terraform {
  experiments = [variable_validation]
}

variable "sumo_access_id" {
  type        = string
  description = "Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"
  validation {
    condition     = length(var.sumo_access_id) > 0
    error_message = "The \"sumo_access_id\" can not be empty."
  }
}
variable "sumo_access_key" {
  type        = string
  description = "Sumo Logic Access Key."
  validation {
    condition     = length(var.sumo_access_key) > 0
    error_message = "The \"sumo_access_key\" can not be empty."
  }
}
variable "deployment" {
  type        = string
  description = "Please update with your deployment, refer: https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"
  validation {
    condition = contains([
      "US1",
    "us1","US2","us2","AU","au","CA","ca","DE","de","EU","eu","FED","fed","JP","jp","IN","in"], var.deployment)
    error_message = "Argument \"deployment\" must be one of \"us1\",\"us2\",\"au\",\"ca\",\"de\",\"eu\",\"fed\",\"jp\",\"in\"."
  }
}
variable "sumo_api_endpoint" {
  type        = string
  validation {
  condition = contains([
  "https://api.au.sumologic.com/api/",
  "https://api.ca.sumologic.com/api/","https://api.de.sumologic.com/api/","https://api.eu.sumologic.com/api/","https://api.fed.sumologic.com/api/","https://api.in.sumologic.com/api/","https://api.jp.sumologic.com/api/","https://api.sumologic.com/api/","https://api.us2.sumologic.com/api/"], var.sumo_api_endpoint)
  error_message = "Argument \"sumo_api_endpoint\" must be one of the values specified at https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security."
}
}
variable "app_installation_folder" {
  default = "Software Development Optimization"
}
variable "collector_name" {
  default = "Software Development Optimization"
}

#Apps
variable "install_jira_cloud" {
  type        = string
  validation {
    condition = contains([
      "all","none","fer","app","collection"], var.install_jira_cloud)
    error_message = "Argument \"install_jira_cloud\" must be one of \"all\",\"none\",\"fer\",\"app\",\"collection\"."
  }
}
variable "install_bitbucket_cloud" {
  type        = string
  validation {
    condition = contains([
      "all","none","fer","app","collection"], var.install_bitbucket_cloud)
    error_message = "Argument \"install_bitbucket_cloud\" must be one of \"all\",\"none\",\"fer\",\"app\",\"collection\"."
  }
}
variable "install_opsgenie" {
  type        = string
  validation {
    condition = contains([
      "all","none","fer","app","collection"], var.install_opsgenie)
    error_message = "Argument \"install_opsgenie\" must be one of \"all\",\"none\",\"fer\",\"app\",\"collection\"."
  }
}
variable "install_sumo_to_opsgenie_webhook" {
  type        = string
  validation {
    condition = contains([
      "true","false"], var.install_sumo_to_opsgenie_webhook)
    error_message = "Argument \"install_sumo_to_opsgenie_webhook\" must be one of \"true\",\"false\"."
  }
}
variable "install_jira_server" {
  type        = string
  validation {
    condition = contains([
      "all","none","fer","app","collection"], var.install_jira_server)
    error_message = "Argument \"install_jira_server\" must be one of \"all\",\"none\",\"fer\",\"app\",\"collection\"."
  }
}
variable "install_sumo_to_jiracloud_webhook" {
  type        = string
  validation {
    condition = contains([
      "true","false"], var.install_sumo_to_jiracloud_webhook)
    error_message = "Argument \"install_sumo_to_jiracloud_webhook\" must be one of \"true\",\"false\"."
  }
}
variable "install_sumo_to_jiraserver_webhook" {
  type        = string
  validation {
    condition = contains([
      "true","false"], var.install_sumo_to_jiraserver_webhook)
    error_message = "Argument \"install_sumo_to_jiraserver_webhook\" must be one of \"true\",\"false\"."
  }
}
variable "install_sumo_to_jiraservicedesk_webhook" {
  type        = string
  validation {
    condition = contains([
      "true","false"], var.install_sumo_to_jiraservicedesk_webhook)
    error_message = "Argument \"install_sumo_to_jiraservicedesk_webhook\" must be one of \"true\",\"false\"."
  }
}
variable "install_jenkins" {
  type        = string
  validation {
    condition = contains([
      "all","none","fer","app","collection"], var.install_jenkins)
    error_message = "Argument \"install_jenkins\" must be one of \"all\",\"none\",\"fer\",\"app\",\"collection\"."
  }
}
variable "install_github" {
  type        = string
  validation {
    condition = contains([
      "all","none","fer","app","collection"], var.install_github)
    error_message = "Argument \"install_github\" must be one of \"all\",\"none\",\"fer\",\"app\",\"collection\"."
  }
}

variable "install_gitlab" {
  type        = string
  validation {
    condition = contains([
      "all","none","fer","app","collection"], var.install_gitlab)
    error_message = "Argument \"install_gitlab\" must be one of \"all\",\"none\",\"fer\",\"app\",\"collection\"."
  }
}

variable "install_pagerduty" {
  type        = string
  validation {
    condition = contains([
      "all","none","fer","app","collection"], var.install_pagerduty)
    error_message = "Argument \"install_pagerduty\" must be one of \"all\",\"none\",\"fer\",\"app\",\"collection\"."
  }
}
variable "install_sdo" {
  type        = string
  validation {
    condition = contains([
      "none","app"], var.install_sdo)
    error_message = "Argument \"install_sdo\" must be one of \"none\",\"app\"."
  }
}

#Source Categories
variable "jira_cloud_sc" {}
variable "jira_server_sc" {}
variable "bitbucket_sc" {}
variable "opsgenie_sc" {}
variable "pagerduty_sc" {}
variable "github_sc" {}
variable "gitlab_sc" {}
variable "jenkins_sc" {}

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
variable pagerduty_api_endpoint {
  default = "https://api.pagerduty.com"
}
variable "pagerduty_api_key" {}
variable "pagerduty_services_pagerduty_webhooks" {}
variable "pagerduty_services_sumo_webhooks" {}
variable "install_sumo_to_pagerduty_webhook" {
  type        = string
  validation {
    condition = contains([
      "true","false"], var.install_sumo_to_pagerduty_webhook)
    error_message = "Argument \"install_sumo_to_pagerduty_webhook\" must be one of \"true\",\"false\"."
  }
}

#Github
variable "github_token" {}
variable "github_organization" {}
variable "github_repository_names" {}
variable "github_repo_events" {}
variable "github_org_events" {}
variable "github_org_webhook_create" {
  type        = string
  validation {
    condition = contains([
      "true","false"], var.github_org_webhook_create)
    error_message = "Argument \"github_org_webhook_create\" must be one of \"true\",\"false\"."
  }
}
variable "github_repo_webhook_create" {
  type        = string
  validation {
    condition = contains([
      "true","false"], var.github_repo_webhook_create)
    error_message = "Argument \"github_repo_webhook_create\" must be one of \"true\",\"false\"."
  }
}

#Gitlab
variable "gitlab_token" {}
variable "gitlab_project_names" {}
variable "gitlab_project_webhook_create" {
  type        = string
  validation {
    condition = contains([
      "true","false"], var.gitlab_project_webhook_create)
    error_message = "Argument \"gitlab_project_webhook_create\" must be one of \"true\",\"false\"."
  }
}
#FERs
variable "github_pull_request_fer_scope" {}
variable "github_pull_request_fer_parse" {}

variable "jenkins_build_fer_scope" {}
variable "jenkins_build_fer_parse" {}

variable "jenkins_deploy_fer_scope" {}
variable "jenkins_deploy_fer_parse" {}

variable "opsgenie_alerts_fer_scope" {}
variable "opsgenie_alerts_fer_parse" {}

variable "bitbucket_pull_request_fer_scope" {}
variable "bitbucket_pull_request_fer_parse" {}

variable "bitbucket_build_fer_scope" {}
variable "bitbucket_build_fer_parse" {}

variable "bitbucket_deploy_fer_scope" {}
variable "bitbucket_deploy_fer_parse" {}

variable "jira_issues_fer_scope" {}
variable "jira_issues_fer_parse" {}

variable "pagerduty_alerts_fer_scope" {}
variable "pagerduty_alerts_fer_parse" {}

variable "jenkins_build_status_fer_scope" {}
variable "jenkins_build_status_fer_parse" {}

variable "gitlab_pull_request_fer_scope" {}
variable "gitlab_pull_request_fer_parse" {}

variable "gitlab_build_request_fer_scope" {}
variable "gitlab_build_request_fer_parse" {}


variable "gitlab_deploy_request_fer_scope" {}
variable "gitlab_deploy_request_fer_parse" {}

variable "gitlab_issue_request_fer_scope" {}
variable "gitlab_issue_request_fer_parse" {}

# User Input varibale names for JobName , DeployName

variable "gitlab_build_jobname" {
  type        = string
  description = "Please enter the build job name for your pipeline:"
  validation {
    condition     = length(var.gitlab_build_jobname) > 0
    error_message = "The build name cannot be empty."
  }
}