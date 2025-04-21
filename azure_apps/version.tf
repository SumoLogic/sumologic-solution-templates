terraform {
  required_version = ">= 1.11.4"

  required_providers {
    sumologic = {
      version = ">= 3.0.0, < 4.0.0"
      source  = "SumoLogic/sumologic"
    }
  }
}