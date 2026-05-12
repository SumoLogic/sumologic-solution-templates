terraform {
  required_version = ">= 1.5.7"

  required_providers {
    sumologic = {
      version = ">= 3.1.5"
      source  = "SumoLogic/sumologic"
    }
  }
}
