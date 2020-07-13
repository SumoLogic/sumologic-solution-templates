# This script creates Sumo Logic Collector and Sources.
# Configure the Sumo Logic credentials in the sumologic.auto.tvars.

# Sumo Logic Provider
provider "sumologic" {
  access_id   = var.sumo_access_id
  access_key  = var.sumo_access_key
  environment = var.deployment
}

# Create/Delete Collector
resource "sumologic_collector" "atlassian_collector" {
  name     = var.collector_name
  category = "SDP"
}

# Create/Delete Jira Cloud Source
resource "sumologic_http_source" "jira_cloud" {
  count        = "${var.install_jira_cloud}" ? 1 : 0
  name         = "Jira Cloud"
  category     = "SDP/Jira/Cloud"
  collector_id = sumologic_collector.atlassian_collector.id
}

# Create/Delete BitBucket Cloud Source
resource "sumologic_http_source" "bitbucket_cloud" {
  count        = "${var.install_bitbucket_cloud}" ? 1 : 0
  name         = "Bitbucket Cloud"
  category     = "SDP/Bitbucket"
  fields       = {"_convertHeadersToFields"="true"}
  collector_id = sumologic_collector.atlassian_collector.id
}

# Create/Delete Jira Server Source
resource "sumologic_http_source" "jira_server" {
  count        = "${var.install_jira_server}" ? 1 : 0
  name         = "Jira Server"
  category     = "SDP/Jira/Events"
  collector_id = sumologic_collector.atlassian_collector.id
}

# Create/Delete OpsGenie Source
resource "sumologic_http_source" "opsgenie" {
  count        = "${var.install_opsgenie}" ? 1 : 0
  name         = "OpsGenie"
  category     = "SDP/Opsgenie"
  collector_id = sumologic_collector.atlassian_collector.id
}

# Create/Delete Pagerduty Source
resource "sumologic_http_source" "pagerduty" {
  count        = "${var.install_pagerduty}" ? 1 : 0
  name         = "Pagerduty"
  category     = "SDP/Pagerduty"
  collector_id = sumologic_collector.atlassian_collector.id
}

# Create/Delete Github Source
resource "sumologic_http_source" "github" {
  count        = "${var.install_github}" ? 1 : 0
  name         = "Github"
  category     = "SDP/Github"
  fields       = {"_convertHeadersToFields"="true"}
  collector_id = sumologic_collector.atlassian_collector.id
}

# Sumo Logic - Create/Delete folder for installing the applications
data "sumologic_personal_folder" "personalFolder" {}

resource "sumologic_folder" "folder" {
  name        = var.app_installation_folder
  description = "Atlassian Applications"
  parent_id   = data.sumologic_personal_folder.personalFolder.id
  depends_on  = [sumologic_collector.atlassian_collector]
}

# Remove slash from Sumo Logic sumo_api_endpoint

locals {
  sumo_api_endpoint_fixed = replace(var.sumo_api_endpoint, "api/", "api")
}

# Install Apps
# Install Jira Cloud
resource "null_resource" "install_jira_cloud_app" {
  count      = "${var.install_jira_cloud}" ? 1 : 0
  depends_on = [sumologic_http_source.jira_cloud]

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/019757ca-3b08-457c-bd15-7239f1ab66c9/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Jira Cloud", "description": "The Sumo Logic App for Jira Cloud provides insights into project management issues that enable you to more effectively plan, assign, track, report, and manage work across multiple teams.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"jiralogsrc": "_sourceCategory = SDP/Jira/Cloud" }}'
    EOT
  }
}

# Install Jira Server
resource "null_resource" "install_jira_server_app" {
  count      = "${var.install_jira_server}" ? 1 : 0
  depends_on = [sumologic_http_source.jira_server]

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/ec905b32-e514-4c63-baac-0efa3b3a2109/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Jira", "description": "The Sumo Logic App for Jira provides insight into Jira usage, request activity, issues, security, sprint events, and user events.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"jiralogsrc": "_sourceCategory = ${var.jira_server_access_logs_sourcecategory}", "jirawebhooklogsrc": "_sourceCategory = SDP/Jira/Events" }}'
    EOT
  }
}

# Install Bitbucket
resource "null_resource" "install_bitbucket_cloud_app" {
  count      = "${var.install_bitbucket_cloud}" ? 1 : 0
  depends_on = [sumologic_http_source.bitbucket_cloud]

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/3b068c67-069e-417e-a855-ff7549a0606d/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Bitbucket", "description": "The Sumo Logic App for Bitbucket provides insights into project management to more effectively plan the deployments.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"bblogsrc": "_sourceCategory = SDP/Bitbucket" }}'
    EOT
  }
}

# Install Opsgenie
resource "null_resource" "install_Opsgenie_app" {
  count      = "${var.install_opsgenie}" ? 1 : 0
  depends_on = [sumologic_http_source.opsgenie]

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/05bf2074-0487-486f-8359-3d878fbc1c49/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Opsgenie", "description": "The Opsgenie App provides at-a-glance views and detailed analytics for alerts on your DevOps environment.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"opsgenieLogSrc": "_sourceCategory = SDP/Opsgenie" }}'
    EOT
  }
}

# Install Pagerduty App
resource "null_resource" "install_pagerduty_app" {
  count = "${var.install_pagerduty}" ? 1 : 0
  depends_on = [sumologic_http_source.pagerduty]

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/589857e0-e4c1-4165-8212-f656899a3b95/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Pagerduty V2", "description": "The Sumo Logic App for PagerDuty V2 collects incident messages from your PagerDuty account via a webhook, and displays that incident data in pre-configured Dashboards, so you can monitor and analyze the activity of your PagerDuty account and Services.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"logsrcpd": "_sourceCategory = SDP/Pagerduty"}}'
    EOT
  }
}

# Install Github App
resource "null_resource" "install_github_app" {
  count = "${var.install_github}" ? 1 : 0
  depends_on = [sumologic_http_source.github]

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/86289912-b909-426e-8154-bda55b9ee902/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Github", "description": "The Sumo Logic App for GitHub connects to your GitHub repository at the Organization or Repository level, and ingests GitHub events via a webhook.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"paramId123": "_sourceCategory = SDP/Github"}}'
    EOT
  }
}

# Create/Delete Sumo Logic to Pagerduty Webhook
resource "sumologic_connection" "pagerduty_connection" {
  count        = "${var.install_sumo_to_pagerduty_webhook}" ? length(var.pagerduty_services) : 0
  type        = "WebhookConnection"
  name        = "Pagerduty Connection for Service - ${var.pagerduty_services[count.index]}"
  description = "Created via Sumo Logic SDP Terraform Script."
  url         = "https://events.pagerduty.com/generic/2010-04-15/create_event.json"
  headers = {
    "X-Header" : "Token token=${var.pagerduty_api_key}"
  }

  default_payload = <<JSON
{
	"service_key": "${pagerduty_service_integration.sumologic_service[count.index].integration_key}",
	"event_type": "trigger",
	"description": "Event from Sumo Logic.",
	"client": "Sumo Logic",
	"client_url": "{{SearchQueryUrl}}"
}
JSON
  webhook_type    = "PagerDuty"
}

# Create/Delete Sumo Logic to OpsGenie Webhook
resource "sumologic_connection" "opsgenie_connection" {
  count        = "${var.install_sumo_to_opsgenie_webhook}" ? 1 : 0
  type        = "WebhookConnection"
  name        = "Opsgenie Webhook"
  description = "Created via Sumo Logic SDP Terraform Script."
  url         = "${var.opsgenie_api_url}/v1/json/sumologic?apiKey=${jsondecode(restapi_object.ops_to_sumo_webhook[0].create_response).data.apiKey}"

  default_payload = <<JSON
{
  "searchName": "{{SearchName}}",
  "searchDescription": "{{SearchDescription}}",
  "searchQuery": "{{SearchQuery}}",
  "searchQueryUrl": "{{SearchQueryUrl}}",
  "timeRange": "{{TimeRange}}",
  "fireTime": "{{FireTime}}",
  "rawResultsJson": "{{RawResultsJson}}",
  "numRawResults": "{{NumRawResults}}",
  "priority": "${var.opsgenie_priority}",
  "aggregateResultsJson": "{{AggregateResultsJson}}"
}
JSON
  webhook_type    = "Opsgenie"
}

# Create/Delete Sumo Logic to Jira Cloud Webhook
resource "sumologic_connection" "jira_cloud_connection" {
  count        = "${var.install_sumo_to_jiracloud_webhook}" ? 1 : 0
  type        = "WebhookConnection"
  name        = "Jira Cloud Webhook"
  description = "Created via Sumo Logic SDP Terraform Script."
  url         = "${var.jira_cloud_url}/rest/api/2/issue"
  headers = {
    "X-Header" : "${var.jira_cloud_auth}"
  }

  default_payload = <<JSON
{
  "fields": {
    "issuetype": {
      "name": "${var.jira_cloud_issuetype}"
    },
    "project": {
      "key": "${var.jira_cloud_projectkey}"
    },
    "summary": "{{SearchName}}",
    "priority": {
      "id": "${var.jira_cloud_priority}"
    },
    "description": "{{SearchQueryUrl}}"
  }
}
JSON
  webhook_type    = "Jira"
}

# Create/Delete Sumo Logic to Jira Server Webhook
resource "sumologic_connection" "jira_server_connection" {
  count        = "${var.install_sumo_to_jiraserver_webhook}" ? 1 : 0
  type        = "WebhookConnection"
  name        = "Jira Server Webhook"
  description = "Created via Sumo Logic SDP Terraform Script."
  url         = "${var.jira_server_url}/rest/api/2/issue"
  headers = {
    "X-Header" : "${var.jira_server_auth}"
  }

  default_payload = <<JSON
{
  "fields": {
    "issuetype": {
      "name": "${var.jira_server_issuetype}"
    },
    "project": {
      "key": "${var.jira_server_projectkey}"
    },
    "summary": "{{SearchName}}",
    "priority": {
      "id": "${var.jira_server_priority}"
    },
    "description": "{{SearchQueryUrl}}"
  }
}
JSON
  webhook_type    = "Jira"
}

# Create/Delete Sumo Logic to Jira Service Desk Webhook
resource "sumologic_connection" "jira_service_desk_connection" {
  count        = "${var.install_sumo_to_jiraservicedesk_webhook}" ? 1 : 0
  type        = "WebhookConnection"
  name        = "Jira Service Desk Webhook"
  description = "Created via Sumo Logic SDP Terraform Script."
  url         = "${var.jira_servicedesk_url}/rest/api/2/issue"
  headers = {
    "X-Header" : "${var.jira_servicedesk_auth}"
  }

  default_payload = <<JSON
{
  "fields": {
    "issuetype": {
      "name": "${var.jira_servicedesk_issuetype}"
    },
    "project": {
      "key": "${var.jira_servicedesk_projectkey}"
    },
    "summary": "{{SearchName}}",
    "priority": {
      "id": "${var.jira_servicedesk_priority}"
    },
    "description": "{{SearchQueryUrl}}"
  }
}
JSON
  webhook_type    = "Jira"
}