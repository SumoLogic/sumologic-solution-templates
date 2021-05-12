variable "environment" {
  type        = string
  description = "Enter au, ca, de, eu, jp, us2, in, fed or us1. Visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"

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
  description = "Sumo Logic Access Key."

  validation {
    condition     = can(regex("\\w+", var.access_key))
    error_message = "The SumoLogic access key must contain valid characters."
  }
}

variable "apps_folder_name" {
  type        = string
  description = "Provide a folder name where all the apps will be installed. Default value will be \"AWS Observability Apps\"."
  default     = "AWS Observability Apps"
}

variable "parent_folder_id" {
  type        = string
  description = "Please provide a folder ID where you would like the apps to be installed. A folder with name provided in \"apps_folder_name\" will be created. If folder ID is empty, apps will be installed in Personal folder."
  default     = ""
}

variable "monitors_folder_name" {
  type        = string
  description = "Provide a folder name where all the monitors will be installed. Default value will be \"AWS Observability Monitors\"."
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

variable "rds_monitors_disabled" {
  type        = bool
  description = "Whether the RDS Apps monitors are enabled or not?"
  default     = true
}

