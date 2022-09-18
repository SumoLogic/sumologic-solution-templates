resource "sumologic_monitor_folder" "sqlserver_monitor_folder" {
  depends_on = [sumologic_field.db_cluster,sumologic_field.db_system, sumologic_field.db_cluster_address,sumologic_field.db_cluster_port]
  count      = contains(local.database_engines_values, "sqlserver") ? 1 : 0
  name = var.sqlserver_monitor_folder
  description = "Folder for SQL Server Monitors"
  parent_id = sumologic_monitor_folder.root_monitor_folder.id
}

module "SQLServer-DiskUsage" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "sqlserver") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "SQL Server - Disk Usage"
  monitor_description         = "This alert fires when the Disk usage within a 5 minute interval for an SQL Server  instance is high (70% - 80% for Warning and >=80% for Critical)."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.sqlserver_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.sqlserver_data_source} metric=sqlserver_volume_space_total_space_bytes db_cluster=* db_system=sqlserver  | sum by host, db_cluster"
    B = "${var.sqlserver_data_source} metric=sqlserver_volume_space_used_space_bytes db_cluster=* db_system=sqlserver  | sum by host, db_cluster"
    C = "#B*100/#A along host, db_cluster"
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 80,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 70,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Warning",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 80,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 70,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedWarning",
				detection_method = "StaticCondition"
			  }
			]
}
module "SQLServer-InsufficientSpace" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "sqlserver") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "SQL Server - Insufficient Space"
  monitor_description         = "This alert fires when SQL Server instance could not allocate a new page for database because of insufficient disk space in filegroup."
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.sqlserver_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.sqlserver_data_source} db_cluster=* db_system=sqlserver \"Could not allocate\" (space or page) |json \"log\" as _rawlog nodrop | if (isEmpty(_rawlog), _raw, _rawlog) as _raw | parse \"Could not allocate space for object '*' in database '*' because *. Create disk space by deleting unneeded files, dropping objects in the filegroup, adding additional files to the filegroup, or setting autogrowth on for existing files in the filegroup.\" as object, database, reason nodrop | parse \"Could not allocate a new * for database '*' because *. Create the necessary space by dropping objects in the filegroup, adding additional files to the filegroup, or setting autogrowth on for existing files in the filegroup.\" as object, database, reason | count"
  }
  triggers = [
			  {
				threshold_type = "GreaterThan",
				threshold = 0,
				time_range = "5m",
				occurrence_type = "ResultCount"
				trigger_source = "AllResults"
				trigger_type = "Warning",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThanOrEqual",
				threshold = 0,
				time_range = "5m",
				occurrence_type = "ResultCount"
				trigger_source = "AllResults"
				trigger_type = "ResolvedWarning",
				detection_method = "StaticCondition"
			  }
			]
}
module "SQLServer-CpuHighUsage" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "sqlserver") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "SQL Server - Cpu High Usage"
  monitor_description         = "This alert fires when the CPU usage within a 5 minute interval for an SQL Server  instance is high (70% - 80% for Warning and >=80% for Critical)."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.sqlserver_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.sqlserver_data_source} metric=sqlserver_cpu_sqlserver_process_cpu db_cluster=* db_system=sqlserver "
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 80,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 70,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Warning",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 80,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 70,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedWarning",
				detection_method = "StaticCondition"
			  }
			]
}
module "SQLServer-AppDomain" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "sqlserver") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "SQL Server - AppDomain"
  monitor_description         = "This alert fires when we detect AppDomain related issues in your SQL Server instance."
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.sqlserver_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.sqlserver_data_source} db_cluster=* db_system=sqlserver  (AppDomain or \"memory pressure\" or \"out of memory\") |json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw | parse \"AppDomain * (*) is marked for unload due to *.\" as AppDomainID, detail, reason nodrop | parse \"AppDomain * was unloaded by escalation policy to ensure the consistency of your application. * happened while accessing a critical resource\" as detail, reason nodrop | Parse \"Failed to initialize the Common Language Runtime * due to *.\" as detail, reason nodrop | parse \"Error: *, Severity: *, State: *. .NET Framework execution was aborted by escalation policy because of *.\" as error, severity, state, reason | count"
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 1,
				time_range = "5m",
				occurrence_type = "ResultCount"
				trigger_source = "AllResults"
				trigger_type = "Warning",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 1,
				time_range = "5m",
				occurrence_type = "ResultCount"
				trigger_source = "AllResults"
				trigger_type = "ResolvedWarning",
				detection_method = "StaticCondition"
			  }
			]
}
module "SQLServer-ProcessesBlocked" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "sqlserver") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "SQL Server - Processes Blocked"
  monitor_description         = "This alert fires when we detect that SQL Server has blocked processes."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.sqlserver_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.sqlserver_data_source} metric=sqlserver_performance_value counter=\"processes blocked\" db_system=sqlserver db_cluster=*"
  }
  triggers = [
			  {
				threshold_type = "GreaterThan",
				threshold = 0,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Warning",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThanOrEqual",
				threshold = 0,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedWarning",
				detection_method = "StaticCondition"
			  }
			]
}
module "SQLServer-LoginFail" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "sqlserver") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "SQL Server - Login Fail"
  monitor_description         = "This alert fires when we detect that the user cannot login to SQL Server."
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.sqlserver_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.sqlserver_data_source} db_cluster=* _sourceHost=* db_system=sqlserver Logon | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw  | parse \"Logon       Login * for user '*'. Reason: * '*'. [CLIENT: *]\" as logon_status, userName, reason, database, client_ip nodrop | parse \"Logon       Login * for user '*'. Reason: *. [CLIENT: *]\" as logon_status, userName, reason, client_ip nodrop | parse \"Logon       Login * for user '*' because *  [CLIENT: *]\" as logon_status, userName, reason, client_ip nodrop | parse \"Logon       SSPI handshake * with error code *, state * while establishing a connection with integrated security; the connection has been closed. Reason: *.  [CLIENT: *].\" as logon_status, error_code, state, reason, client_ip nodrop | parse \"Logon       * database '*' because *\" as logon_status, database, reason nodrop | parse \"Logon       The target database, '*', is participating in an availability group and is currently * for queries. *\" as database, logon_status, reason | parse field=reason \"* '*'\" as reason, database nodrop | count"
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 1,
				time_range = "5m",
				occurrence_type = "ResultCount"
				trigger_source = "AllResults"
				trigger_type = "Warning",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 1,
				time_range = "5m",
				occurrence_type = "ResultCount"
				trigger_source = "AllResults"
				trigger_type = "ResolvedWarning",
				detection_method = "StaticCondition"
			  }
			]
}
module "SQLServer-Deadlock" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "sqlserver") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "SQL Server - Deadlock"
  monitor_description         = "This alert fires when we detect deadlocks in a SQL Server instance."
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.sqlserver_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.sqlserver_data_source} db_cluster=* _sourceHost=* db_system=sqlserver deadlocked| count"
  }
  triggers = [
			  {
				threshold_type = "GreaterThan",
				threshold = 5,
				time_range = "5m",
				occurrence_type = "ResultCount"
				trigger_source = "AllResults"
				trigger_type = "Warning",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThanOrEqual",
				threshold = 5,
				time_range = "5m",
				occurrence_type = "ResultCount"
				trigger_source = "AllResults"
				trigger_type = "ResolvedWarning",
				detection_method = "StaticCondition"
			  }
			]
}
module "SQLServer-MirroringError" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "sqlserver") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "SQL Server - Mirroring Error"
  monitor_description         = "This alert fires when we detect that the SQL Server mirroring has error."
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.sqlserver_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.sqlserver_data_source} db_cluster=* db_system=sqlserver mirror* | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw  | parse \"A * has occurred while attempting to establish a connection to availability replica '*' with id [*].\" as reason, replica, replicaID nodrop | parse \"An error occurred in a Service Broker/Database Mirroring transport connection endpoint, Error: *, State: *. (Near endpoint role: *, far endpoint address: *)\" as error, state, near_endpoint, far_endpoint | count"
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 1,
				time_range = "5m",
				occurrence_type = "ResultCount"
				trigger_source = "AllResults"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 1,
				time_range = "5m",
				occurrence_type = "ResultCount"
				trigger_source = "AllResults"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
module "SQLServer-BackupFail" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "sqlserver") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "SQL Server - Backup Fail"
  monitor_description         = "This alert fires when we detect that the SQL Server backup failed."
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.sqlserver_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.sqlserver_data_source} db_cluster=* db_system=sqlserver backup !Restore !\"[180] Job\" | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw  | parse \"BackupDiskFile::*: Backup device '*' * to *. Operating system error *(*).\" as media, backup_path, backup_status, operation, error_code, reason nodrop | parse \"Backup      BackupIoRequest::ReportIoError: * * on backup device '*'. Operating system error *(*).\" as operation, backup_status, backup_path, error_code, reason nodrop | parse \"Extend Disk Backup:  * on backup device '*'. Operating system error *(*).\" as backup_status, backup_path, error_code, reason nodrop | parse \"BackupVirtualDeviceFile::RequestDurableMedia: * * on backup device '*'. Operating system error *(*).\" as operation, backup_status, backup_path, error_code, reason nodrop | parse \"Backup      BACKUP * to complete the command BACKUP DATABASE *. Check the backup application log for detailed messages.\" as backup_status, database | if (backup_status in (\"failed\", \"failure\"), \"Failure\", backup_status) as backup_status | timeslice 1d | count"
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 1,
				time_range = "5m",
				occurrence_type = "ResultCount"
				trigger_source = "AllResults"
				trigger_type = "Warning",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 1,
				time_range = "5m",
				occurrence_type = "ResultCount"
				trigger_source = "AllResults"
				trigger_type = "ResolvedWarning",
				detection_method = "StaticCondition"
			  }
			]
}
module "SQLServer-InstanceDown" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "sqlserver") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "SQL Server - Instance Down"
  monitor_description         = "This alert fires when we detect that the SQL Server instance is down for 5 minutes."
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.sqlserver_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.sqlserver_data_source} db_cluster=* db_system=sqlserver | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw | where _raw matches \"*SQL Server is now ready for client connections.*\" or  _raw matches \"*SQL Server is allowing new connections in response to 'continue' request from Service Control Manager.*\" or  _raw matches \"*SQL Server is not allowing new connections because the Service Control Manager requested a pause*\" or  _raw matches \"*SQL Trace was stopped due to server shutdown.*\" or \"*SQL Server terminating because of system shutdown.*\" | parse regex \"(?<time>\\d{4}-\\d{2}-\\d{2}\\s\\d{2}:\\d{2}:\\d{2}.\\d{2,3})\\s+\\S+\" | if (_raw matches \"*SQL Server is now ready for client connections.*\", \"Up\", if (_raw matches \"*SQL Server is allowing new connections in response to 'continue' request from Service Control Manager.*\", \"Up\",  if (_raw matches \"*SQL Server is not allowing new connections because the Service Control Manager requested a pause.*\", \"Down\", if (_raw matches \"*SQL Trace was stopped due to server shutdown.*\" or _raw matches \"*SQL Server terminating because of system shutdown.*\", \"Down\", \"Unkown\" )))) as server_status | where !(server_status=\"Up\") | timeslice 1s | count by _timeslice, db_cluster, server_status"
  }
  triggers = [
			  {
				threshold_type = "GreaterThan",
				threshold = 0,
				time_range = "5m",
				occurrence_type = "ResultCount"
				trigger_source = "AllResults"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThanOrEqual",
				threshold = 0,
				time_range = "5m",
				occurrence_type = "ResultCount"
				trigger_source = "AllResults"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
