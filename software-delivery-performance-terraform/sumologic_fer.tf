resource "sumologic_field_extraction_rule" "github_pr_fer" {
      name = "Github Pull Request"
      scope = "${var.github_sc} ${var.github_pull_request_fer_scope}"
      parse_expression = var.github_pull_request_fer_parse
      enabled = true
}

resource "sumologic_field_extraction_rule" "jenkins_build_fer" {
      name = "Jenkins Build"
      scope = "${var.jenkins_sc} ${var.jenkins_build_fer_scope}"
      parse_expression = var.jenkins_build_fer_parse
      enabled = true
}

resource "sumologic_field_extraction_rule" "jenkins_deploy_fer" {
      name = "Jenkins Deploy"
      scope = "${var.jenkins_sc} ${var.jenkins_deploy_fer_scope}"
      parse_expression = var.jenkins_deploy_fer_parse
      enabled = true
}

resource "sumologic_field_extraction_rule" "opsgenie_alerts_fer" {
      name = "Opsgenie Alerts"
      scope = "${var.opsgenie_sc} ${var.opsgenie_alerts_fer_scope}"
      parse_expression = var.opsgenie_alerts_fer_parse
      enabled = true
}

resource "sumologic_field_extraction_rule" "bitbucket_pr_fer" {
      name = "Bitbucket Pull Request"
      scope = "${var.bitbucket_sc} ${var.bitbucket_pull_request_fer_scope}"
      parse_expression = var.bitbucket_pull_request_fer_parse
      enabled = true
}

resource "sumologic_field_extraction_rule" "bitbucket_build_fer" {
      name = "Bitbucket Build"
      scope = "${var.bitbucket_sc} ${var.bitbucket_build_fer_scope}"
      parse_expression = var.bitbucket_build_fer_parse
      enabled = true
}

resource "sumologic_field_extraction_rule" "bitbucket_deploy_fer" {
      name = "Bitbucket Deploy"
      scope = "${var.bitbucket_sc} ${var.bitbucket_deploy_fer_scope}"
      parse_expression = var.bitbucket_deploy_fer_parse
      enabled = true
}

resource "sumologic_field_extraction_rule" "jira_issues_fer" {
      name = "Jira Issues"
      scope = "${var.jira_cloud_sc} ${var.jira_issues_fer_scope}"
      parse_expression = var.jira_issues_fer_parse
      enabled = true
}

resource "sumologic_field_extraction_rule" "pagerduty_alerts_fer" {
      name = "Pagerduty Alerts"
      scope = "${var.pagerduty_sc} ${var.pagerduty_alerts_fer_scope}"
      parse_expression = var.pagerduty_alerts_fer_parse
      enabled = true
}