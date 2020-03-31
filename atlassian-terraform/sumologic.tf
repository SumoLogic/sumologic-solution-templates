# This script creates Sumo Logic Collector and Sources for Atlassian Systems.
# Configure the Sumo Logic credentials in the terraform.tvars.

# Sumologic Provider
provider "sumologic" {
access_id = "${var.sumo_access_id}"
access_key = "${var.sumo_access_key}"
environment = "${var.environment}"
}

# Create/Delete Collector
resource "sumologic_collector" "atlassian_collector" {
name = "Atlassian c"
category = "Atlassian"
}

# Create/Delete Jira Cloud Source
resource "sumologic_http_source" "jira_cloud" {
    count = "${var.install_jira_cloud}" ? 1:0
    name = "Jira Cloud"
    category = "Atlassian/Jira/Cloud"
    collector_id = "${sumologic_collector.atlassian_collector.id}"
}

# Create/Delete BitBucket Cloud Source
resource "sumologic_http_source" "bitbucket_cloud" {
    count = "${var.install_bitbucket_cloud}" ? 1:0
    name = "Bitbucket Cloud"
    category = "Atlassian/Bitbucket"
    collector_id = "${sumologic_collector.atlassian_collector.id}"
}

# Create/Delete Jira On Prem Source
resource "sumologic_http_source" "jira_on_prem" {
    count = "${var.install_jira_on_prem}" ? 1:0
    name = "Jira On-prem"
    category = "Atlassian/Jira/Events"
    collector_id = "${sumologic_collector.atlassian_collector.id}"
}

# Create/Delete OpsGenie Source
resource "sumologic_http_source" "opsgenie" {
    count = "${var.install_opsgenie}" ? 1:0
    name = "OpsGenie"
    category = "Atlassian/Opsgenie"
    collector_id = "${sumologic_collector.atlassian_collector.id}"
}

# Sumo Logic - Create/Delete folder for installing the applications
data "sumologic_personal_folder" "personalFolder" {}

resource "sumologic_folder" "folder" {
  name        = "${var.app_installation_folder}"
  description = "Atlassian Applications"
  parent_id   = "${data.sumologic_personal_folder.personalFolder.id}"
  depends_on  = [sumologic_collector.atlassian_collector]
}

# Install Apps
# Install Jira Cloud
resource "null_resource" "install_jira_cloud_app" {
 count = "${var.install_jira_cloud}" ? 1:0
 depends_on = [sumologic_http_source.jira_cloud]

 provisioner "local-exec" {
     command = <<EOT
     curl -s --request POST '${var.sumo_api_endpoint}apps/019757ca-3b08-457c-bd15-7239f1ab66c9/install' \
        --header 'Accept: application/json' \
        --header 'Content-Type: application/json' \
        -u "${var.sumo_access_id}:${var.sumo_access_key}" \
        --data-raw '{ "name": "Jira Cloud", "description": "The Sumo Logic App for Jira Cloud provides insights into project management issues that enable you to more effectively plan, assign, track, report, and manage work across multiple teams.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"jiralogsrc": "_sourceCategory = Atlassian/Jira/Cloud" }}'
EOT
 }
}

# Install Jira Onprem
resource "null_resource" "install_jira_on_prem_app" {
 count = "${var.install_jira_on_prem}" ? 1:0
 depends_on = [sumologic_http_source.jira_on_prem]

 provisioner "local-exec" {
     command = <<EOT
     curl -s --request POST '${var.sumo_api_endpoint}apps/ec905b32-e514-4c63-baac-0efa3b3a2109/install' \
        --header 'Accept: application/json' \
        --header 'Content-Type: application/json' \
        -u "${var.sumo_access_id}:${var.sumo_access_key}" \
        --data-raw '{ "name": "Jira", "description": "The Sumo Logic App for Jira provides insight into Jira usage, request activity, issues, security, sprint events, and user events.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"jiralogsrc": "_sourceCategory = ${var.jira_on_prem_access_logs_sourcecategory}", "jirawebhooklogsrc": "_sourceCategory = Atlassian/Jira/Events" }}'
EOT
 }
}

# Install Bitbucket
resource "null_resource" "install_bitbucket_cloud_app" {
 count = "${var.install_bitbucket_cloud}" ? 1:0
 depends_on = [sumologic_http_source.bitbucket_cloud]

 provisioner "local-exec" {
     command = <<EOT
     curl -s --request POST '${var.sumo_api_endpoint}apps/3b068c67-069e-417e-a855-ff7549a0606d/install' \
        --header 'Accept: application/json' \
        --header 'Content-Type: application/json' \
        -u "${var.sumo_access_id}:${var.sumo_access_key}" \
        --data-raw '{ "name": "Bitbucket", "description": "The Sumo Logic App for Bitbucket provides insights into project management to more effectively plan the deployments.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"bblogsrc": "_sourceCategory = Atlassian/Bitbucket" }}'
EOT
 }
}

# Install Opsgenie
resource "null_resource" "install_Opsgenie_app" {
 count = "${var.install_opsgenie}" ? 1:0
 depends_on = [sumologic_http_source.opsgenie]

 provisioner "local-exec" {
     command = <<EOT
     curl -s --request POST '${var.sumo_api_endpoint}apps/05bf2074-0487-486f-8359-3d878fbc1c49/install' \
        --header 'Accept: application/json' \
        --header 'Content-Type: application/json' \
        -u "${var.sumo_access_id}:${var.sumo_access_key}" \
        --data-raw '{ "name": "Opsgenie", "description": "The Opsgenie App provides at-a-glance views and detailed analytics for alerts on your DevOps environment.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"opsgenieLogSrc": "_sourceCategory = Atlassian/Opsgenie" }}'
EOT
 }
}

# Install Atlassian Solution App
resource "null_resource" "install_atlassian_app" {
 count = "${var.install_atlassian_app}" ? 1:0
 #depends_on = [sumologic_http_source.opsgenie]

 provisioner "local-exec" {
     command = <<EOT
     curl -s --request POST '${var.sumo_api_endpoint}apps/332afd45-eb37-4d65-85b5-21eaead37f6b/install' \
        --header 'Accept: application/json' \
        --header 'Content-Type: application/json' \
        -u "${var.sumo_access_id}:${var.sumo_access_key}" \
        --data-raw '{ "name": "Atlassian", "description": "The Atlassian App provides insights into critical data across Atlassian applications, including Jira Cloud, Jira Server, Bitbucket, Atlassian Access, and OpsGenie from one pane-of-glass in a seamless dashboard experience.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"oglogsrc": "_sourceCategory = Atlassian/Opsgenie","jiralogsrc": "_sourceCategory = Atlassian/Jira/Cloud","bblogsrc": "_sourceCategory = Atlassian/Bitbucket" }}'
EOT
 }
}

# Create/Delete Sumo Logic to OpsGenie Webhook i.e. Connection in Sumo Logic by calling REST API
# https://help.sumologic.com/Manage/Connections-and-Integrations/Webhook-Connections/Webhook_Connection_for_Opsgenie
provider "restapi" {
  alias = "sumo"
  uri                  = "${var.sumo_api_endpoint}"
# debug                = true
  write_returns_object = true
  username = "${var.sumo_access_id}"
  password = "${var.sumo_access_key}"
  headers = {Content-Type = "application/json"}
}

#Below value is the opsgenie id of the opsgenie to sumo webhook, retrieved in atlassian.tf
#locals {
#  value_opsgenie = jsondecode(restapi_object.ops_to_sumo_webhook[0].create_response).data.apiKey
#}

data "template_file" "data_json_sto" {
  count = "${var.install_sumo_to_opsgenie_webhook}" ? 1:0
  template = "${file("${path.module}/sumo_to_opsgenie_webhook.json.tmpl")}"
  vars = {
    url = "${var.opsgenie_api_url}/v1/json/sumologic?apiKey=${jsondecode(restapi_object.ops_to_sumo_webhook[0].create_response).data.apiKey}",
    opsgenie_priority = "${var.opsgenie_priority}"
  }
}

resource "restapi_object" "sumo_to_opsgenie_webhook" {
  provider = restapi.sumo
  count = "${var.install_sumo_to_opsgenie_webhook}" ?1:0
  path = "/connections"
  destroy_path = "/connections/{id}?type=WebhookConnection"
# debug = true
  id_attribute = "id"
  data = "${data.template_file.data_json_sto[0].rendered}"
}

# Create/Delete Sumo Logic to Jira Cloud Webhook i.e. Connection in Sumo Logic by calling REST API
# https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Cloud
data "template_file" "data_json_stjc" {
  count = "${var.install_sumo_to_jiracloud_webhook}" ? 1:0
  template = "${file("${path.module}/sumo_to_jiracloud_webhook.json.tmpl")}"
  vars = {
    url = "${var.jira_cloud_url}/rest/api/2/issue",
    jira_cloud_issuetype = "${var.jira_cloud_issuetype}"
    jira_cloud_priority = "${var.jira_cloud_priority}"
    jira_cloud_projectkey = "${var.jira_cloud_projectkey}"
    jira_cloud_auth = "${var.jira_cloud_auth}"
  }
}

resource "restapi_object" "sumo_to_jiracloud_webhook" {
  provider = restapi.sumo
  count = "${var.install_sumo_to_jiracloud_webhook}" ?1:0
  path = "/connections"
  destroy_path = "/connections/{id}?type=WebhookConnection"
  id_attribute = "id"
  data = "${data.template_file.data_json_stjc[0].rendered}"
}

# Create/Delete Sumo Logic to Jira Server Webhook i.e. Connection in Sumo Logic by calling REST API
# https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Server
data "template_file" "data_json_stjs" {
  count = "${var.install_sumo_to_jiraserver_webhook}" ? 1:0
  template = "${file("${path.module}/sumo_to_jiraserver_webhook.json.tmpl")}"
  vars = {
    url = "${var.jira_on_prem_url}/rest/api/2/issue",
    jira_server_issuetype = "${var.jira_server_issuetype}"
    jira_server_priority = "${var.jira_server_priority}"
    jira_server_projectkey = "${var.jira_server_projectkey}"
    jira_server_auth = "${var.jira_server_auth}"
  }
}

resource "restapi_object" "sumo_to_jiraserver_webhook" {
  provider = restapi.sumo
  count = "${var.install_sumo_to_jiraserver_webhook}" ?1:0
  path = "/connections"
  destroy_path = "/connections/{id}?type=WebhookConnection"
  id_attribute = "id"
  data = "${data.template_file.data_json_stjs[0].rendered}"
}