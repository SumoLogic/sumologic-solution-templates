# Sumo Logic - SDO Terraform

# This script creates WebhooksV3 to Sumo Logic in Pagerduty Services, Account and Teams.
# Configure the Pagerduty credentials in the pagerdutyv3.auto.tfvars.

# Create v3 webhook for service/services in PagerDuty
resource "pagerduty_webhook_subscription" "service_webhook" {
  count = (("${var.install_pagerduty}" == "collection" || "${var.install_pagerduty}" == "all") && "${var.install_pagerduty_version}" == "v3") ? length(var.create_services_webhooks) : 0
  delivery_method {
    type = "http_delivery_method"
    url = sumologic_http_source.pagerduty[0].url
  }
  description = "Sends PagerDuty v3 webhook events to Sumo"
  events = [
    "incident.acknowledged",
    "incident.annotated",
    "incident.delegated",
    "incident.escalated",
    "incident.priority_updated",
    "incident.reassigned",
    "incident.reopened",
    "incident.resolved",
    "incident.responder.added",
    "incident.responder.replied",
    "incident.status_update_published",
    "incident.triggered",
    "incident.unacknowledged",
    "service.created",
    "service.deleted",
    "service.updated"
  ]
  active = true
  filter {
    id = "${var.create_services_webhooks[count.index]}"
    type = "service_reference"
  }
  type = "webhook_subscription"
}

# Send service level alerts to PagerDuty
data "pagerduty_vendor" "v3_service_sumologic" {
  count = (("${var.install_pagerduty}" == "collection" || "${var.install_pagerduty}" == "all") && "${var.install_pagerduty_version}" == "v3") ? length(var.create_services_webhooks) : 0
  name = "Sumo Logic"
}

# We need to create Service Key for each service for Sumo Logic to Pagerduty Webhook
resource "pagerduty_service_integration" "sumologic_v3_service" {
  count   = length(data.pagerduty_vendor.v3_service_sumologic) > 0 && "${var.install_sumo_to_pagerduty_webhook}" ? length(var.pagerduty_services_sumo_webhooks) : 0
  name    = data.pagerduty_vendor.v3_service_sumologic[0].name
  service = var.pagerduty_services_sumo_webhooks[count.index]
  vendor  = data.pagerduty_vendor.v3_service_sumologic[0].id
}

# Create v3 webhook for account in PagerDuty
resource "pagerduty_webhook_subscription" "account_webhook" {
  count = (("${var.install_pagerduty}" == "collection" || "${var.install_pagerduty}" == "all") && "${var.install_pagerduty_version}" == "v3") ? ("${var.create_account_webhook}" == true ? 1 : 0) : 0
  delivery_method {
    type = "http_delivery_method"
    url = sumologic_http_source.pagerduty[0].url
  }
  description = "Sends PagerDuty v3 webhook events to Sumo"
  events = [
    "incident.acknowledged",
    "incident.annotated",
    "incident.delegated",
    "incident.escalated",
    "incident.priority_updated",
    "incident.reassigned",
    "incident.reopened",
    "incident.resolved",
    "incident.responder.added",
    "incident.responder.replied",
    "incident.status_update_published",
    "incident.triggered",
    "incident.unacknowledged",
    "service.created",
    "service.deleted",
    "service.updated"
  ]
  active = true
  filter {
    type = "account_reference"
  }
  type = "webhook_subscription"
}

# TODO for account level alerts
data "pagerduty_vendor" "v3_account_sumologic" {
  count = (("${var.install_pagerduty}" == "collection" || "${var.install_pagerduty}" == "all") && "${var.install_pagerduty_version}" == "v3" && "${var.create_account_webhook}") == "yes" ? 1 : 0
  name = "Sumo Logic"
}

# Create v3 webhook for team/teams in PagerDuty
resource "pagerduty_webhook_subscription" "team_webhook" {
  count = (("${var.install_pagerduty}" == "collection" || "${var.install_pagerduty}" == "all") && "${var.install_pagerduty_version}" == "v3") ? length(var.create_teams_webhooks) : 0
  delivery_method {
    type = "http_delivery_method"
    url = sumologic_http_source.pagerduty[0].url
  }
  description = "Sends PagerDuty v3 webhook events to Sumo"
  events = [
    "incident.acknowledged",
    "incident.annotated",
    "incident.delegated",
    "incident.escalated",
    "incident.priority_updated",
    "incident.reassigned",
    "incident.reopened",
    "incident.resolved",
    "incident.responder.added",
    "incident.responder.replied",
    "incident.status_update_published",
    "incident.triggered",
    "incident.unacknowledged",
    "service.created",
    "service.deleted",
    "service.updated"
  ]
  active = true
  filter {
    id = "${var.create_teams_webhooks[count.index]}"
    type = "team_reference"
  }
  type = "webhook_subscription"
}

# TODO for team level alerts
data "pagerduty_vendor" "v3_team_sumologic" {
  count = (("${var.install_pagerduty}" == "collection" || "${var.install_pagerduty}" == "all") && "${var.install_pagerduty_version}" == "v3") ? length(var.create_teams_webhooks) : 0
  name = "Sumo Logic"
}
