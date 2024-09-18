terraform {
  required_version = ">= 1.2.5"

  required_providers {

    sumologic = {
      version = ">= 2.31.3, < 3.0.0"
      source  = "SumoLogic/sumologic"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
}
