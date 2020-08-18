#Sumo Logic SDO solution - This files has code to create FER's in Sumo Logic.

resource "sumologic_field_extraction_rule" "github_pr_fer" {
  count            = "${var.install_github}" ? 1 : 0
  depends_on       = [sumologic_http_source.github]
  name             = "Github Pull Request"
  scope            = "_sourceCategory=${var.github_sc} ${var.github_pull_request_fer_scope}"
  parse_expression = var.github_pull_request_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "jenkins_build_fer" {
  count            = "${var.install_jenkins}" ? 1 : 0
  depends_on       = [sumologic_http_source.jenkins]
  name             = "Jenkins Build"
  scope            = "_sourceCategory=${var.jenkins_sc} ${var.jenkins_build_fer_scope}"
  parse_expression = var.jenkins_build_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "jenkins_deploy_fer" {
  count            = "${var.install_jenkins}" ? 1 : 0
  depends_on       = [sumologic_http_source.jenkins]
  name             = "Jenkins Deploy"
  scope            = "_sourceCategory=${var.jenkins_sc} ${var.jenkins_deploy_fer_scope}"
  parse_expression = var.jenkins_deploy_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "opsgenie_alerts_fer" {
  count            = "${var.install_opsgenie}" ? 1 : 0
  depends_on       = [sumologic_http_source.opsgenie]
  name             = "Opsgenie Alerts"
  scope            = "_sourceCategory=${var.opsgenie_sc} ${var.opsgenie_alerts_fer_scope}"
  parse_expression = var.opsgenie_alerts_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "bitbucket_pr_fer" {
  count            = "${var.install_bitbucket_cloud}" ? 1 : 0
  depends_on       = [sumologic_http_source.bitbucket_cloud]
  name             = "Bitbucket Pull Request"
  scope            = "_sourceCategory=${var.bitbucket_sc} ${var.bitbucket_pull_request_fer_scope}"
  parse_expression = var.bitbucket_pull_request_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "bitbucket_build_fer" {
  count            = "${var.install_bitbucket_cloud}" ? 1 : 0
  depends_on       = [sumologic_http_source.bitbucket_cloud]
  name             = "Bitbucket Build"
  scope            = "_sourceCategory=${var.bitbucket_sc} ${var.bitbucket_build_fer_scope}"
  parse_expression = var.bitbucket_build_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "bitbucket_deploy_fer" {
  count            = "${var.install_bitbucket_cloud}" ? 1 : 0
  depends_on       = [sumologic_http_source.bitbucket_cloud]
  name             = "Bitbucket Deploy"
  scope            = "_sourceCategory=${var.bitbucket_sc} ${var.bitbucket_deploy_fer_scope}"
  parse_expression = var.bitbucket_deploy_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "jira_issues_fer" {
  count            = "${var.install_jira_cloud}" || "${var.install_jira_server}" ? 1 : 0
  name             = "Jira Issues"
  scope            = "_sourceCategory=${var.jira_cloud_sc} or _sourceCategory=${var.jira_server_sc} ${var.jira_issues_fer_scope}"
  parse_expression = var.jira_issues_fer_parse
  enabled          = true
}

resource "sumologic_field_extraction_rule" "pagerduty_alerts_fer" {
  count            = "${var.install_pagerduty}" ? 1 : 0
  depends_on       = [sumologic_http_source.pagerduty]
  name             = "Pagerduty Alerts"
  scope            = "_sourceCategory=${var.pagerduty_sc} ${var.pagerduty_alerts_fer_scope}"
  parse_expression = var.pagerduty_alerts_fer_parse
  enabled          = true
}