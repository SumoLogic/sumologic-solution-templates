terraform {
  required_version = ">= 1.5.7"

  required_providers {

    sumologic = {
      version = ">= 3.1.5"
      source  = "SumoLogic/sumologic"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.13.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.44.0"
    }

  }
}
