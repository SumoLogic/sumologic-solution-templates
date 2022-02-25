variable "environment" {
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
    "fed"], var.environment)
    error_message = "The value must be one of au, ca, de, eu, jp, us1, us2, in, or fed."
  }
}

variable "access_id" {
  type        = string
  description = "Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"

  validation {
    condition     = can(regex("\\w+", var.access_id))
    error_message = "The SumoLogic access ID must contain valid characters."
  }
}

variable "access_key" {
  type        = string
  description = "Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"
  sensitive = true

  validation {
    condition     = can(regex("\\w+", var.access_key))
    error_message = "The SumoLogic access key must contain valid characters."
  }
}

variable "json_file_directory_path" {
  type        = string
  description = "Directory path where all the JSONs are present."
}

variable "apps_folder_name" {
  type        = string
  description = <<EOT
            Provide a folder name where all the apps will be installed under the Personal folder of the user whose access keys you have entered.
            Default value will be: AWS Observability Apps
        EOT
  default     = "AWS Observability Apps"
}

variable "parent_folder_id" {
  type        = string
  description = "Please provide a folder ID where you would like the apps to be installed. A folder with name provided in \"apps_folder_name\" will be created. If folder ID is empty, apps will be installed in Personal folder."
  default     = ""
}

variable "monitors_folder_name" {
  type        = string
  description = <<EOT
            Provide a folder name where all the monitors will be installed under Monitor Folder.
            Default value will be: AWS Observability Monitors
        EOT
  default     = "AWS Observability Monitors"
}

variable "connection_notifications" {
  type = list(object(
    {
      connection_type       = string,
      connection_id         = string,
      payload_override      = string,
      run_for_trigger_types = list(string)
    }
  ))
  description = "Connection Notifications to be sent by the alert."
  default     = []
}

variable "email_notifications" {
  type = list(object(
    {
      connection_type       = string,
      recipients            = list(string),
      subject               = string,
      time_zone             = string,
      message_body          = string,
      run_for_trigger_types = list(string)
    }
  ))
  description = "Email Notifications to be sent by the alert."
  default     = []
}

variable "group_notifications" {
  type        = bool
  description = "Whether or not to group notifications for individual items that meet the trigger condition. Defaults to true."
  default     = true
}

variable "alb_monitors_disabled" {
  type        = bool
  description = "Indicates if the ALB Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "apigateway_monitors_disabled" {
  type        = bool
  description = "Indicates if the API Gateway Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "dynamodb_monitors_disabled" {
  type        = bool
  description = "Indicates if DynamoDB Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "ec2metrics_monitors_disabled" {
  type        = bool
  description = "Indicates if EC2 Metrics Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "ecs_monitors_disabled" {
  type        = bool
  description = "Indicates if ECS Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "elasticache_monitors_disabled" {
  type        = bool
  description = "Indicates if Elasticache Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "lambda_monitors_disabled" {
  type        = bool
  description = "Indicates if Lambda Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "nlb_monitors_disabled" {
  type        = bool
  description = "Indicates if NLB Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "rds_monitors_disabled" {
  type        = bool
  description = "Indicates if RDS Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "folder_installation_location" {
  type        = string
  description = "Indicates where to install the app folder. Enter \"Personal Folder\" for installing in \"Personal\" folder and \"Admin Recommended Folder\" for installing in \"Admin Recommended\" folder."
  validation {
    condition = contains([
      "Personal Folder",
      "Admin Recommended Folder"], var.folder_installation_location)
    error_message = "The value must be one of \"Personal Folder\" or \"Admin Recommended Folder\"."
  }
  default = "Personal Folder"
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

variable "folder_share_with_org" {
  type        = bool
  description = "Indicates if AWS Observability folder should be shared with entire organization. true to enable; false to disable."
  default     = true

}

