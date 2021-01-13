terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 2.1"
    }
    sumologic = {
      source  = "terraform-providers/sumologic"
      version = "~> 2.6.2"
    }
  }
  required_version = ">= 0.13"
}