# This script creates Sumo Logic Collector and Sources.
# Configure the Sumo Logic credentials in the sumologic.auto.tvars.

# Sumo Logic Provider
provider "sumologic" {
  access_id   = var.sumo_access_id
  access_key  = var.sumo_access_key
  environment = var.deployment
}

# Create/Delete Collector
resource "sumologic_collector" "sdo_collector" {
  name     = var.collector_name
  category = "SDO"
}

# Create/Delete Jira Cloud Source
resource "sumologic_http_source" "jira_cloud" {
  count        = "${var.install_jira_cloud}" == "collection" || "${var.install_jira_cloud}" == "all" ? 1 : 0
  name         = "Jira Cloud"
  category     = var.jira_cloud_sc
  collector_id = sumologic_collector.sdo_collector.id
}

# Create/Delete BitBucket Cloud Source
resource "sumologic_http_source" "bitbucket_cloud" {
  count        = "${var.install_bitbucket_cloud}" == "collection" || "${var.install_bitbucket_cloud}" == "all" ? 1 : 0
  name         = "Bitbucket Cloud"
  category     = var.bitbucket_sc
  fields       = { "_convertHeadersToFields" = "true" }
  collector_id = sumologic_collector.sdo_collector.id
}

# Create/Delete Jira Server Source
resource "sumologic_http_source" "jira_server" {
  count        = "${var.install_jira_server}" == "collection" || "${var.install_jira_server}" == "all" ? 1 : 0
  name         = "Jira Server"
  category     = var.jira_server_sc
  collector_id = sumologic_collector.sdo_collector.id
}

# Create/Delete OpsGenie Source
resource "sumologic_http_source" "opsgenie" {
  count        = "${var.install_opsgenie}" == "collection" || "${var.install_opsgenie}" == "all" ? 1 : 0
  name         = "OpsGenie"
  category     = var.opsgenie_sc
  collector_id = sumologic_collector.sdo_collector.id
}

# Create/Delete Pagerduty Source
resource "sumologic_http_source" "pagerduty" {
  count        = "${var.install_pagerduty}" == "collection" || "${var.install_pagerduty}" == "all" ? 1 : 0
  name         = "Pagerduty"
  category     = var.pagerduty_sc
  collector_id = sumologic_collector.sdo_collector.id
}

# Create/Delete Github Source
resource "sumologic_http_source" "github" {
  count        = "${var.install_github}" == "collection" || "${var.install_github}" == "all" ? 1 : 0
  name         = "Github"
  category     = var.github_sc
  fields       = { "_convertHeadersToFields" = "true" }
  collector_id = sumologic_collector.sdo_collector.id
}

#Create/Delete Gitlab Source
resource "sumologic_http_source" "gitlab" {
  count        = "${var.install_gitlab}" == "collection" || "${var.install_gitlab}" == "all" ? 1 : 0
  name         = "Gitlab"
  category     = var.gitlab_sc
  fields       = { "_convertHeadersToFields" = "true" }
  collector_id = sumologic_collector.sdo_collector.id
}

# Create/Delete Jenkins Source
resource "sumologic_http_source" "jenkins" {
  count        = "${var.install_jenkins}" == "collection" || "${var.install_jenkins}" == "all" ? 1 : 0
  name         = "Jenkins"
  category     = var.jenkins_sc
  fields       = { "_convertHeadersToFields" = "true" }
  collector_id = sumologic_collector.sdo_collector.id
}


# Create/Delete CircleCI App Source
resource "sumologic_http_source" "circleci" {
  count        = "${var.install_circleci}" == "collection" || "${var.install_circleci}" == "all" ? 1 : 0
  name         = "CircleCI"
  category     = var.circleci_app_sc
  collector_id = sumologic_collector.sdo_collector.id
}

# Create/Delete CircleCI Orb Job Source
resource "sumologic_http_source" "circleci_orb_job" {
  count        = "${var.install_circleci_SDO_plugin}" == "all" || "${var.install_circleci_SDO_plugin}" == "collection" ? 1 : 0
  name         = "CircleCI Orb Job"
  category     = var.circleci_orb_job_sc
  collector_id = sumologic_collector.sdo_collector.id
}

# Create/Delete CircleCI Orb Workflow Source
resource "sumologic_http_source" "circleci_orb_workflow" {
  count        = "${var.install_circleci_SDO_plugin}" == "all" || "${var.install_circleci_SDO_plugin}" == "collection" ? 1 : 0
  name         = "CircleCI Orb Workflow"
  category     = var.circleci_orb_workflow_sc
  collector_id = sumologic_collector.sdo_collector.id
}


# Sumo Logic - Create/Delete folder for installing the applications
data "sumologic_personal_folder" "personalFolder" {}

# Generate timestamp to add to the folder name.
locals {
  time_stamp = formatdate("DD-MMM-YYYY hh:mm:ss", timestamp())
}

# resource "sumologic_folder" "folder" {
#   name        = "${var.app_installation_folder} - ${local.time_stamp}"
#   description = "SDO Applications"
#   parent_id   = data.sumologic_personal_folder.personalFolder.id
#   depends_on  = [sumologic_collector.sdo_collector]
# }

# Remove slash from Sumo Logic sumo_api_endpoint
locals {
  sumo_api_endpoint_fixed = replace(var.sumo_api_endpoint, "api/", "api")
}

# Create Folder
resource "null_resource" "create_folder" {
  depends_on = [sumologic_collector.sdo_collector]
  triggers = {
        version = var.folder_version
  }
  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v2/content/folders' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "${var.app_installation_folder} - ${local.time_stamp}", "description": "SDO Applications", "parentId": "${data.sumologic_personal_folder.personalFolder.id}"}' \
            -o sumo_folder.json
    EOT
  }
}

# Extract Id as Terraform doesn't support complex jsons involving arrays and lists
resource "null_resource" "process_folder_result" {
  depends_on = [null_resource.create_folder]
  triggers = {
        version = var.folder_version
  }
  provisioner "local-exec" {
    command = "python extract_id.py"
  }
}

# Load processed json
data "local_file" "folder_json" {
  depends_on = [null_resource.process_folder_result]
  filename = "${path.module}/sumo_folder_id.json"
}

# Make the json data available
data "external" "folder_data_json" {
  program = ["echo", data.local_file.folder_json.content]
}

# Install Apps
# Install Jira Cloud
resource "null_resource" "install_jira_cloud_app" {
  triggers = {
        version = var.jira_cloud_version
  }
  count      = "${var.install_jira_cloud}" == "app" || "${var.install_jira_cloud}" == "all" ? 1 : 0
  depends_on = [sumologic_http_source.jira_cloud]

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/019757ca-3b08-457c-bd15-7239f1ab66c9/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Jira Cloud", "description": "The Sumo Logic App for Jira Cloud provides insights into project management issues that enable you to more effectively plan, assign, track, report, and manage work across multiple teams.", "destinationFolderId": "${data.external.folder_data_json.result.id}","dataSourceValues": {"jiralogsrc": "_sourceCategory = ${var.jira_cloud_sc}" }}'
    EOT
  }
}

# Install Jira Server
resource "null_resource" "install_jira_server_app" {
  count      = "${var.install_jira_server}" == "app" || "${var.install_jira_server}" == "all" ? 1 : 0
  depends_on = [sumologic_http_source.jira_server]
  triggers = {
        version = var.jira_server_version
  }

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/ec905b32-e514-4c63-baac-0efa3b3a2109/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Jira", "description": "The Sumo Logic App for Jira provides insight into Jira usage, request activity, issues, security, sprint events, and user events.", "destinationFolderId": "${data.external.folder_data_json.result.id}","dataSourceValues": {"jiralogsrc": "_sourceCategory = ${var.jira_server_access_logs_sourcecategory}", "jirawebhooklogsrc": "_sourceCategory = ${var.jira_server_sc}" }}'
    EOT
  }
}

# Install Bitbucket
resource "null_resource" "install_bitbucket_cloud_app" {
  count      = "${var.install_bitbucket_cloud}" == "app" || "${var.install_bitbucket_cloud}" == "all"? 1 : 0
  depends_on = [sumologic_http_source.bitbucket_cloud]
  triggers = {
        version = var.bitbucket_version
  }

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/3b068c67-069e-417e-a855-ff7549a0606d/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Bitbucket", "description": "The Sumo Logic App for Bitbucket provides insights into project management to more effectively plan the deployments.", "destinationFolderId": "${data.external.folder_data_json.result.id}","dataSourceValues": {"bblogsrc": "_sourceCategory = ${var.bitbucket_sc}" }}'
    EOT
  }
}

# Install Opsgenie
resource "null_resource" "install_Opsgenie_app" {
  count      = "${var.install_opsgenie}" == "app" || "${var.install_opsgenie}" == "all" ? 1 : 0
  depends_on = [sumologic_http_source.opsgenie]
  triggers = {
        version = var.opsgenie_version
  }

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/05bf2074-0487-486f-8359-3d878fbc1c49/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Opsgenie", "description": "The Opsgenie App provides at-a-glance views and detailed analytics for alerts on your DevOps environment.", "destinationFolderId": "${data.external.folder_data_json.result.id}","dataSourceValues": {"opsgenieLogSrc": "_sourceCategory = ${var.opsgenie_sc}" }}'
    EOT
  }
}

# Install Pagerduty App
resource "null_resource" "install_pagerduty_app" {
  count      = "${var.install_pagerduty}" == "app" || "${var.install_pagerduty}" == "all" ? 1 : 0
  depends_on = [sumologic_http_source.pagerduty]
  triggers = {
        version = var.pagerduty_version
  }

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/589857e0-e4c1-4165-8212-f656899a3b95/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Pagerduty V2", "description": "The Sumo Logic App for PagerDuty V2 collects incident messages from your PagerDuty account via a webhook, and displays that incident data in pre-configured Dashboards, so you can monitor and analyze the activity of your PagerDuty account and Services.", "destinationFolderId": "${data.external.folder_data_json.result.id}","dataSourceValues": {"logsrcpd": "_sourceCategory = ${var.pagerduty_sc}"}}'
    EOT
  }
}

# Install Github App
resource "null_resource" "install_github_app" {
  count      = "${var.install_github}" == "app" || "${var.install_github}" == "all" ? 1 : 0
  depends_on = [sumologic_http_source.github]
  triggers = {
        version = var.github_version
  }

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/86289912-b909-426e-8154-bda55b9ee902/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Github", "description": "The Sumo Logic App for GitHub connects to your GitHub repository at the Organization or Repository level, and ingests GitHub events via a webhook.", "destinationFolderId": "${data.external.folder_data_json.result.id}","dataSourceValues": {"paramId123": "_sourceCategory = ${var.github_sc}"}}'
    EOT
  }
}

# Install CircleCI App
resource "null_resource" "install_circleci_app" {
  count = "${var.install_circleci}" == "app" || "${var.install_circleci}" == "all" ? 1 : 0
  depends_on = [sumologic_http_source.circleci]
  triggers = {
        version = var.circleci_version
  }
  
  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/f58985bd-40a8-4f87-aeeb-5a6a6ab4f703/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "CircleCI", "description": "The CircleCI app for Sumo Logic provides advanced views to track the performance and health of your continuous integration and deployment pipelines.", "destinationFolderId": "${data.external.folder_data_json.result.id}","dataSourceValues": {"logsrc": "_sourceCategory = ${var.circleci_app_sc}"}}'
    EOT
  }
}


# Install Gitlab App
resource "null_resource" "install_gitlab_app" {
  count      = "${var.install_gitlab}" == "app" || "${var.install_gitlab}" == "all" ? 1 : 0
  depends_on = [sumologic_http_source.gitlab]
  triggers = {
        version = var.gitlab_version
  }

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/fd3446f3-2662-4124-bfc0-4b36f0b625d3/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Gitlab", "description": "Gitlab is an open source automation server for automating tasks related to building, testing, and delivering software.", "destinationFolderId": "${data.external.folder_data_json.result.id}","dataSourceValues": {"logsrc": "_sourceCategory = ${var.gitlab_sc}"}}'
    EOT
  }
}

# Install Jenkins App
resource "null_resource" "install_jenkins_app" {
  count      = "${var.install_jenkins}" == "app" || "${var.install_jenkins}" == "all" ? 1 : 0
  depends_on = [sumologic_http_source.jenkins]
  triggers = {
        version = var.jenkins_version
  }

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/050ad791-f6e6-45e1-bae3-be4818c240dc/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Jenkins", "description": "Jenkins is an open source automation server for automating tasks related to building, testing, and delivering software.", "destinationFolderId": "${data.external.folder_data_json.result.id}","dataSourceValues": {"jenkinslogsrc": "_sourceCategory = ${var.jenkins_sc}"}}'
    EOT
  }
}

# Install SDO App
resource "null_resource" "install_sdo_app" {
  count = "${var.install_sdo}" == "app" ? 1 : 0
  triggers = {
        version = var.sdo_version
  }

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/cdf6245b-3c27-4de8-89bf-216e41d18c28/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Software Development Optimization", "description": "The Sumo Logic Software Development Optimization Solution helps you increase release velocity, improve reliability, and comprehensively monitor your software development pipelines.", "destinationFolderId": "${data.external.folder_data_json.result.id}"}'
    EOT
  }
}

# Create/Delete Field required by BitBucket App in Sumo Logic by calling REST API
provider "restapi" {
  alias = "sumo"
  uri   = var.sumo_api_endpoint
  # debug                = true
  write_returns_object = true
  username             = var.sumo_access_id
  password             = var.sumo_access_key
  headers              = { Content-Type = "application/json" }
}

# Create/Delete Field required by BitBucket App in Sumo Logic by calling REST API
resource "restapi_object" "bitbucket_field" {
  provider     = restapi.sumo
  count        = "${var.install_bitbucket_cloud}" == "collection" || "${var.install_bitbucket_cloud}" == "all" ? 1 : 0
  path         = "/v1/fields"
  destroy_path = "/v1/fields/{id}"
  id_attribute = "fieldId"
  data         = <<JSON
  {
      "fieldName": "X-Event-Key"
  }
  JSON
}

# Create/Delete Field required by Github App in Sumo Logic by calling REST API
resource "restapi_object" "github_field" {
  provider     = restapi.sumo
  count        = "${var.install_github}" == "collection" || "${var.install_github}" == "all" ? 1 : 0
  path         = "/v1/fields"
  destroy_path = "/v1/fields/{id}"
  id_attribute = "fieldId"
  data         = <<JSON
  {
      "fieldName": "x-github-event"
  }
  JSON
}

# Create/Delete Field required by Gitlab App in Sumo Logic by calling REST API
resource "restapi_object" "gitlab_field" {
  provider     = restapi.sumo
  count        = "${var.install_gitlab}" == "collection" || "${var.install_gitlab}" == "all" ? 1 : 0
  path         = "/v1/fields"
  destroy_path = "/v1/fields/{id}"
  id_attribute = "fieldId"
  data         = <<JSON
  {
      "fieldName": "x-gitlab-event"
  }
  JSON
}