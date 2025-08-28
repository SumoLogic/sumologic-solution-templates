terraform {
  required_version = ">= 1.5.7"

  required_providers {
    sumologic = {
      version = ">= 2.31.3, < 3.0.0"
      source = "SumoLogic/sumologic"
    }
  }
}
