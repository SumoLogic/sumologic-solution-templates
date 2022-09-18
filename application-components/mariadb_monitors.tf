resource "sumologic_monitor_folder" "mariadb_monitor_folder" {
  depends_on = [sumologic_field.db_cluster,sumologic_field.db_system, sumologic_field.db_cluster_address,sumologic_field.db_cluster_port]
  count      = contains(local.database_engines_values, "mariadb") ? 1 : 0
  name = var.mariadb_monitor_folder
  description = "Folder for MariaDB Monitors"
  parent_id = sumologic_monitor_folder.root_monitor_folder.id
}

module "MariaDB-NoindexusedintheSQLstatements" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mariadb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MariaDB - No index used in the SQL statements"
  monitor_description         = "This alert fires when there are 5 or more statements not using an index in the SQL query within a 5 minute time interval."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mariadb_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.mariadb_data_source} db_system=mariadb metric=mysql_perf_schema_events_statements_no_index_used_total db_cluster=* server=* schema=* | sum by db_cluster, host, server, schema"
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 5,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 5,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
module "MariaDB-Largenumberofslowqueries" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mariadb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MariaDB - Large number of slow queries"
  monitor_description         = "This alert fires when there are 5 or more slow queries within a 5 minute time interval."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mariadb_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.mariadb_data_source} db_system=mariadb metric=mysql_slow_queries db_cluster=* server=* | sum by db_cluster, host, server"
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 5,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 5,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
module "MariaDB-Followerreplicationlagdetected" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mariadb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MariaDB - Follower replication lag detected"
  monitor_description         = "This alert fires when we detect that the average replication lag within a 5 minute time interval is greater than or equal to 900 seconds ."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mariadb_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.mariadb_data_source} db_system=mariadb metric=mysql_slave_Seconds_Behind_Master db_cluster=* server=* host=* | avg by db_cluster, server, host"
    B = "${var.mariadb_data_source} db_system=mariadb metric=mysql_slave_SQL_delay db_cluster=* server=* host=*  | avg by db_cluster, server, host"
    C = "(#A - #B) along db_cluster, server, host"
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 900,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 900,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
module "MariaDB-Largenumberofstatementerrors" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mariadb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MariaDB - Large number of statement errors"
  monitor_description         = "This alert fires when there are 5 or more statement errors within a 5 minute time interval."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mariadb_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.mariadb_data_source} db_system=mariadb metric=mysql_perf_schema_events_statements_errors_total db_cluster=* server=* schema=* | sum by db_cluster, host, server, schema"
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 5,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 5,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
module "MariaDB-Largenumberofstatementwarnings" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mariadb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MariaDB - Large number of statement warnings"
  monitor_description         = "This alert fires when we detect that there are 20 or more statement warnings within a 5 minute time interval."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mariadb_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.mariadb_data_source} db_system=mariadb metric=mysql_perf_schema_events_statements_warnings_total db_cluster=* server=* schema=* | sum by db_cluster, host, server, schema"
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 20,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 20,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
module "MariaDB-Instancedown" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mariadb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MariaDB - Instance down"
  monitor_description         = "This alert fires when we detect that a MariaDB instance is down"
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.mariadb_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.mariadb_data_source} db_system=mariadb db_cluster=*  (\"Shutdown complete\" or \"Terminated.\") | json \"log\" nodrop | if (_raw matches \"{*\", log, _raw) as mesg | parse regex field=mesg \"\\[(?<ErrorLogtype>[^\\]]*)][\\:]*\\s(?<ErrorMsg>.*)\" nodrop | \"Unknown\" as server_status | if (ErrorMsg matches \"*Terminated.*\", \"Down\", server_status) as server_status | if (ErrorMsg matches \"*Shutdown complete*\", \"Down\", server_status) as server_status | where server_status = \"Down\" | if (isEmpty(pod),_sourceHost,pod) as host | timeslice 1s | count by _timeslice, db_cluster,host,server_status,ErrorMsg"
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
module "MariaDB-Largenumberofabortedconnections" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mariadb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MariaDB - Large number of aborted connections"
  monitor_description         = "This alert fires when there are 5 or more aborted connections detected within a 5 minute time interval."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mariadb_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.mariadb_data_source} db_system=mariadb metric=mysql_aborted_connects db_cluster=* server=* | sum by db_cluster,host, server"
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 5,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 5,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
module "MariaDB-Connectionrefused" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mariadb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MariaDB - Connection refused"
  monitor_description         = "This alert fires when connections are refused when the limit of maximum connections is reached."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mariadb_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.mariadb_data_source} db_system=mariadb metric=mysql_connection_errors_max_connections db_cluster=* host=* server=* | sum by db_cluster, host, server"
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 1,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 1,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
module "MariaDB-SlaveServerError" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mariadb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MariaDB - Slave Server Error"
  monitor_description         = "This alert fires when slave server error within 5 minute time interval."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mariadb_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    C = "${var.mariadb_data_source} db_system=mariadb (metric=mysql_slave_last_io_errno or metric=mysql_slave_last_sql_errno) db_cluster=* | filter latest > 0 | sum by db_cluster,host,server"
  }
  triggers = [
			  {
				threshold_type = "GreaterThan",
				threshold = 0,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThanOrEqual",
				threshold = 0,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
module "MariaDB-HighInnodbbufferpoolutilization" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mariadb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MariaDB - High Innodb buffer pool utilization"
  monitor_description         = "This alert fires when the InnoDB buffer pool utilization is high (>=90%) within a 5 minute time interval."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mariadb_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.mariadb_data_source} db_system=mariadb metric=mysql_Innodb_buffer_pool_pages_total db_cluster=* server=* | sum by db_cluster, host, server"
    B = "${var.mariadb_data_source} db_system=mariadb metric=mysql_Innodb_buffer_pool_pages_free db_cluster=* server=* | sum by db_cluster, host, server"
    C = "((#A - #B) / #A) * 100 along db_cluster, host, server"
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 90,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 90,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
module "MariaDB-ExcessiveSlowQueryDetected" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mariadb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MariaDB - Excessive Slow Query Detected"
  monitor_description         = "This alert fires when the average time to execute a query is more than 15 seconds for a 5 minute time interval."
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.mariadb_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "db_system=mariadb db_cluster=* \"User@Host\" \"Query_time\" | json auto maxdepth 1 nodrop | if (isEmpty(log), _raw, log) as mariadb_log_message | parse regex field=mariadb_log_message \"(?<query_block># User@Host:[\\S\\s]+?SET timestamp=\\d+;[\\S\\s]+?;)\" multi | parse regex field=query_block \"Schema: (?<schema>(?:\\S*|\\s)?)\\s*Last_errno[\\s\\S]+?Query_time:\\s+(?<query_time>[\\d.]*)\\s+Lock_time:\\s+(?<lock_time>[\\d.]*)\\s+Rows_sent:\\s+(?<rows_sent>[\\d.]*)\\s+Rows_examined:\\s+(?<rows_examined>[\\d.]*)\\s+Rows_affected:\\s+(?<rows_affected>[\\d.]*)\\s+Rows_read:\\s+(?<rows_read>[\\d.]*)\\n\" nodrop // Pttrn2-vrtn1 | parse regex field=query_block \"Schema: (?<schema>(?:\\S*|\\s)?)\\s*Last_errno[\\s\\S]+?\\s+Killed:\\s+\\d+\\n\" nodrop // Pttrn2-vrtn2 | parse regex field=query_block \"Query_time:\\s+(?<query_time>[\\d.]*)\\s+Lock_time:\\s+(?<lock_time>[\\d.]*)\\s+Rows_sent:\\s+(?<rows_sent>[\\d]*)\\s+Rows_examined:\\s+(?<rows_examined>[\\d]*)\\s+Rows_affected:\\s+(?<rows_affected>[\\d]*)\\s+\" nodrop // Pttrn2-vrtn3 | parse regex field=query_block \"Query_time:\\s+(?<query_time>[\\d.]*)\\s+Lock_time:\\s+(?<lock_time>[\\d.]*)\\s+Rows_sent:\\s+(?<rows_sent>[\\d]*)\\s+Rows_examined:\\s+(?<rows_examined>[\\d]*)\" // Pttrn2-vrtn4 | fields -query_block | num (query_time) | count as frequency, sum(query_time) as total_time, min(query_time) as min_time, max(query_time) as max_time, avg(query_time) as avg_time, avg(rows_examined) as avg_rows_examined, avg(rows_sent) as avg_rows_sent, avg(Lock_Time) as avg_lock_time group by sql_cmd, db_cluster, schema | 15 as threshold // customize if need different value. As an example, query taking more than 15 Seconds is considered as Excessive Slow. | where avg_time > threshold | sort by avg_time, frequency asc"
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
module "MariaDB-Largenumberofinternalconnectionerrors" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mariadb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MariaDB - Large number of internal connection errors"
  monitor_description         = "This alert fires when there are 5 or more internal connection errors within a 5 minute time interval."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mariadb_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.mariadb_data_source} db_system=mariadb metric=mysql_connection_errors_internal db_cluster=* server=* | sum by db_cluster, host, server"
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 5,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 5,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
module "MariaDB-Highaveragequeryruntime" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "mariadb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "MariaDB - High average query run time"
  monitor_description         = "This alert fires when the average run time of MariaDB queries within a 5 minute time interval for a given schema is greater than or equal to one second."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.mariadb_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.mariadb_data_source} db_system=mariadb metric=mysql_perf_schema_events_statements_seconds_total db_cluster=* server=* schema=* | avg by db_cluster, host, server, schema"
  }
  triggers = [
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 1,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThan",
				threshold = 1,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
