# Sumo Logic - SDO Terraform

# This script creates Webhooks to Sumo Logic in Atlassian Systems.
# Configure the Atlassian credentials in the atlassian.auto.tfvars.

# Remove slash from Sumo Logic opsgenie_api_url

locals {
  opsgenie_api_url_fixed = replace(var.opsgenie_api_url, "com/", "com")
}

# Create/Delete OpsGenie to Sumo Logic Webhook by calling REST API
provider "restapi" {
  uri = local.opsgenie_api_url_fixed
  # debug                = true
  write_returns_object = true
  headers              = { Content-Type = "application/json", Authorization = "GenieKey ${var.opsgenie_key}" }
}

data "template_file" "data_json" {
  count      = "${var.install_opsgenie}" == "collection" || "${var.install_opsgenie}" == "all" ? 1 : 0
  depends_on = [sumologic_http_source.opsgenie]
  template   = "${file("${path.module}/templates/opsgenie_to_sumo_webhook.json.tmpl")}"
  vars = {
    url = sumologic_http_source.opsgenie[0].url
  }
}

resource "restapi_object" "ops_to_sumo_webhook" {
  count = "${var.install_opsgenie}" == "collection" || "${var.install_opsgenie}" == "all" ? 1 : 0
  path  = "/v2/integrations"
  # debug = true
  id_attribute = "data/id"
  data         = data.template_file.data_json[0].rendered
}

# JIRA Cloud Provider
provider "jira" {
  url      = var.jira_cloud_url
  user     = var.jira_cloud_user
  password = var.jira_cloud_password
}

# Create/Delete Jira Cloud to Sumo Logic Webhook
resource "jira_webhook" "sumo_jira" {
  count  = "${var.install_jira_cloud}" == "collection" || "${var.install_jira_cloud}" == "all" ? 1 : 0
  name   = "Sumologic Hook"
  url    = sumologic_http_source.jira_cloud[0].url
  jql    = var.jira_cloud_jql
  events = var.jira_cloud_events # See https://developer.atlassian.com/cloud/jira/platform/webhooks/ for supported events
}

# JIRA Server Provider
provider "jira" {
  alias    = "server"
  url      = var.jira_server_url
  user     = var.jira_server_user
  password = var.jira_server_password
}

# Create/Delete Jira Server to Sumo Logic Webhook
resource "jira_webhook" "sumo_jira_server" {
  provider = jira.server
  count    = "${var.install_jira_server}" == "collection" || "${var.install_jira_server}" == "all" ? 1 : 0
  name     = "Sumologic Hook"
  url      = sumologic_http_source.jira_server[0].url
  jql      = var.jira_server_jql
  events   = var.jira_server_events # See https://developer.atlassian.com/server/jira/platform/webhooks/ for supported events
}

# BitBucket Provider
provider "bitbucket" {
  username = var.bitbucket_cloud_user
  password = var.bitbucket_cloud_password
}

# Create/Delete BitBucket to Sumo Logic Webhook
resource "bitbucket_hook" "sumo_bitbucket" {
  count       = "${var.install_bitbucket_cloud}" == "collection" || "${var.install_bitbucket_cloud}" == "all" ? length(var.bitbucket_cloud_repos) : 0
  owner       = var.bitbucket_cloud_owner
  repository  = var.bitbucket_cloud_repos[count.index]
  url         = sumologic_http_source.bitbucket_cloud[0].url
  description = var.bitbucket_cloud_desc
  events      = var.bitbucket_cloud_events
}