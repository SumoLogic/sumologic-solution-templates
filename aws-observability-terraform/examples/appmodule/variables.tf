variable "sumologic_environment" {
  type        = string
  description = "Enter au, ca, de, eu, fed, in, jp, kr, us1 or us2. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"

  validation {
    condition = contains([
      "au",
      "ca",
      "de",
      "eu",
      "fed",
      "in",
      "jp",
      "kr",
      "us1",
      "us2"], var.sumologic_environment)
    error_message = "The value must be one of au, ca, de, eu, fed, in, jp, kr, us1 or us2."
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
  #sensitive = true

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

variable "sumo_api_endpoint" {
  type = string
  validation {
    condition = contains([
      "https://api.au.sumologic.com/api/",
    "https://api.ca.sumologic.com/api/", "https://api.de.sumologic.com/api/", "https://api.eu.sumologic.com/api/", "https://api.fed.sumologic.com/api/", "https://api.in.sumologic.com/api/", "https://api.jp.sumologic.com/api/", "https://api.sumologic.com/api/", "https://api.us2.sumologic.com/api/", "https://api.kr.sumologic.com/api/"], var.sumo_api_endpoint)
    error_message = "Argument \"sumo_api_endpoint\" must be one of the values specified at https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security."
  }
}

variable "apps_folder" {
  type        = string
  description = <<EOT
            Provide a folder name where all the apps will be installed under the Personal folder of the user whose access keys you have entered.
            Default value will be: AWS Observability Apps
        EOT
  default     = "AWS Observability Apps"
}

variable "monitors_folder" {
  type        = string
  description = <<EOT
            Provide a folder name where all the monitors will be installed under Monitor Folder.
            Default value will be: AWS Observability Monitors
        EOT
  default     = "AWS Observability Monitors"
}

variable "alb_monitors" {
  type        = bool
  description = "Indicates if the ALB Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "ec2metrics_monitors" {
  type        = bool
  description = "Indicates if EC2 Metrics Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "ecs_monitors" {
  type        = bool
  description = "Indicates if ECS Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "elasticache_monitors" {
  type        = bool
  description = "Indicates if Elasticache Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}