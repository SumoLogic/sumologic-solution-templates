# This script creates Sumo Logic Webhooks. Uses Sumo Logic provider configured in sumologic.tf
# Configure the Sumo Logic credentials in the sumologic.auto.tvars and other system credentials in respective files.

# Create/Delete Sumo Logic to Pagerduty Webhook
resource "sumologic_connection" "pagerduty_connection" {
  count       = "${var.install_sumo_to_pagerduty_webhook}" ? length(var.pagerduty_services_sumo_webhooks) : 0
  type        = "WebhookConnection"
  name        = "Pagerduty Connection for Service - ${var.pagerduty_services_sumo_webhooks[count.index]}"
  description = "Created via Sumo Logic SDO Terraform Script."
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
  count       = "${var.install_sumo_to_opsgenie_webhook}" ? 1 : 0
  type        = "WebhookConnection"
  name        = "Opsgenie Webhook"
  description = "Created via Sumo Logic SDO Terraform Script."
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
  count       = "${var.install_sumo_to_jiracloud_webhook}" ? 1 : 0
  type        = "WebhookConnection"
  name        = "Jira Cloud Webhook"
  description = "Created via Sumo Logic SDO Terraform Script."
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
  count       = "${var.install_sumo_to_jiraserver_webhook}" ? 1 : 0
  type        = "WebhookConnection"
  name        = "Jira Server Webhook"
  description = "Created via Sumo Logic SDO Terraform Script."
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
  count       = "${var.install_sumo_to_jiraservicedesk_webhook}" ? 1 : 0
  type        = "WebhookConnection"
  name        = "Jira Service Desk Webhook"
  description = "Created via Sumo Logic SDO Terraform Script."
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