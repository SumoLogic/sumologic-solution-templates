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
      source  = "terraform-providers/sumologic"
      version = "~> 2.1.0"
    }
  }
}
