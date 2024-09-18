terraform {
  required_providers {
    bitbucket = "~> 1.2"
    null      = "~> 2.1"
    #   restapi = "~> 1.12"
    template = "~> 2.1"
    #   jira = "~> 0.1.11"
    github    = "~> 2.8"
    pagerduty = {
      source  = "pagerduty/pagerduty"
      version = "2.2.1"
    }
    sumologic = ">= 2.31.3, < 3.0.0"
    gitlab    = "3.6.0"
  }
}
