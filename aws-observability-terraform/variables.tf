variable "sumologic_environment" {
  type        = string
  description = "Enter au, ca, de, eu, jp, us2, in, fed or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"

  validation {
    condition = contains([
      "au",
      "ca",
      "de",
      "eu",
      "jp",
      "us1",
      "us2",
      "in",
    "fed"], var.sumologic_environment)
    error_message = "The value must be one of au, ca, de, eu, jp, us1, us2, in, or fed."
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
  sensitive = true

  validation {
    condition     = can(regex("\\w+", var.sumologic_access_key))
    error_message = "The SumoLogic access key must contain valid characters."
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

variable "sumologic_folder_installation_location" {
  type        = string
  description = "Indicates where to install the app folder. Enter \"Personal Folder\" for installing in \"Personal\" folder and \"Admin Recommended Folder\" for installing in \"Admin Recommended\" folder."
  validation {
    condition = contains([
      "Personal Folder",
      "Admin Recommended Folder"], var.sumologic_folder_installation_location)
    error_message = "The value must be one of \"Personal Folder\" or \"Admin Recommended Folder\"."
  }
  default     = "Personal Folder"

}

variable "sumologic_folder_share_with_org" {
  type        = bool
  description = "Indicates if AWS Observability folder should be shared (view access) with entire organization. true to enable; false to disable."
  default     = true

}