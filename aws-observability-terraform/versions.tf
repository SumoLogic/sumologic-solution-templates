terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    null = {
      source = "hashicorp/null"
    }
    sumologic = {
      source = "terraform-providers/sumologic"
    }
  }
  required_version = ">= 0.13"
}
