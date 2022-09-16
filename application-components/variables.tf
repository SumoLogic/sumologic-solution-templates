variable "sumologic_environment" {
  type        = string
  description = "Enter au, ca, de, eu, jp, us2, in, fed or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"

  validation {
    condition = contains([
      "stag",
      "long",
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

variable "database_deployment_type" {
  type        = string
  description = "Provide the deployment type where your databases are running.Allowed values are Kubernetes,Non-Kubernetes,Both. "
  validation {
    condition = contains([
      "Kubernetes",
      "Non-Kubernetes",
      "Both"], var.database_deployment_type)
    error_message = "The value must be one of \"Kubernetes\", \"Both\" or \"Non-Kubernetes\"."
  }
  default     = "Both"

}


variable "database_engines" {
  type= string
  description = <<EOT
            Provide comma separated list of database components for which sumologic resources needs to be created. Allowed values are "memcached,cassandra,elasticsearch,sqlserver,mongodb,mysql,postgresql,redis,mariadb,couchbase,oracle.
        EOT
  validation {
      condition = anytrue([for engine in split(",", var.database_engines): contains(["memcached","cassandra","elasticsearch","sqlserver","mongodb","mysql","postgresql","redis","mariadb","couchbase","oracle"], engine)])
    error_message = "The value must be one of memcached,cassandra,elasticsearch,sqlserver,mongodb,mysql,postgresql,redis,mariadb,couchbase,oracle"
  }
  default=""
}

# App related variables

variable "apps_folder_installation_location" {
  type        = string
  description = "Indicates where to install the app folder. Enter \"Personal Folder\" for installing in \"Personal\" folder and \"Admin Recommended Folder\" for installing in \"Admin Recommended\" folder."
  validation {
    condition = contains([
      "Personal Folder",
      "Admin Recommended Folder"], var.apps_folder_installation_location)
    error_message = "The value must be one of \"Personal Folder\" or \"Admin Recommended Folder\"."
  }
  default     = "Personal Folder"

}


variable "share_apps_folder_with_org" {
  type        = bool
  description = "Indicates if Apps folder should be shared (view access) with entire organization. true to enable; false to disable."
  default     = true

}

# Todo add suffix
variable "apps_folder_name" {
  type        = string
  description = <<EOT
            Provide a folder name where all the apps will be installed under the Personal folder of the user whose access keys you have entered.
            Default value will be: Applications Component Solutions
        EOT
  default     = "Applications Component Solution - Apps"
}


# Common Monitor related variables
variable "monitors_folder_name" {
  type        = string
  description = <<EOT
            Provide a folder name where all the apps will be installed under the Personal folder of the user whose access keys you have entered.
            Default value will be: Applications Component Solutions
        EOT
  default     = "Applications Component Solution - Monitors"
}


variable "monitors_disabled" {
  type        = bool
  description = "Whether the monitors are enabled or not?"
  default     = true
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
}

variable "group_notifications" {
  type        = bool
  description = "Whether or not to group notifications for individual items that meet the trigger condition. Defaults to true."
  default     = true
}

# individual monitors

variable "memcached_monitor_folder" {
  type = string
  description = "Folder where monitors will be created."
  default = "Memcached"
}

variable "memcached_data_source" {
  type = string
  description = "Sumo Logic Memcached cluster Filter. For eg: db_cluster=memcached.prod.01"
  default = "db_system=memcached"
}



