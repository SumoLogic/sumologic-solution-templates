module "elasticache_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** No Metric Rules for Elasticache ********************** #

  # ********************** Fields ********************** #
  # managed_fields = {
  #   "CacheClusterId" = {
  #     field_name = "cacheclusterid"
  #     data_type  = "String"
  #     state      = true
  #   }
  # }

  # ********************** FERs ********************** #
  managed_field_extraction_rules = {
    "CloudTrailFieldExtractionRule" = {
      name             = "AwsObservabilityElastiCacheCloudTrailLogsFER"
      scope            = "account=* eventname eventsource \"elasticache.amazonaws.com\""
      parse_expression = <<EOT
              | json "eventSource", "awsRegion", "requestParameters.cacheClusterId", "responseElements.cacheClusterId", "recipientAccountId" as eventSource, region, req_cacheClusterId, res_cacheClusterId, accountid nodrop
              | where eventSource = "elasticache.amazonaws.com"
              | if (!isEmpty(req_cacheClusterId), req_cacheClusterId, res_cacheClusterId) as cacheclusterid
              | "aws/elasticache" as namespace
              | tolowercase(cacheclusterid) as cacheclusterid
              | fields region, namespace, cacheclusterid, accountid
      EOT
      enabled          = true
    }
  }

  # ********************** Apps ********************** #
  managed_apps = {
    "ElastiCacheApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/ElastiCache-App.json"])
      folder_id    = var.app_folder_id
    }
  }

  # ********************** Monitors ********************** #
  managed_monitors = {
    "AmazonElasticacheMultipleFailedOperations" = {
      monitor_name         = "Amazon Elasticache - Multiple Failed Operations"
      monitor_description  = "This alert fires when we detect multiple failed operations within a 15 minute interval for an ElastiCache service."
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "account=* region=* namespace=aws/elasticache \"\\\"eventSource\\\":\\\"elasticache.amazonaws.com\\\"\" errorCode errorMessage\n| json \"eventSource\", \"errorCode\", \"errorMessage\", \"userIdentity\", \"requestParameters\", \"responseElements\"  as event_source, error_code, error_message, user_identity, requestParameters, responseElements nodrop\n| json field=requestParameters \"cacheClusterId\" as req_cacheClusterId nodrop\n| json field=responseElements \"cacheClusterId\" as res_cacheClusterId nodrop\n| json field=user_identity \"arn\", \"userName\" nodrop \n| parse field=arn \":assumed-role/*\" as user nodrop  \n| parse field=arn \"arn:aws:iam::*:*\" as accountId, user nodrop\n| if (isEmpty(userName), user, userName) as user\n| if (isEmpty(req_cacheClusterId), res_cacheClusterId, req_cacheClusterId) as cacheclusterid\n| where event_source matches \"elasticache.amazonaws.com\" and !isEmpty(error_code) and !isEmpty(error_message) and !isEmpty(user)\n| count as event_count by _messageTime, account, region, event_source, error_code, error_message, user, cacheclusterid\n| formatDate(_messageTime, \"MM/dd/yyyy HH:mm:ss:SSS Z\") as message_date\n| fields message_date, account, region, event_source, error_code, error_message, user, cacheclusterid\n| fields -_messageTime"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-15m",
          trigger_type     = "Critical",
          threshold        = 10,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-15m",
          trigger_type     = "ResolvedCritical",
          threshold        = 10,
          threshold_type   = "LessThan",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AmazonElasticacheHighRedisDatabaseMemoryUsage" = {
      monitor_name         = "Amazon Elasticache - High Redis Database Memory Usage"
      monitor_description  = "This alert fires when the average database memory usage within a 5 minute interval for the Redis engine is high (>=95%). When the value reaches 100%, eviction may happen or write operations may fail based on ElastiCache policies thereby impacting application performance."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/elasticache metric=DatabaseMemoryUsagePercentage statistic=Average account=* region=* CacheClusterId=* CacheNodeId=* | avg by account, region, namespace, CacheClusterId, CacheNodeId"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 95,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 95,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AmazonElasticacheHighCPUUtilization" = {
      monitor_name         = "Amazon Elasticache - High CPU Utilization"
      monitor_description  = "This alert fires when the average CPU utilization within a 5 minute interval for a host is  high (>=90%). The CPUUtilization metric includes total CPU utilization across application, operating system and management processes. We highly recommend monitoring  CPU utilization for hosts with two vCPUs or less."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/elasticache metric=CPUUtilization statistic=Average account=* region=* CacheClusterId=* CacheNodeId=* | avg by CacheClusterId, CacheNodeId, account, region, namespace"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 90,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 90,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ],
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AmazonElasticacheHighRedisMemoryFragmentationRatio" = {
      monitor_name         = "Amazon Elasticache - High Redis Memory Fragmentation Ratio"
      monitor_description  = "This alert fires when the average Redis memory fragmentation ratio for within a 5 minute interval is high (>=1.5). Value equal to or greater than 1.5 Indicate significant memory fragmentation."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/elasticache metric=MemoryFragmentationRatio statistic=Average account=* region=* CacheClusterId=* CacheNodeId=* | avg by account, region, namespace, CacheClusterId, CacheNodeId"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 1.5,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 1.5,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ],
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AmazonElasticacheLowRedisCacheHitRate" = {
      monitor_name         = "Amazon Elasticache - Low Redis Cache Hit Rate"
      monitor_description  = "This alert fires when the average cache hit rate for Redis within a 5 minute interval is low (<= 80%). This indicates low efficiency of the Redis instance. If  cache ratio is lower than 80%, that indicates a significant amount of keys are either evicted, expired, or don't exist."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/elasticache metric=CacheHitRate statistic=Average account=* region=* CacheClusterId=* CacheNodeId=* | avg by account, region, namespace, CacheClusterId, CacheNodeId"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 80,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 80,
          threshold_type   = "GreaterThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ],
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AmazonElasticacheHighEngineCPUUtilization" = {
      monitor_name         = "Amazon Elasticache - High Engine CPU Utilization"
      monitor_description  = "This alert fires when the average CPU utilization for the Redis engine process within a 5 minute interval is  high (>=90%). For larger node types with four vCPUs or more, use the EngineCPUUtilization metric to monitor and set thresholds for scaling."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/elasticache metric=EngineCPUUtilization statistic=Average account=* region=* CacheClusterId=* CacheNodeId=* | avg by CacheClusterId, CacheNodeId, account, region, namespace"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 90,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 90,
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