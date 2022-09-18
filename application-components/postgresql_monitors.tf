resource "sumologic_monitor_folder" "postgresql_monitor_folder" {
  depends_on = [sumologic_field.db_cluster,sumologic_field.db_system, sumologic_field.db_cluster_address,sumologic_field.db_cluster_port]
  count      = contains(local.database_engines_values, "postgresql") ? 1 : 0
  name = var.postgresql_monitor_folder
  description = "Folder for PostgreSQL Monitors"
  parent_id = sumologic_monitor_folder.root_monitor_folder.id
}

# Sumo Logic PostgreSQL Metric Monitors
module "Postgresql-LowCommits" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "postgresql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "Postgresql- Commit Rate Low"
  monitor_description         = "This alert fires when we detect that Postgres seems to be processing very few transactions."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.postgresql_monitor_folder[count.index].id

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.postgresql_data_source} metric=postgresql_xact_commit db_system=postgresql db_cluster=* db=* host=* | quantize using sum | sum by db_cluster,db,host | rate"
  }

  # Triggers
  triggers = [
              {
                  threshold_type = "LessThan",
                  threshold = 10,
                  time_range = "5m",
                  occurrence_type = "Always" # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                  trigger_type = "Critical",
                  detection_method = "StaticCondition"
                },
                {
                  threshold_type = "GreaterThanOrEqual",
                  threshold = 10,
                  time_range = "5m",
                  occurrence_type = "Always" # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                  trigger_type = "ResolvedCritical",
                  detection_method = "StaticCondition"
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

module "Postgresql-SlowQueries" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "postgresql") ? 1 : 0
  # version                   = "{revision}"
  monitor_name                = "PostgreSQL - SlowQueries"
  monitor_description         = "This alert fires when we detect that the PostgreSQL instance is executing slow queries"
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.postgresql_monitor_folder[count.index].id

  # Queries - Only one query is allowed for Logs monitor
  queries = {
    A = "${var.postgresql_data_source} db_system=postgresql db_cluster=* duration | json \"log\" as _rawlog nodrop | if (isEmpty(_rawlog), _raw, _rawlog) as _raw | parse \"* * * [*] *@* *:  *\" as date,time,time_zone,thread_id,user,db,severity,msg | parse regex field=msg \"duration: (?<execution_time_ms>[\\S]+) ms  (?<query>.+)\"| count by db_cluster, db"
  }

  # Triggers
  triggers = [
              {
                  threshold_type        = "GreaterThanOrEqual",
                  threshold             = 1,
                  time_range            = "5m",
                  occurrence_type       = "ResultCount", # Options: ResultCount and MissingData for logs
                  trigger_source        = "AllResults", # Options: AllResults for logs.
                  trigger_type          = "Warning",
                  detection_method      = "StaticCondition"
                },
                {
                  threshold_type        = "LessThan",
                  threshold             = 1,
                  time_range            = "5m",
                  occurrence_type       = "MissingData", # Options: ResultCount and MissingData for logs
                  trigger_source        = "AllResults", # Options: AllResults for logs.
                  trigger_type          = "ResolvedWarning",
                  detection_method      = "StaticCondition"
                }
            ]


  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning

}

module "Postgresql-HighRateofStatementTimeout" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "postgresql") ? 1 : 0
  # version                   = "{revision}"
  monitor_name                = "PostgreSQL - High Rate of Statement Timeout"
  monitor_description         = "This alert fires when we detect Postgres transactions show a high rate of statement timeouts"
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.postgresql_monitor_folder[count.index].id

  # Queries - Only one query is allowed for Logs monitor
  queries = {
    A = "${var.postgresql_data_source} db_system=postgresql db_cluster=* \"statement timeout\" | json \"log\" as _rawlog nodrop | if (isEmpty(_rawlog), _raw, _rawlog) as _raw | parse \"* * * [*] *@* *:  *\" as date,time,time_zone,thread_id,user,db,severity,msg | count by  db_cluster, db | (queryEndTime() - queryStartTime())/1000 as duration_sec | _count/duration_sec as timeout_rate | where timeout_rate > 3 "
  }

  # Triggers
  triggers = [
              {
                  threshold_type        = "GreaterThanOrEqual",
                  threshold             = 1,
                  time_range            = "5m",
                  occurrence_type       = "ResultCount", # Options: ResultCount and MissingData for logs
                  trigger_source        = "AllResults", # Options: AllResults for logs.
                  trigger_type          = "Critical",
                  detection_method      = "StaticCondition"
                },
                {
                  threshold_type        = "LessThan",
                  threshold             = 1,
                  time_range            = "5m",
                  occurrence_type       = "MissingData", # Options: ResultCount and MissingData for logs
                  trigger_source        = "AllResults", # Options: AllResults for logs.
                  trigger_type          = "ResolvedCritical",
                  detection_method      = "StaticCondition"
                }
            ]


  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical

}

module "Postgresql-InstanceDown" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "postgresql") ? 1 : 0
  # version                   = "{revision}"
  monitor_name                = "PostgreSQL - Instance Down"
  monitor_description         = "This alert fires when the Postgres instance is down"
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.postgresql_monitor_folder[count.index].id

  # Queries - Only one query is allowed for Logs monitor
  queries = {
    A = "${var.postgresql_data_source} db_system=postgresql db_cluster=* host=* (\"database system\" AND \"shut down\") | json \"log\" as _rawlog nodrop | if (isEmpty(_rawlog), _raw, _rawlog) as _raw | parse \"* * * [*] *:  *\" as date,time,time_zone,thread_id,severity,msg | count by  db_cluster, host"
  }

  # Triggers
  triggers = [
              {
                  threshold_type        = "GreaterThanOrEqual",
                  threshold             = 1,
                  time_range            = "5m",
                  occurrence_type       = "ResultCount", # Options: ResultCount and MissingData for logs
                  trigger_source        = "AllResults", # Options: AllResults for logs.
                  trigger_type          = "Critical",
                  detection_method      = "StaticCondition"
                },
                {
                  threshold_type        = "LessThan",
                  threshold             = 1,
                  time_range            = "5m",
                  occurrence_type       = "MissingData", # Options: ResultCount and MissingData for logs
                  trigger_source        = "AllResults", # Options: AllResults for logs.
                  trigger_type          = "ResolvedCritical",
                  detection_method      = "StaticCondition"
                }
            ]


  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical

}

module "Postgresql-HighRateDeadlock" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "postgresql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "Postgresql- High Rate Deadlock"
  monitor_description         = "This alert fires when we detect deadlocks in a Postgres instance"
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.postgresql_monitor_folder[count.index].id

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.postgresql_data_source} metric=postgresql_deadlocks db_system=postgresql db_cluster=* db=* host=* | quantize using sum| sum by  db_cluster, host, db | rate | eval(_value*60)"
  }

  # Triggers
  triggers = [
              {
                  threshold_type = "GreaterThanOrEqual",
                  threshold = 1,
                  time_range = "5m",
                  occurrence_type = "Always" # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                  trigger_type = "Critical",
                  detection_method = "StaticCondition"
                },
                {
                  threshold_type = "LessThan",
                  threshold = 1,
                  time_range = "5m",
                  occurrence_type = "Always" # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                  trigger_type = "ResolvedCritical",
                  detection_method = "StaticCondition"
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

module "Postgresql-TooManyConnections" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "postgresql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "Postgresql- Too Many Connections"
  monitor_description         = "PostgreSQL instance has too many connections)"
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.postgresql_monitor_folder[count.index].id

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.postgresql_data_source} metric=postgresql_numbackends db_system=postgresql db_cluster=*  host=* "
  }

  # Triggers
  triggers = [
              {
                  threshold_type = "GreaterThanOrEqual",
                  threshold = 90,
                  time_range = "5m",
                  occurrence_type = "Always" # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                  trigger_type = "Critical",
                  detection_method = "StaticCondition"
                },
                {
                  threshold_type = "LessThan",
                  threshold = 90,
                  time_range = "5m",
                  occurrence_type = "Always" # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                  trigger_type = "ResolvedCritical",
                  detection_method = "StaticCondition"
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

module "Postgresql-TooManyLocksAcquired" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "postgresql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "Postgresql - Too Many Locks Acquired"
  monitor_description         = "This alert fires when we detect that there are too many locks acquired on the database. If this alert happens frequently, you may need to increase the postgres setting max_locks_per_transaction."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.postgresql_monitor_folder[count.index].id

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.postgresql_data_source} metric=postgresql_num_locks db_system=postgresql db_cluster=*  host=*  db=* mode=*| sum by  db_cluster, host, db | eval(_value / 100*64)"
  }

  # Triggers
  triggers = [
              {
                  threshold_type = "GreaterThanOrEqual",
                  threshold = 0.2,
                  time_range = "5m",
                  occurrence_type = "Always" # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                  trigger_type = "Critical",
                  detection_method = "StaticCondition"
                },
                {
                  threshold_type = "LessThan",
                  threshold = 0.2,
                  time_range = "5m",
                  occurrence_type = "Always" # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                  trigger_type = "ResolvedCritical",
                  detection_method = "StaticCondition"
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

module "Postgresql-AccessFromHighlyMaliciousSources" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "postgresql") ? 1 : 0
  # version                   = "{revision}"
  monitor_name                = "PostgreSQL - Access from Highly Malicious Sources"
  monitor_description         = "This alert will fire when a Postgres instance is accessed from known malicious IP addresses."
  monitor_monitor_type        = "Logs"
  monitor_parent_id           = sumologic_monitor_folder.postgresql_monitor_folder[count.index].id

  # Queries - Only one query is allowed for Logs monitor
  queries = {
    A = "${var.postgresql_data_source} db_system=postgresql db_cluster=* connection | json \"log\" as _rawlog nodrop | if (isEmpty(_rawlog), _raw, _rawlog) as _raw | parse \"connection received: host=* port=*\" as ip,port | count by ip,  db_cluster | lookup type, actor, raw, threatlevel as malicious_confidence from sumo://threat/cs on threat=ip | where type=\"ip_address\" | count by  db_cluster, ip, type, actor, malicious_confidence"
  }

  # Triggers
  triggers = [
              {
                  threshold_type        = "GreaterThanOrEqual",
                  threshold             = 1,
                  time_range            = "5m",
                  occurrence_type       = "ResultCount", # Options: ResultCount and MissingData for logs
                  trigger_source        = "AllResults", # Options: AllResults for logs.
                  trigger_type          = "Critical",
                  detection_method      = "StaticCondition"
                },
                {
                  threshold_type        = "LessThan",
                  threshold             = 1,
                  time_range            = "5m",
                  occurrence_type       = "MissingData", # Options: ResultCount and MissingData for logs
                  trigger_source        = "AllResults", # Options: AllResults for logs.
                  trigger_type          = "ResolvedCritical",
                  detection_method      = "StaticCondition"
                }
            ]


  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical

}

module "Postgresql-SSLCompressionActive" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "postgresql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "Postgresql - SSL Compression Active"
  monitor_description         = "This alert fires when we detect database connections with SSL compression are enabled. This may add significant jitter in replication delay. Replicas should turn off SSL compression via `sslcompression=0` in `recovery.conf`"
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.postgresql_monitor_folder[count.index].id

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.postgresql_data_source} db_system=postgresql db_cluster=*  host=* metric=postgresql_stat_ssl_compression_count"
  }

  # Triggers
  triggers = [
              {
                  threshold_type = "GreaterThan",
                  threshold = 0,
                  time_range = "5m",
                  occurrence_type = "Always" # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                  trigger_type = "Critical",
                  detection_method = "StaticCondition"
                },
                {
                  threshold_type = "LessThanOrEqual",
                  threshold = 0,
                  time_range = "5m",
                  occurrence_type = "Always" # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                  trigger_type = "ResolvedCritical",
                  detection_method = "StaticCondition"
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}

module "Postgresql-HighReplicationLag" {
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  count      = contains(local.database_engines_values, "postgresql") ? 1 : 0
  #version                  = "{revision}"
  monitor_name                = "PostgreSQL - High Replication Delay"
  monitor_description         = "This alert fires when we detect that the Postgres Replication Delay is high."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.postgresql_monitor_folder[count.index].id

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.postgresql_data_source} db_system=postgresql db_cluster=*  host=* metric=postgresql_replication_delay"
  }

  # Triggers
  triggers = [
              {
                  threshold_type = "GreaterThan",
                  threshold = 3600,
                  time_range = "5m",
                  occurrence_type = "Always" # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                  trigger_type = "Critical",
                  detection_method = "StaticCondition"
                },
                {
                  threshold_type = "LessThanOrEqual",
                  threshold = 3600,
                  time_range = "5m",
                  occurrence_type = "Always" # Options: Always, AtLeastOnce and MissingData for Metrics
                  trigger_source = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
                  trigger_type = "ResolvedCritical",
                  detection_method = "StaticCondition"
                }
            ]

  # Notifications
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
}
