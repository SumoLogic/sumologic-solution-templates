terraform {
  required_version = ">= 1.2.5"

  required_providers {

    sumologic = {
      version = ">= 2.19.0"
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
