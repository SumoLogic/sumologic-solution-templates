terraform {
  required_version = ">= 1.2.5"

  required_providers {

    sumologic = {
      version = ">= 3.0.2"
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

    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 4.19.0"
    }

  }
}
