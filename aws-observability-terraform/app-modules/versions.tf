terraform {
  required_version = ">= 0.13.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 2.1"
    }
    sumologic = {
      version = ">= 2.31.3, < 4.0.0"
      source  = "SumoLogic/sumologic"
    }
  }
}