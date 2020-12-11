# Sumo Logic - SDO Terraform

# This script creates Webhooks to Sumo Logic in Pagerduty Services.
# Configure the Pagerduty credentials in the pagerduty.auto.tfvars.

# Configure the Pagerduty Provider
provider "pagerduty" {
  skip_credentials_validation = "true"
  token = var.pagerduty_api_key
}

data "pagerduty_extension_schema" "webhook" {
  count = "${var.install_pagerduty}" == "collection" || "${var.install_pagerduty}" == "all" ? length(var.pagerduty_services_pagerduty_webhooks) : 0
  name = "Generic V2 Webhook"
}

# Create Webhook in Pagerduty
resource "pagerduty_extension" "sumologic_extension" {
  count             = length(data.pagerduty_extension_schema.webhook) > 0 && "${var.install_pagerduty}" == "collection" || "${var.install_pagerduty}" == "all" ? length(var.pagerduty_services_pagerduty_webhooks) : 0
  name              = "Sumo Logic Webhook"
  endpoint_url      = sumologic_http_source.pagerduty[0].url
  extension_schema  = data.pagerduty_extension_schema.webhook[0].id
  extension_objects = [var.pagerduty_services_pagerduty_webhooks[count.index]]
}

data "pagerduty_vendor" "sumologic" {
  count = "${var.install_pagerduty}" == "collection" || "${var.install_pagerduty}" == "all" ? length(var.pagerduty_services_pagerduty_webhooks) : 0
  name = "Sumo Logic"
}

# We need to create Service Key for each service for Sumo Logic to Pagerduty Webhook
resource "pagerduty_service_integration" "sumologic_service" {
  count   = length(data.pagerduty_vendor.sumologic) > 0 && "${var.install_sumo_to_pagerduty_webhook}" ? length(var.pagerduty_services_sumo_webhooks) : 0
  name    = data.pagerduty_vendor.sumologic[0].name
  service = var.pagerduty_services_sumo_webhooks[count.index]
  vendor  = data.pagerduty_vendor.sumologic[0].id
}