module "rds_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** Metric Rules ********************** #
  managed_metric_rules = {
    "ClusterMetricRule" = {
      metric_rule_name = "AwsObservabilityRDSClusterMetricsEntityRule"
      match_expression = "Namespace=AWS/RDS DBClusterIdentifier=*"
      sleep            = 0
      variables_to_extract = [
        {
          name        = "dbidentifier"
          tagSequence = "$DBClusterIdentifier._1"
        }
      ]
    },
    "InstanceMetricRule" = {
      metric_rule_name = "AwsObservabilityRDSInstanceMetricsEntityRule"
      match_expression = "Namespace=AWS/RDS DBInstanceIdentifier=*"
      # Issue with metric rules creation when created in parallel. To handle that sleep is added.
      sleep = 5
      variables_to_extract = [
        {
          name        = "dbidentifier"
          tagSequence = "$DBInstanceIdentifier._1"
        }
      ]
    }
  }

  # ********************** Required Fields and FERs are created at aws-observability-terraform/field.tf ********************** #

  # ********************** Apps ********************** #
  managed_apps = {
    "RdsApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/Rds-App.json"])
      folder_id    = var.app_folder_id
    }
  }

  # ********************** Monitors ********************** #
  managed_monitors = {
    "RdsBufferCacheHitRatio" = {
      monitor_name         = "Amazon RDS - Low Aurora Buffer Cache Hit Ratio"
      monitor_description  = "This alert fires when the average RDS Aurora buffer cache hit ratio within a 5 minute interval is low (<= 50%). This indicates that a lower percentage of requests were are served by the buffer cache, which could further indicate a degradation in application performance."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/rds metric=BufferCacheHitRatio statistic=Average account=* region=* dbidentifier=* | avg by dbidentifier, namespace, region, account"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 50,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 50,
          threshold_type   = "GreaterThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "RdsHighDiskQueueDepth" = {
      monitor_name         = "Amazon RDS - High Disk Queue Depth"
      monitor_description  = "This alert fires when the average disk queue depth for a database is high (>=5) for an interval of 5 minutes. Higher this value, higher will be the number of outstanding I/Os (read/write requests) waiting to access the disk, which will impact the performance of your application."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/rds metric=DiskQueueDepth statistic=Average account=* region=* dbidentifier=* | avg by dbidentifier, namespace, region, account"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 5,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 5,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "RdsHighWriteLatency" = {
      monitor_name         = "Amazon RDS - High Write Latency"
      monitor_description  = "This alert fires when the average write latency of a database within a 5 minute interval is high (>=5 seconds) . High write latencies will affect the performance of your application."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/rds metric=WriteLatency statistic=Average account=* region=* dbidentifier=* | avg by dbidentifier, namespace, region, account"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 5,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 5,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ],
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "RdsLowBurstBalance" = {
      monitor_name         = "Amazon RDS - Low Burst Balance"
      monitor_description  = "This alert fires when we observe a low burst balance (<= 50%) for a given database. A low burst balance indicates you won't be able to scale up as fast for burstable database workloads on gp2 volumes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/rds metric=BurstBalance statistic=Average account=* region=* dbidentifier=* | avg by dbidentifier, namespace, region, account"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 50,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 50,
          threshold_type   = "GreaterThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ],
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "RdsHighReadLatency" = {
      monitor_name         = "Amazon RDS - High Read Latency"
      monitor_description  = "This alert fires when the average read latency of a database within a 5 minutes time inerval is high (>=5 seconds). High read latency will affect the performance of your application."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/rds metric=ReadLatency statistic=Average account=* region=* dbidentifier=* | avg by dbidentifier, namespace, region, account"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 5,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 5,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ],
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "RdsHighCPUUtilization" = {
      monitor_name         = "Amazon RDS - High CPU Utilization"
      monitor_description  = "This alert fires when we detect that the average CPU utilization for a database is high (>=85%) for an interval of 5 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/rds metric=CPUUtilization statistic=Average account=* region=* dbidentifier=* | avg by dbidentifier, namespace, region, account"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 85,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 85,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ],
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "RdsMySQLSlowQuery" = {
      monitor_name         = "Amazon RDS MySQL - Excessive Slow Query Detected"
      monitor_description  = "This alert fires when we detect the average time to execute a query is more than 5 seconds over last 10 minutes."
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* namespace=aws/rds dbidentifier=* _sourceHost=/aws/rds/*SlowQuery \"User@Host\" \"Query_time\"\n| json \"message\" nodrop | if (_raw matches \"{*\", message, _raw) as message\n| parse regex field=message \"(?<query_block># User@Host:[\\S\\s]+?SET timestamp=\\d+;[\\S\\s]+?;)\" multi\n| parse regex field=query_block \"# User@Host:\\s*\\S+?\\[(?<user>\\S*?)\\]\\s*@\\s*\\[(?<ip_addr>\\S*?)\\]\\s*Id:\\s*(?<Id>\\d*)\" nodrop\n| parse regex field=query_block \"# User@Host:\\s*\\S+?\\[(?<user>\\S*?)\\]\\s*@\\s*(?<host_name>\\S+)\\s\\[(?<ip_addr>\\S*?)\\]\\s+Id:\\s*(?<Id>\\d+)\"\n| parse regex field=query_block \"# Query_time:\\s+(?<query_time>[\\d.]*)\\s+Lock_time:\\s+(?<lock_time>[\\d.]*)\\s+Rows_sent:\\s+(?<rows_sent>[\\d]*)\\s+Rows_examined:\\s+(?<rows_examined>[\\d]*)\" nodrop\n| parse regex field=query_block \"SET timestamp=(?<set_timestamp>\\d*);\\n(?<sql_cmd>[\\s\\S]*);\" nodrop\n| parse regex field=sql_cmd \"[^a-zA-Z]*(?<sql_cmd_type>[a-zA-Z]+)\\s*\"\n| fields -query_block\n| num (query_time)\n| count as frequency, sum(query_time) as total_time, min(query_time) as min_time, max(query_time) as max_time, avg(query_time) as avg_time, avg(rows_examined) as avg_rows_examined, avg(rows_sent) as avg_rows_sent, avg(Lock_Time) as avg_lock_time group by sql_cmd, dbidentifier\n| 5 as threshold // customize if need different value. As an example, query taking more than 5 Seconds is considered as Excessive Slow.\n| where avg_time > threshold\n| sort by avg_time, frequency asc"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-10m",
          trigger_type     = "Critical",
          threshold        = 1,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-10m",
          trigger_type     = "ResolvedCritical",
          threshold        = 1,
          threshold_type   = "LessThan",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "RdsMySQLHighAuthFailure" = {
      monitor_name         = "Amazon RDS MySQL - High Authentication Failure"
      monitor_description  = "This alert fires when we detect more then 10 authentication failure over a 5 minute time-period"
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* namespace=aws/rds dbidentifier=* _sourceHost=/aws/rds/*Error \"Access denied for user\"\n| json \"message\" nodrop | if (_raw matches \"{*\", message, _raw) as message\n| parse field=message \" [*] \" as LogLevel\n| parse field=message \" * [Note] Access denied for user '*'@'*' (using *: *)\" as requestid, user, host, authenticationType, flag nodrop\n| parse field=message \"[Warning] Access denied for user '*'@'*' (using *: *)\" as user, host, authenticationType, flag nodrop\n| count as event_count"
      }
      triggers = [
        {
          detection_method = "LogsStaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 10,
          threshold_type   = "GreaterThan",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        },
        {
          detection_method = "LogsStaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 10,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "RdsPostgreSQLSlowQuery" = {
      monitor_name         = "Amazon RDS PostgreSQL - Excessive Slow Query Detected"
      monitor_description  = "This alert fires when we detect the average time to execute a query is more than 5 seconds over a 10 minutes."
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* namespace=aws/rds dbidentifier=* _sourceHost=/aws/rds/*postgresql\n| json \"message\" nodrop \n| if (_raw matches \"{*\", message, _raw) as message\n| parse field=message \"* * *:*(*):*@*:[*]:*:*\" as date,time,time_zone,host,thread_id,user,database,processid,severity,msg \n| parse regex field=msg \"duration: (?<execution_time_ms>[\\S]+) ms (?<query>.+)\"\n| 5000 as threshold // customize if need different value. As an example, query taking more than 5 Seconds is considered as Excessive Slow.\n| where execution_time_ms > threshold  \n| count by dbidentifier, database"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 0,
          threshold_type   = "GreaterThan",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 0,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "RdsPostgreSQLHighAuthFailure" = {
      monitor_name         = "Amazon RDS PostgreSQL - High Authentication Failure"
      monitor_description  = "This alert fires when we detect Postgres logs show high rate of authentication failures"
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* namespace=aws/rds _sourceHost=/aws/rds/*postgresql dbidentifier=* \"authentication failed\"\n| json \"message\" nodrop | if (_raw matches \"{*\", message, _raw) as message\n| parse field=message \"* * *:*(*):*@*:[*]:*:*\" as date,time,time_zone,host,thread_id,user,database,processid,severity,msg \n| where msg matches \"*authentication failed*\""
      }
      triggers = [
        {
          detection_method = "LogsStaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 10,
          threshold_type   = "GreaterThan",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        },
        {
          detection_method = "LogsStaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 10,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "RdsPostgreSQLHighErrors" = {
      monitor_name         = "Amazon RDS PostgreSQL - High Errors"
      monitor_description  = "This alert fires when we detect Postgres logs show high rate of error/fatal logs"
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* namespace=aws/rds _sourceHost=/aws/rds/*postgresql dbidentifier=* (\"ERROR\" OR \"FATAL\")\n| json \"message\" nodrop | if (_raw matches \"{*\", message, _raw) as message\n| parse field=message \"* * *:*(*):*@*:[*]:*:*\" as date,time,time_zone,host,threadid,user,database,processid,severity,msg \n| where severity IN (\"ERROR\", \"FATAL\") "
      }
      triggers = [
        {
          detection_method = "LogsStaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 10,
          threshold_type   = "GreaterThan",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        },
        {
          detection_method = "LogsStaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 10,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "RdsPostgreSQLStatementTimeout" = {
      monitor_name         = "Amazon RDS PostgreSQL - Statement Timeouts"
      monitor_description  = "This alert fires when we detect Postgres logs show statement timeouts"
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* namespace=aws/rds dbidentifier=* _sourceHost=/aws/rds/*postgresql \"statement timeout\" | json \"message\" nodrop | if (_raw matches \"{*\", message, _raw) as message | parse field=message \"* * *:*(*):*@*:[*]:*:*\" as date,time,time_zone,host,thread_id,user,database,processid,severity,msg | count by  dbidentifier, database"
      }
      triggers = [
        {
          detection_method = "LogsStaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 0,
          threshold_type   = "GreaterThan",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        },
        {
          detection_method = "LogsStaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 0,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "RdsLowFreeStorage" = {
      monitor_name         = "Amazon RDS - Low Free Storage"
      monitor_description  = "This alert fires when the average free storage space of a RDS instance is low (< 512MB) for an interval of 15 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "account=* region=* namespace=aws/rds metric=FreeStorageSpace statistic=average |  eval _value/(1024*1024) | avg by dbidentifier, namespace, region, account"
      }
      triggers = [
        {
          detection_method = "MetricsStaticCondition",
          time_range       = "-15m",
          trigger_type     = "Critical",
          threshold        = 512,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "MetricsStaticCondition",
          time_range       = "-15m",
          trigger_type     = "ResolvedCritical",
          threshold        = 512,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ],
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "RdsLowFreeableMemory" = {
      monitor_name         = "Amazon RDS - Low Freeable Memory"
      monitor_description  = "This alert fires when the average Freeable memory of an RDS instance is < 128 MB for an interval of 15 minutes. If this value is lower you may need to scale up to a larger instance class."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "account=* region=* namespace=aws/rds metric=FreeableMemory statistic=average |  eval _value/(1024*1024) | avg by dbidentifier, namespace, region, account"
      }
      triggers = [
        {
          detection_method = "MetricsStaticCondition",
          time_range       = "-15m",
          trigger_type     = "Critical",
          threshold        = 128,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "MetricsStaticCondition",
          time_range       = "-15m",
          trigger_type     = "ResolvedCritical",
          threshold        = 128,
          threshold_type   = "GreaterThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ],
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    }
  }
}