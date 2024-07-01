terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 2.1"
    }
    sumologic = {
      version = ">= 2.31.0, < 3.0.0"
      source  = "SumoLogic/sumologic"
    }
  }
}
