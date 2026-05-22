variable "sumologic_environment" {
  type        = string
  description = "Enter au, ca, ch, de, eu, esc, fed, jp, kr, us1 or us2. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"

  validation {
    condition = contains([
      "stag",
      "au",
      "ca",
      "ch",
      "de",
      "eu",
      "esc",
      "fed",
      "jp",
      "kr",
      "us1",
    "us2"], var.sumologic_environment)
    error_message = "The value must be one of stag, au, ca, ch, de, eu, esc, fed, jp, kr, us1 or us2."
  }
}

variable "sumologic_access_id" {
  type        = string
  description = "Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"

  validation {
    condition     = can(regex("\\w+", var.sumologic_access_id))
    error_message = "The SumoLogic access ID must contain valid characters."
  }
}

variable "sumologic_access_key" {
  type        = string
  description = "Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"
  sensitive   = true

  validation {
    condition     = can(regex("\\w+", var.sumologic_access_key))
    error_message = "The SumoLogic access key must contain valid characters."
  }
}

variable "sumologic_environment_base_url" {
  type        = string
  description = "Base URL for custom Sumo Logic environments (e.g., 'https://api.ch.sumologic.com/api/' for Switzerland). If provided, this takes precedence over the sumologic_environment parameter. Leave empty for standard deployments."
  default     = null

  validation {
    condition     = var.sumologic_environment_base_url == null || can(regex("^https://[a-zA-Z0-9.-]+\\.sumologic\\.(com|net)/api/?$", var.sumologic_environment_base_url))
    error_message = "The base URL must be null or a valid Sumo Logic API endpoint URL (e.g., 'https://api.ch.sumologic.com/api/')."
  }
}

variable "sumologic_organization_id" {
  type        = string
  description = <<EOT
            You can find your org on the Preferences page in the Sumo Logic UI. For more information, see the Preferences Page topic. Your org ID will be used to configure the IAM Role for Sumo Logic AWS Sources."
            For more details, visit https://help.sumologic.com/01Start-Here/05Customize-Your-Sumo-Logic-Experience/Preferences-Page
        EOT
  validation {
    condition     = can(regex("\\w+", var.sumologic_organization_id))
    error_message = "The organization ID must contain valid characters."
  }
}

variable "aws_account_alias" {
  type        = string
  description = <<EOT
            Provide the Name/Alias for the AWS environment from which you are collecting data. This name will appear in the Sumo Logic Explorer View, metrics, and logs.
            If you are going to deploy the solution in multiple AWS accounts then this value has to be overidden at main.tf file.
            Do not include special characters in the alias.
        EOT
  validation {
    condition     = can(regex("[a-z0-9]*", var.aws_account_alias))
    error_message = "Alias must only contain lowercase letters, number and length less than or equal to 30 characters."
  }
}

variable "aws_resource_tags" {
  description = "Map of tags to apply to all AWS resources provisioned through the AWS Observability Solution"
  type        = map(string)
  default     = {}
}