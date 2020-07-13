# Sumo Logic - SDP Terraform

# This script creates Webhooks to Sumo Logic in Github Repositories.
# Configure the Github credentials in the github.auto.tfvars.

# Configure the GitHub Provider
provider "github" {
  token        = var.github_token
  organization = var.github_organization
}

# Repository Level Webhook
resource "github_repository_webhook" "github_sumologic_webhook" {
    count = "${var.install_github}" ? length(var.github_repository_names) : 0
    repository = var.github_repository_names[count.index]

    configuration {
        url          = sumologic_http_source.github[0].url
        content_type = "json"
        insecure_ssl = false
    }

    active = true

    events = var.github_repo_events
}

# Organization Level Webhook
resource "github_organization_webhook" "github_sumologic_org_webhook" {
    count = "${var.install_github}" ? "${var.create_github_org_webhook}" : 0

    configuration {
            url          = sumologic_http_source.github[0].url
            content_type = "json"
            insecure_ssl = false
    }

    active = true

    events = var.github_org_events
}
