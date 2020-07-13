# Sumo Logic - SDP Terraform

# This script creates Webhooks to Sumo Logic in Pagerduty Services.
# Configure the Pagerduty credentials in the pagerduty.auto.tfvars.

# Configure the Pagerduty Provider
provider "pagerduty" {
  token = var.pagerduty_api_key
}

data "pagerduty_extension_schema" "webhook" {
  name = "Generic V2 Webhook"
}

# Create Webhook in Pagerduty
resource "pagerduty_extension" "sumologic_extension"{
  count = "${var.install_pagerduty}" ? length(var.pagerduty_services) : 0
  name = "Sumo Logic Webhook"
  endpoint_url = sumologic_http_source.pagerduty[0].url
  extension_schema = data.pagerduty_extension_schema.webhook.id
  extension_objects    = [var.pagerduty_services[count.index]]
}

data "pagerduty_vendor" "sumologic" {
  name = "Sumo Logic"
}

# We need to create Service Key for each service for Sumo Logic to Pagerduty Webhook
resource "pagerduty_service_integration" "sumologic_service" {
  count = "${var.install_sumo_to_pagerduty_webhook}" ? length(var.pagerduty_services) : 0
  name    = data.pagerduty_vendor.sumologic.name
  service = var.pagerduty_services[count.index]
  vendor  = data.pagerduty_vendor.sumologic.id
}