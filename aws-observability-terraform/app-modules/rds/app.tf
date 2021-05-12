module "rds_module" {
  source = "../common"

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
      sleep            = 3
      variables_to_extract = [
        {
          name        = "dbidentifier"
          tagSequence = "$DBInstanceIdentifier._1"
        }
      ]
    }
  }

  # ********************** Fields ********************** #

  managed_fields = {
    "DBIdentifier" = {
      field_name = "dbidentifier"
      data_type  = "String"
      state      = true
    }
  }

  # ********************** FERs ********************** #

  managed_field_extraction_rules = {
    "CloudTrailFieldExtractionRule" = {
      name             = "AwsObservabilityRdsCloudTrailLogsFER"
      scope            = "account=* eventname eventsource \"rds.amazonaws.com\""
      parse_expression = <<EOT
              json "eventSource", "awsRegion", "requestParameters", "responseElements" as eventSource, region, requestParameters, responseElements nodrop
              | where eventSource = "rds.amazonaws.com"
              | "aws/rds" as namespace
              | json field=requestParameters "dBInstanceIdentifier", "resourceName", "dBClusterIdentifier" as dBInstanceIdentifier1, resourceName, dBClusterIdentifier1 nodrop
              | json field=responseElements "dBInstanceIdentifier" as dBInstanceIdentifier3 nodrop | json field=responseElements "dBClusterIdentifier" as dBClusterIdentifier3 nodrop
              | parse field=resourceName "arn:aws:rds:*:db:*" as f1, dBInstanceIdentifier2 nodrop | parse field=resourceName "arn:aws:rds:*:cluster:*" as f1, dBClusterIdentifier2 nodrop
              | if (resourceName matches "arn:aws:rds:*:db:*", dBInstanceIdentifier2, if (!isEmpty(dBInstanceIdentifier1), dBInstanceIdentifier1, dBInstanceIdentifier3) ) as dBInstanceIdentifier
              | if (resourceName matches "arn:aws:rds:*:cluster:*", dBClusterIdentifier2, if (!isEmpty(dBClusterIdentifier1), dBClusterIdentifier1, dBClusterIdentifier3) ) as dBClusterIdentifier
              | if (isEmpty(dBInstanceIdentifier), dBClusterIdentifier, dBInstanceIdentifier) as dbidentifier
              | tolowercase(dbidentifier) as dbidentifier
              | fields region, namespace, dBInstanceIdentifier, dBClusterIdentifier, dbidentifier
      EOT
      enabled          = true
    }
  }

  # ********************** Apps ********************** #

  managed_apps = {
    "RdsApp" = {
      content_json = "/aws-observability/json/Rds-App.json"
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
    }
  }
}