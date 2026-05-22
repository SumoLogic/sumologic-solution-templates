provider "sumologic" {
  access_id   = var.sumologic_access_id
  access_key  = var.sumologic_access_key
  base_url    = var.sumologic_environment_base_url
  environment = var.sumologic_environment_base_url == null ? var.sumologic_environment : null
}

provider "aws" {
  # Set the region via the AWS_DEFAULT_REGION environment variable, or configure it in your root module:
  region = "us-east-1"
  #
  # For multi-account / multi-region deployments, pass an aliased provider to the collection module:
  #   alias   = "production-us-east-1"
  #   profile = "<AWS CLI profile name>"
}

provider "lambda-invoke-extension" {
  region = "us-east-1"
}