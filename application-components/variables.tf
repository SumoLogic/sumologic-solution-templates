# sumologic organization variables

variable "sumologic_environment" {
  type        = string
  description = "Enter au, ca, de, eu, jp, us2, in, kr, fed or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"

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
      "kr",
    "fed"], var.sumologic_environment)
    error_message = "The value must be one of au, ca, de, eu, jp, us1, us2, in, kr or fed."
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

# Component variables
variable "components_on_kubernetes_deployment" {
  type        = string
  description = <<EOT
            Provide comma separated list of application components deployed on kubernetes environment for which sumologic resources needs to be created. Allowed values are "memcached,cassandra,elasticsearch,sqlserver,mongodb,mysql,postgresql,redis,mariadb,couchbase,oracle".
        EOT
  validation {
    condition     = anytrue([for engine in split(",", var.components_on_kubernetes_deployment) : contains(["", "memcached", "cassandra", "elasticsearch", "sqlserver", "mongodb", "mysql", "postgresql", "redis", "mariadb", "couchbase", "oracle"], engine)])
    error_message = "The value must be one of \"memcached,cassandra,elasticsearch,sqlserver,mongodb,mysql,postgresql,redis,mariadb,couchbase,oracle\"."
  }
  default = ""
}

variable "components_on_non_kubernetes_deployment" {
  type        = string
  description = <<EOT
            Provide comma separated list of application components deployed on non kubernetes environment for which sumologic resources needs to be created. Allowed values are "memcached,cassandra,elasticsearch,sqlserver,mongodb,mysql,postgresql,redis,mariadb,couchbase,oracle".
        EOT
  validation {
    condition     = anytrue([for engine in split(",", var.components_on_non_kubernetes_deployment) : contains(["", "memcached", "cassandra", "elasticsearch", "sqlserver", "mongodb", "mysql", "postgresql", "redis", "mariadb", "couchbase", "oracle"], engine)])
    error_message = "The value must be one of \"memcached,cassandra,elasticsearch,sqlserver,mongodb,mysql,postgresql,redis,mariadb,couchbase,oracle\"."
  }
  default = ""
}

# App variables

variable "apps_folder_installation_location" {
  type        = string
  description = "Indicates where to install the app folder. Enter \"Personal Folder\" for installing in \"Personal\" folder and \"Admin Recommended Folder\" for installing in \"Admin Recommended\" folder."
  validation {
    condition = contains([
      "Personal Folder",
    "Admin Recommended Folder"], var.apps_folder_installation_location)
    error_message = "The value must be one of \"Personal Folder\" or \"Admin Recommended Folder\"."
  }
  default = "Personal Folder"

}


variable "share_apps_folder_with_org" {
  type        = bool
  description = "Indicates if Apps folder should be shared (view access) with entire organization. true to enable; false to disable."
  default     = true

}

variable "apps_folder_name" {
  type        = string
  description = <<EOT
            Provide a folder name where all the apps will be installed under the Personal Or Admin Recommended folder of the user whose access keys you have entered.
            Default value will be: Applications Component Solution - Apps
        EOT
  default     = "Applications Component Solution - Apps"
}


# Common Monitor variables
variable "monitors_folder_name" {
  type        = string
  description = <<EOT
            Provide a folder name where all the apps will be installed under the Personal Or Admin Recommended folder of the user whose access keys you have entered.
            Default value will be: Applications Component Solution - Monitors
        EOT
  default     = "Applications Component Solution - Monitors"
}


variable "monitors_disabled" {
  type        = bool
  description = "Whether the monitors are enabled or not?"
  default     = true
}



variable "connection_notifications_critical" {
  type = list(object(
    {
      connection_type       = string,
      connection_id         = string,
      payload_override      = string,
      run_for_trigger_types = list(string)
    }
  ))
  description = "Connection Notifications to be sent by the critical monitor(alert)."
}

variable "connection_notifications_warning" {
  type = list(object(
    {
      connection_type       = string,
      connection_id         = string,
      payload_override      = string,
      run_for_trigger_types = list(string)
    }
  ))
  description = "Connection Notifications to be sent by the warning monitor(alert)."
}

variable "connection_notifications_missingdata" {
  type = list(object(
    {
      connection_type       = string,
      connection_id         = string,
      payload_override      = string,
      run_for_trigger_types = list(string)
    }
  ))
  description = "Connection Notifications to be sent by the missing data monitor(alert)."
}

variable "email_notifications_critical" {
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
  description = "Email Notifications to be sent by the critical monitor(alert)."
}

variable "email_notifications_warning" {
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
  description = "Email Notifications to be sent by the warning monitor(alert)."
}

variable "email_notifications_missingdata" {
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
  description = "Email Notifications to be sent by the missing data monitor(alert)."
}


variable "group_notifications" {
  type        = bool
  description = "Whether or not to group notifications for individual items that meet the trigger conditions in the monitor. Defaults to true."
  default     = true
}

# individual monitor variables

variable "memcached_monitor_folder" {
  type        = string
  description = "Folder where memcached monitors will be created."
  default     = "Memcached"
}

variable "memcached_data_source" {
  type        = string
  description = "Sumo Logic Memcached cluster filter for monitors. For eg: db_cluster=memcached.prod.01"
  default     = "db_system=memcached"
}

variable "redis_monitor_folder" {
  type        = string
  description = "Folder where redis monitors will be created."
  default     = "Redis"
}

variable "redis_data_source" {
  type        = string
  description = "Sumo Logic Redis cluster filter for monitors. For eg: db_cluster=redis.prod.01"
  default     = "db_system=redis"
}

variable "mongodb_monitor_folder" {
  type        = string
  description = "Folder where mongodb monitors will be created."
  default     = "MongoDB"
}

variable "mongodb_data_source" {
  type        = string
  description = "Sumo Logic MongoDB cluster filter for monitors. For eg: db_cluster=mongodb.prod.01"
  default     = "db_system=mongodb"
}

variable "sqlserver_data_source" {
  type        = string
  description = "Sumo Logic sqlserver cluster filter for monitors. For eg: db_cluster=sqlserver.prod.01"
  default     = "db_system=sqlserver"
}
variable "sqlserver_monitor_folder" {
  type        = string
  description = "Folder where sqlserver monitors will be created."
  default     = "SQL Server"
}

variable "cassandra_data_source" {
  type        = string
  description = "Sumo Logic cassandra cluster filter for monitors. For eg: db_cluster=cassandra.prod.01"
  default     = "db_system=cassandra"
}
variable "cassandra_monitor_folder" {
  type        = string
  description = "Folder where cassandra monitors will be created."
  default     = "Cassandra"
}

variable "mysql_data_source" {
  type        = string
  description = "Sumo Logic mysql cluster filter for monitors. For eg: db_cluster=mysql.prod.01"
  default     = "db_system=mysql"
}
variable "mysql_monitor_folder" {
  type        = string
  description = "Folder where mysql monitors will be created."
  default     = "MySQL"
}

variable "postgresql_data_source" {
  type        = string
  description = "Sumo Logic postgresql cluster filter for monitors. For eg: db_cluster=postgresql.prod.01"
  default     = "db_system=postgresql"
}
variable "postgresql_monitor_folder" {
  type        = string
  description = "Folder where postgresql monitors will be created."
  default     = "PostgreSQL"
}

variable "oracle_data_source" {
  type        = string
  description = "Sumo Logic oracle cluster filter for monitors. For eg: db_cluster=oracle.prod.01"
  default     = "db_system=oracle"
}
variable "oracle_monitor_folder" {
  type        = string
  description = "Folder where oracle monitors will be created."
  default     = "Oracle"
}

variable "elasticsearch_data_source" {
  type        = string
  description = "Sumo Logic elasticsearch cluster filter for monitors. For eg: db_cluster=elasticsearch.prod.01"
  default     = "db_system=elasticsearch"
}
variable "elasticsearch_monitor_folder" {
  type        = string
  description = "Folder where elasticsearch monitors will be created."
  default     = "Elasticsearch"
}

variable "couchbase_data_source" {
  type        = string
  description = "Sumo Logic couchbase cluster filter for monitors. For eg: db_cluster=couchbase.prod.01"
  default     = "db_system=couchbase"
}
variable "couchbase_monitor_folder" {
  type        = string
  description = "Folder where couchbase monitors will be created."
  default     = "Couchbase"
}

variable "mariadb_data_source" {
  type        = string
  description = "Sumo Logic mariadb cluster filter for monitors. For eg: db_cluster=mariadb.prod.01"
  default     = "db_system=mariadb"
}

variable "mariadb_monitor_folder" {
  type        = string
  description = "Folder where mariadb monitors will be created."
  default     = "MariaDB"
}

