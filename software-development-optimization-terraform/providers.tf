terraform {
  required_providers {
    bitbucket = "~> 1.2"
    null      = "~> 2.1"
    #   restapi = "~> 1.12"
    template = "~> 2.1"
    #   jira = "~> 0.1.11"
    github    = "~> 2.8"
    pagerduty = {
      source  = "Pagerduty/pagerduty"
      version = "2.2.1"
    }
    sumologic = {
      version = ">= 2.31.3, < 3.0.0"
      source  = "SumoLogic/sumologic"
    }
    gitlab    = "3.6.0"
  }
}
