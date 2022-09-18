resource "sumologic_monitor_folder" "memcached_monitor_folder" {
  depends_on = [sumologic_field.db_cluster,sumologic_field.db_system, sumologic_field.db_cluster_address,sumologic_field.db_cluster_port]
  count      = contains(local.database_engines_values, "memcached") ? 1 : 0
  name = var.memcached_monitor_folder
  description = "Folder for Memcached Monitors"
  parent_id = sumologic_monitor_folder.root_monitor_folder.id
}

module "Memcached-AuthenticationError" {
  count      = contains(local.database_engines_values, "memcached") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Memcached - Authentication Error"
  monitor_description         = "This alert fires when has connection failed authentications"
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.memcached_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.memcached_data_source} metric=memcached_auth_errors db_cluster=* host=*| sum by db_cluster,host | rate"
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
              },
              {
                threshold_type = "GreaterThanOrEqual",
                threshold = 0,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "Critical",
                detection_method = "StaticCondition"
              },
              {
                threshold_type = "LessThan",
                threshold = 0,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "ResolvedCritical",
                detection_method = "StaticCondition"
              }
            ]
}
module "Memcached-Uptime" {
  count      = contains(local.database_engines_values, "memcached") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Memcached - Uptime"
  monitor_description         = "This alert fires when uptime is < 180.  You can use this to detect respawns."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.memcached_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.memcached_data_source} metric=memcached_uptime db_cluster=* host=*  | avg by db_cluster, host"
  }
  triggers = [
              {
                threshold_type = "LessThanOrEqual",
                threshold = 180,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "Critical",
                detection_method = "StaticCondition"
              },
              {
                threshold_type = "GreaterThan",
                threshold = 180,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "ResolvedCritical",
                detection_method = "StaticCondition"
              }
            ]
}
module "Memcached-ConnectionYields" {
  count      = contains(local.database_engines_values, "memcached") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Memcached - Connection Yields"
  monitor_description         = "This alert fires when yielded connections per minute > 5"
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.memcached_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.memcached_data_source} metric=memcached_conn_yields db_cluster=* host=*| sum by db_cluster,host | rate"
  }
  triggers = [
              {
                threshold_type = "GreaterThan",
                threshold = 5,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "Warning",
                detection_method = "StaticCondition"
              },
              {
                threshold_type = "LessThanOrEqual",
                threshold = 5,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "ResolvedWarning",
                detection_method = "StaticCondition"
              },
              {
                threshold_type = "GreaterThanOrEqual",
                threshold = 0,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "Critical",
                detection_method = "StaticCondition"
              },
              {
                threshold_type = "LessThan",
                threshold = 0,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "ResolvedCritical",
                detection_method = "StaticCondition"
              }
            ]
}
module "Memcached-CacheHitRatio" {
  count      = contains(local.database_engines_values, "memcached") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Memcached - Cache Hit Ratio"
  monitor_description         = "The hit rate is one of the most important indicators of Memcached performance. A high hit rate means faster responses to your users. If the hit rate is falling, you need quick visibility into why. This alert gets fired low cache hit ratio is less than 50%"
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.memcached_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.memcached_data_source} metric=memcached_get_hits db_cluster=* host=* | avg by db_cluster, host  "
    B = "${var.memcached_data_source} metric=memcached_get_misses db_cluster=* host=* | avg by db_cluster, host  "
    C = "#A/(#B+#A) along  db_cluster, host "
  }
  triggers = [
              {
                threshold_type = "LessThanOrEqual",
                threshold = 0.5,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "Critical",
                detection_method = "StaticCondition"
              },
              {
                threshold_type = "GreaterThan",
                threshold = 0.5,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "ResolvedCritical",
                detection_method = "StaticCondition"
              }
            ]
}
module "Memcached-CommandsError" {
  count      = contains(local.database_engines_values, "memcached") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Memcached - Commands Error"
  monitor_description         = "This alert fires when has error commands"
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.memcached_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.memcached_data_source} db_cluster=* db_system=memcached memcached \">\" ERROR | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as memcached_log_message | parse regex field=memcached_log_message \">(?<pid>\\d+) (?<msg>\\w+)\" | fields pid, msg"
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
module "Memcached-CurrentConnections" {
  count      = contains(local.database_engines_values, "memcached") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Memcached - Current Connections"
  monitor_description         = "Number of connected clients. If current connections are none then something is wrong."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.memcached_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.memcached_data_source} metric=memcached_curr_connections db_cluster=* host=* | sum by db_cluster, host "
  }
  triggers = [
              {
                threshold_type = "LessThanOrEqual",
                threshold = 0,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "Critical",
                detection_method = "StaticCondition"
              },
              {
                threshold_type = "GreaterThan",
                threshold = 0,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "ResolvedCritical",
                detection_method = "StaticCondition"
              }
            ]
}
module "Memcached-ListenDisabled" {
  count      = contains(local.database_engines_values, "memcached") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Memcached - Listen Disabled"
  monitor_description         = "This alert fires when new queued connections per minute > 5"
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.memcached_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.memcached_data_source} metric=memcached_listen_disabled_num db_cluster=* host=*| sum by db_cluster,host | rate"
  }
  triggers = [
              {
                threshold_type = "GreaterThan",
                threshold = 5,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "Warning",
                detection_method = "StaticCondition"
              },
              {
                threshold_type = "LessThanOrEqual",
                threshold = 5,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "ResolvedWarning",
                detection_method = "StaticCondition"
              },
              {
                threshold_type = "GreaterThanOrEqual",
                threshold = 0,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "Critical",
                detection_method = "StaticCondition"
              },
              {
                threshold_type = "LessThan",
                threshold = 0,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "ResolvedCritical",
                detection_method = "StaticCondition"
              }
            ]
}
module "Memcached-HighMemoryUsage" {
  count      = contains(local.database_engines_values, "memcached") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Memcached - High Memory Usage"
  monitor_description         = "This alert fires when the memory usage is more than 80%."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.memcached_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.memcached_data_source} metric=memcached_bytes db_cluster=* host=* | sum by db_cluster, host"
    B = "${var.memcached_data_source} metric=memcached_limit_maxbytes db_cluster=* host=* | sum by db_cluster, host"
    C = "#A/(#A+#B) along db_cluster, host"
  }
  triggers = [
              {
                threshold_type = "GreaterThan",
                threshold = 80,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "Warning",
                detection_method = "StaticCondition"
              },
              {
                threshold_type = "LessThanOrEqual",
                threshold = 80,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "ResolvedWarning",
                detection_method = "StaticCondition"
              },
              {
                threshold_type = "GreaterThanOrEqual",
                threshold = 0,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "Critical",
                detection_method = "StaticCondition"
              },
              {
                threshold_type = "LessThan",
                threshold = 0,
                time_range = "5m",
                occurrence_type = "Always"
                trigger_source = "AnyTimeSeries"
                trigger_type = "ResolvedCritical",
                detection_method = "StaticCondition"
              }
            ]
}
