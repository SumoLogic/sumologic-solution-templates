#Sumo Logic SDO solution - This files has code to create FER's in Sumo Logic.

resource "sumologic_field_extraction_rule" "github_pr_fer" {
  count            = "${var.install_github}" == "fer" || "${var.install_github}" == "collection" || "${var.install_github}" == "all" ? 1 : 0
  depends_on       = [sumologic_http_source.github,restapi_object.github_field]
  name             = "Github Pull Request"
  scope            = "_sourceCategory=${var.github_sc} ${var.github_pull_request_fer_scope}"
  parse_expression = var.github_pull_request_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "jenkins_build_fer" {
  count            = "${var.install_jenkins}" == "fer" || "${var.install_jenkins}" == "collection" || "${var.install_jenkins}" == "all" ? 1 : 0
  depends_on       = [sumologic_http_source.jenkins]
  name             = "Jenkins Build"
  scope            = "_sourceCategory=${var.jenkins_sc} ${var.jenkins_build_fer_scope}"
  parse_expression = var.jenkins_build_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "jenkins_deploy_fer" {
  count            = "${var.install_jenkins}" == "fer" || "${var.install_jenkins}" == "collection" || "${var.install_jenkins}" == "all" ? 1 : 0
  depends_on       = [sumologic_http_source.jenkins]
  name             = "Jenkins Deploy"
  scope            = "_sourceCategory=${var.jenkins_sc} ${var.jenkins_deploy_fer_scope}"
  parse_expression = var.jenkins_deploy_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "jenkins_build_status_fer" {
  count            = "${var.install_jenkins}" == "fer" || "${var.install_jenkins}" == "collection" || "${var.install_jenkins}" == "all" ? 1 : 0
  name             = "Jenkins Build Status"
  scope            = "_sourceCategory=${var.jenkins_sc} ${var.jenkins_build_status_fer_scope}"
  parse_expression = var.jenkins_build_status_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "opsgenie_alerts_fer" {
  count            = "${var.install_opsgenie}" == "fer" || "${var.install_opsgenie}" == "collection" || "${var.install_opsgenie}" == "all" ? 1 : 0
  depends_on       = [sumologic_http_source.opsgenie]
  name             = "Opsgenie Alerts"
  scope            = "_sourceCategory=${var.opsgenie_sc} ${var.opsgenie_alerts_fer_scope}"
  parse_expression = var.opsgenie_alerts_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "bitbucket_pr_fer" {
  count            = "${var.install_bitbucket_cloud}" == "fer" || "${var.install_bitbucket_cloud}" == "collection" || "${var.install_bitbucket_cloud}" == "all" ? 1 : 0
  depends_on       = [sumologic_http_source.bitbucket_cloud,restapi_object.bitbucket_field]
  name             = "Bitbucket Pull Request"
  scope            = "_sourceCategory=${var.bitbucket_sc} ${var.bitbucket_pull_request_fer_scope}"
  parse_expression = var.bitbucket_pull_request_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "bitbucket_build_fer" {
  count            = "${var.install_bitbucket_cloud}" == "fer" || "${var.install_bitbucket_cloud}" == "collection" || "${var.install_bitbucket_cloud}" == "all" ? 1 : 0
  depends_on       = [sumologic_http_source.bitbucket_cloud,restapi_object.bitbucket_field]
  name             = "Bitbucket Build"
  scope            = "_sourceCategory=${var.bitbucket_sc} ${var.bitbucket_build_fer_scope}"
  parse_expression = var.bitbucket_build_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "bitbucket_deploy_fer" {
  count            = "${var.install_bitbucket_cloud}" == "fer" || "${var.install_bitbucket_cloud}" == "collection" || "${var.install_bitbucket_cloud}" == "all" ? 1 : 0
  depends_on       = [sumologic_http_source.bitbucket_cloud,restapi_object.bitbucket_field]
  name             = "Bitbucket Deploy"
  scope            = "_sourceCategory=${var.bitbucket_sc} ${var.bitbucket_deploy_fer_scope}"
  parse_expression = var.bitbucket_deploy_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "jira_issues_fer" {
  count            = "${var.install_jira_cloud}" == "fer" || "${var.install_jira_cloud}" == "collection" || "${var.install_jira_cloud}" == "all" || "${var.install_jira_server}" == "fer" || "${var.install_jira_server}" == "collection" || "${var.install_jira_server}" == "all" ? 1 : 0
  name             = "Jira Issues"
  scope            = "_sourceCategory=${var.jira_cloud_sc} or _sourceCategory=${var.jira_server_sc} ${var.jira_issues_fer_scope}"
  parse_expression = var.jira_issues_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "pagerduty_alerts_fer" {
  count            = "${var.install_pagerduty}" == "fer" || "${var.install_pagerduty}" == "collection" || "${var.install_pagerduty}" == "all" ? 1 : 0
  depends_on       = [sumologic_http_source.pagerduty]
  name             = "Pagerduty Alerts"
  scope            = "_sourceCategory=${var.pagerduty_sc} ${var.pagerduty_alerts_fer_scope}"
  parse_expression = var.pagerduty_alerts_fer_parse
  enabled          = true
}