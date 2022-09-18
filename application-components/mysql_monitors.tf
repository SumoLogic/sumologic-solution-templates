resource "sumologic_monitor_folder" "mysql_monitor_folder" {
  depends_on = [sumologic_field.db_cluster,sumologic_field.db_system, sumologic_field.db_cluster_address,sumologic_field.db_cluster_port]
  count      = contains(local.database_engines_values, "mysql") ? 1 : 0
  name = var.mysql_monitor_folder
  description = "Folder for MySQL Monitors"
  parent_id = sumologic_monitor_folder.root_monitor_folder.id
}

# Sumo Logic MySQL Metric Monitors
module "MySQL-Connectionrefused" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mysql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MySQL - Connection refused"
  monitor_description         = "This alert fires when connections are refused when the limit of maximum connections is reached within 5 minute time interval."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mysql_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.mysql_data_source} metric=mysql_connection_errors_max_connections db_cluster=* server=* | sum by db_cluster, server"
  }

  # Triggers
  triggers = [
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "Critical",
                  threshold = 1,
                  threshold_type = "GreaterThanOrEqual",
                  occurrence_type = "Always", # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                },
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "ResolvedCritical",
                  threshold = 1,
                  threshold_type = "LessThan",
                  occurrence_type = "Always",
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

# Sumo Logic MySQL Log Monitors
module "MySQL-ExcessiveSlowQueryDetected" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mysql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MySQL - Excessive Slow Query Detected"
  monitor_description         = "This alert fires when we detect the average time to execute a query is more than 15 seconds over a 24 hour time-period"
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.mysql_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled

  # Queries - Only one query is allowed for Logs monitor
  queries = {
    A = "${var.mysql_data_source} db_system=mysql db_cluster=* \"User@Host\" \"Query_time\"\n| parse regex \"(?<query_block># User@Host:[\\S\\s]+?SET timestamp=\\d+;[\\S\\s]+?;)\" multi\n| parse regex field=query_block \"# User@Host: \\S+?\\[(?<user>\\S*?)\\] @ (?<host_name>\\S+)\\s\\[(?<ip_addr>\\S*?)\\]\" nodrop // Pttrn1-vrtn1\n| parse regex field=query_block \"# User@Host: \\S+?\\[(?<user>\\S*?)\\] @\\s+\\[(?<ip_addr>\\S*?)\\]\\s+Id:\\s+(?<Id>\\d{1,10})\" nodrop // Pttrn1-vrtn2\n| parse regex field=query_block \"# User@Host: \\S+?\\[(?<user>\\S*?)\\] @ (?<host_name>\\S+)\\s\\[(?<ip_addr>\\S*?)\\]\\s+Id:\\s+(?<Id>\\d{1,10})\" // Pttrn1-vrtn3\n| parse regex field=query_block \"Schema: (?<schema>(?:\\S*|\\s)?)\\s*Last_errno[\\s\\S]+?Query_time:\\s+(?<query_time>[\\d.]*)\\s+Lock_time:\\s+(?<lock_time>[\\d.]*)\\s+Rows_sent:\\s+(?<rows_sent>[\\d.]*)\\s+Rows_examined:\\s+(?<rows_examined>[\\d.]*)\\s+Rows_affected:\\s+(?<rows_affected>[\\d.]*)\\s+Rows_read:\\s+(?<rows_read>[\\d.]*)\\n\" nodrop // Pttrn2-vrtn1\n| parse regex field=query_block \"Schema: (?<schema>(?:\\S*|\\s)?)\\s*Last_errno[\\s\\S]+?\\s+Killed:\\s+\\d+\\n\" nodrop // Pttrn2-vrtn2\n| parse regex field=query_block \"Query_time:\\s+(?<query_time>[\\d.]*)\\s+Lock_time:\\s+(?<lock_time>[\\d.]*)\\s+Rows_sent:\\s+(?<rows_sent>[\\d]*)\\s+Rows_examined:\\s+(?<rows_examined>[\\d]*)\\s+Rows_affected:\\s+(?<rows_affected>[\\d]*)\\s+\" nodrop // Pttrn2-vrtn3\n| parse regex field=query_block \"Query_time:\\s+(?<query_time>[\\d.]*)\\s+Lock_time:\\s+(?<lock_time>[\\d.]*)\\s+Rows_sent:\\s+(?<rows_sent>[\\d]*)\\s+Rows_examined:\\s+(?<rows_examined>[\\d]*)\" // Pttrn2-vrtn4\n| parse regex field=query_block \"# Bytes_sent:\\s+(?<bytes_sent>\\d*)\\s+Tmp_tables:\\s+(?<tmp_tables>\\d*)\\s+Tmp_disk_tables:\\s+(?<temp_disk_tables>\\d*)\\s+Tmp_table_sizes:\\s+(?<tmp_table_sizes>\\d*)\\n\" nodrop // Pttrn3-vrtn1\n| parse regex field=query_block \"# Bytes_sent:\\s+(?<bytes_sent>\\d*)\\n\" nodrop // Pttrn3-vrtn2\n| parse regex field=query_block \"SET timestamp=(?<set_timestamp>\\d*);(?:\\\\n|\\n)(?<sql_cmd>[\\s\\S]*);\" nodrop\n| fields -query_block\n| num (query_time)\n| count as frequency, sum(query_time) as total_time, min(query_time) as min_time, max(query_time) as max_time, avg(query_time) as avg_time, avg(rows_examined) as avg_rows_examined, avg(rows_sent) as avg_rows_sent, avg(Lock_Time) as avg_lock_time group by sql_cmd, db_cluster, schema\n| 15 as threshold // customize if need different value. As an example, query taking more than 15 Seconds is considered as Excessive Slow.\n| where avg_time > threshold\n| sort by avg_time, frequency asc"
  }

  # Triggers
  triggers = [
                {
                  detection_method = "StaticCondition",
                  time_range = "1d",
                  trigger_type = "Critical",
                  threshold = 1,
                  threshold_type = "GreaterThanOrEqual",
                  occurrence_type = "ResultCount",
                  trigger_source = "AllResults"
                },
                {
                  detection_method = "StaticCondition",
                  time_range = "1d",
                  trigger_type = "ResolvedCritical",
                  threshold = 1,
                  threshold_type = "LessThan",
                  occurrence_type = "ResultCount",
                  trigger_source = "AllResults"
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

# Sumo Logic MySQL Metric Monitors
module "MySQL-Followerreplicationlagdetected" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mysql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MySQL - Follower replication lag detected"
  monitor_description         = "This alert fires when we detect that the average replication lag is greater than or equal to 900 seconds within a 5 minute time interval."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mysql_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.mysql_data_source} metric=mysql_slave_Seconds_Behind_Master db_cluster=* server=* host=* instance=* | avg by db_cluster, server, host, instance"
    B = "${var.mysql_data_source} metric=mysql_slave_SQL_delay db_cluster=* server=* host=* instance=* | avg by db_cluster, server, host, instance"
    C = "(#A - #B) along db_cluster, server, host, instance"
  }

  # Triggers
  triggers = [
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "Critical",
                  threshold = 900,
                  threshold_type = "GreaterThanOrEqual",
                  occurrence_type = "Always", # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                },
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "ResolvedCritical",
                  threshold = 900,
                  threshold_type = "LessThan",
                  occurrence_type = "Always",
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

# Sumo Logic MySQL Metric Monitors
module "MySQL-Highaveragequeryruntime" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mysql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MySQL - High average query run time"
  monitor_description         = "This alert fires when the average run time of SQL queries for a given schema is greater than or equal to one second within a time interval of 5 minutes."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mysql_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.mysql_data_source} metric=mysql_perf_schema_events_statements_seconds_total db_cluster=* server=* schema=* | avg by db_cluster, server, schema"
  }

  # Triggers
  triggers = [
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "Critical",
                  threshold = 1,
                  threshold_type = "GreaterThanOrEqual",
                  occurrence_type = "Always", # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                },
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "ResolvedCritical",
                  threshold = 1,
                  threshold_type = "LessThan",
                  occurrence_type = "Always",
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

# Sumo Logic MySQL Metric Monitors
module "MySQL-HighInnodbbufferpoolutilization" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mysql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MySQL - High Innodb buffer pool utilization"
  monitor_description         = "This alert fires when we detect that the InnoDB buffer pool utilization is high (>=90%) within a 5 minute time interval."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mysql_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.mysql_data_source} metric=mysql_Innodb_buffer_pool_pages_total db_cluster=* server=* | sum by db_cluster, server"
    B = "${var.mysql_data_source} metric=mysql_Innodb_buffer_pool_pages_free db_cluster=* server=* | sum by db_cluster, server"
    C = "((#A - #B) / #A) * 100 along db_cluster, server"
  }

  # Triggers
  triggers = [
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "Critical",
                  threshold = 90,
                  threshold_type = "GreaterThanOrEqual",
                  occurrence_type = "Always", # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                },
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "ResolvedCritical",
                  threshold = 90,
                  threshold_type = "LessThan",
                  occurrence_type = "Always",
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

# Sumo Logic MySQL Log Monitors
module "MySQL-Instancedown" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mysql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MySQL - Instance down"
  monitor_description         = "This alert fires when we detect that a MySQL instance is down within last 5 minutes interval"
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.mysql_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled

  # Queries - Only one query is allowed for Logs monitor
  queries = {
    A = "${var.mysql_data_source} db_system=mysql db_cluster=* mysqld (\"Shutdown complete\" or \"Terminated.\")\n| json \"log\" nodrop | if (_raw matches \"{*\", log, _raw) as mesg\n| parse regex field=mesg \"\\[(?<ErrorLogtype>[^\\]]*)][\\:]*\\s(?<ErrorMsg>.*)\" nodrop\n| \"Unknown\" as server_status\n| if (ErrorMsg matches \"*Terminated.*\", \"Down\", server_status) as server_status\n| if (ErrorMsg matches \"*Shutdown complete*\", \"Down\", server_status) as server_status\n| where server_status = \"Down\"\n| timeslice 1s\n| count by _timeslice, db_cluster, server_status, ErrorMsg"
  }

  # Triggers
  triggers = [
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "Critical",
                  threshold = 1,
                  threshold_type = "GreaterThanOrEqual",
                  occurrence_type = "ResultCount",
                  trigger_source = "AllResults"
                },
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "ResolvedCritical",
                  threshold = 1,
                  threshold_type = "LessThan",
                  occurrence_type = "ResultCount",
                  trigger_source = "AllResults"
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

# Sumo Logic MySQL Metric Monitors
module "MySQL-Largenumberofabortedconnections" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mysql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MySQL - Large number of aborted connections"
  monitor_description         = "This alert fires when we detect that there are 5 or more aborted connections identified within a time interval of 5 minutes."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mysql_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.mysql_data_source} metric=mysql_aborted_connects db_cluster=* server=* | sum by db_cluster, server"
  }

  # Triggers
  triggers = [
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "Critical",
                  threshold = 5,
                  threshold_type = "GreaterThanOrEqual",
                  occurrence_type = "Always", # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                },
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "ResolvedCritical",
                  threshold = 5,
                  threshold_type = "LessThan",
                  occurrence_type = "Always",
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

# Sumo Logic MySQL Metric Monitors
module "MySQL-Largenumberofinternalconnectionerrors" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mysql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MySQL - Large number of internal connection errors"
  monitor_description         = "This alert fires when we detect that there are 5 or more internal connection errors within a time interval of 5 minutes."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mysql_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.mysql_data_source} metric=mysql_connection_errors_internal db_cluster=* server=* | sum by db_cluster, server"
  }

  # Triggers
  triggers = [
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "Critical",
                  threshold = 5,
                  threshold_type = "GreaterThanOrEqual",
                  occurrence_type = "Always", # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                },
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "ResolvedCritical",
                  threshold = 5,
                  threshold_type = "LessThan",
                  occurrence_type = "Always",
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

# Sumo Logic MySQL Metric Monitors
module "MySQL-Largenumberofslowqueries" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mysql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MySQL - Large number of slow queries"
  monitor_description         = "This alert fires when we detect that there are 5 or more slow queries within a 5 minute time interval."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mysql_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.mysql_data_source} metric=mysql_slow_queries db_cluster=* server=* | sum by db_cluster, server"
  }

  # Triggers
  triggers = [
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "Critical",
                  threshold = 5,
                  threshold_type = "GreaterThanOrEqual",
                  occurrence_type = "Always", # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                },
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "ResolvedCritical",
                  threshold = 5,
                  threshold_type = "LessThan",
                  occurrence_type = "Always",
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

# Sumo Logic MySQL Metric Monitors
module "MySQL-Largenumberofstatementerrors" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mysql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MySQL - Large number of statement errors"
  monitor_description         = "This alert fires when we detect that there are 5 or more statement errors within a 5 minute time interval."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mysql_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.mysql_data_source} metric=mysql_perf_schema_events_statements_errors_total db_cluster=* server=* schema=* | sum by db_cluster, server, schema"
  }

  # Triggers
  triggers = [
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "Critical",
                  threshold = 5,
                  threshold_type = "GreaterThanOrEqual",
                  occurrence_type = "Always", # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                },
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "ResolvedCritical",
                  threshold = 5,
                  threshold_type = "LessThan",
                  occurrence_type = "Always",
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

# Sumo Logic MySQL Metric Monitors
module "MySQL-Largenumberofstatementwarnings" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mysql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MySQL - Large number of statement warnings"
  monitor_description         = "This alert fires when we detect that there are 20 or more statement warnings within a 5 minute time interval."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mysql_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.mysql_data_source} metric=mysql_perf_schema_events_statements_warnings_total db_cluster=* server=* schema=* | sum by db_cluster, server, schema"
  }

  # Triggers
  triggers = [
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "Critical",
                  threshold = 20,
                  threshold_type = "GreaterThanOrEqual",
                  occurrence_type = "Always", # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                },
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "ResolvedCritical",
                  threshold = 20,
                  threshold_type = "LessThan",
                  occurrence_type = "Always",
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

# Sumo Logic MySQL Metric Monitors
module "MySQL-NoindexusedintheSQLstatements" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mysql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MySQL - No index used in the SQL statements"
  monitor_description         = "This alert fires when we detect that there are 5 or more statements not using an index in the sql query within a 5 minute time interval."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mysql_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.mysql_data_source} metric=mysql_perf_schema_events_statements_no_index_used_total db_cluster=* server=* schema=* | sum by db_cluster, server, schema"
  }

  # Triggers
  triggers = [
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "Critical",
                  threshold = 5,
                  threshold_type = "GreaterThanOrEqual",
                  occurrence_type = "Always", # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                },
                {
                  detection_method = "StaticCondition",
                  time_range = "5m",
                  trigger_type = "ResolvedCritical",
                  threshold = 5,
                  threshold_type = "LessThan",
                  occurrence_type = "Always",
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}
