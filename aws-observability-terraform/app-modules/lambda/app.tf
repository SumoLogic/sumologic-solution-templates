module "lambda_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** No Metric Rules for Lambda ********************** #

  # ********************** Required Fields and FERs are created at aws-observability-terraform/field.tf ********************** #

  # ********************** Apps ********************** #
  managed_apps = {
    "LambdaApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/Lambda-App.json"])
      folder_id    = var.app_folder_id
    }
  }

  # ********************** Monitors ********************** #
  managed_monitors = {
    "AWSLambdaLowProvisionedConcurrencyUtilization" = {
      monitor_name         = "AWS Lambda - Low Provisioned Concurrency Utilization"
      monitor_description  = "This alert fires when the average provisioned concurrency utilization for 5 minutes is low (<= 50%). This indicates low provisioned concurrency utilization efficiency."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/lambda metric=ProvisionedConcurrencyUtilization statistic=Average account=* region=* functionname=* | avg by functionname, namespace, region, account"
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
    "AWSLambdaHighPercentageofFailedRequests" = {
      monitor_name         = "AWS Lambda - High Percentage of Failed Requests"
      monitor_description  = "This alert fires when we detect a large number of failed Lambda requests (>5%) within an interval of 5 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/lambda metric=Errors Statistic=Sum account=* region=* functionname=* | sum by functionname, account, region, namespace"
        B = "Namespace=aws/lambda metric=Invocations Statistic=Sum account=* region=* functionname=* | sum by functionname, account, region, namespace"
        C = "#A * 100 / #B along functionname, account, region, namespace"
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
    "AWSLambdaHighMemoryUtilization" = {
      monitor_name         = "AWS Lambda - High Memory Utilization"
      monitor_description  = "This alert fires when we detect a Lambda execution with memory usage of more than 85% within an interval of 10 minutes."
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* Namespace=aws/lambda Memory Size Used\n| json \"message\" nodrop | if (_raw matches \"{*\", message, _raw) as message\n| _sourceName as logStream | _sourceHost as logGroup\n| parse regex field=message \"REPORT\\s+RequestId:\\s+(?<RequestId>[^\\s]+)\\s+Duration:\\s+(?<Duration>[^\\s]+)\\s+ms\\s+Billed Duration:\\s+(?<BilledDuration>[^\\s]+)\\s+ms\\s+Memory\\s+Size:\\s+(?<MemorySize>[^\\s]+)\\s+MB\\s+Max\\s+Memory\\s+Used:\\s+(?<MaxMemoryUsed>[^\\s]+)\\s+MB\" \n| parse field=loggroup \"/aws/lambda/*\" as functionname\n| avg(MemorySize) as MemorySizeAvg, avg(MaxMemoryUsed) as MaxMemoryUsedAvg by functionname\n| (MaxMemoryUsedAvg/MemorySizeAvg)*100 as memoryUtilization\n| where memoryUtilization>85"
      }
      triggers = [
        {
          detection_method = "LogsStaticCondition",
          time_range       = "-10m",
          trigger_type     = "Critical",
          threshold        = 0,
          threshold_type   = "GreaterThan",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        },
        {
          detection_method = "LogsStaticCondition",
          time_range       = "-10m",
          trigger_type     = "ResolvedCritical",
          threshold        = 0,
          threshold_type   = "LessThan",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSLambdaThrottling" = {
      monitor_name         = "AWS Lambda - Throttling"
      monitor_description  = "This alert fires when we detect a Lambda running into throttling within an interval of 10 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/lambda metric=Throttles statistic=average account=* region=* functionname=* Resource=* | avg by account, region,namespace, functionname "
      }
      triggers = [
        {
          detection_method = "MetricsStaticCondition",
          time_range       = "-10m",
          trigger_type     = "Critical",
          threshold        = 0,
          threshold_type   = "GreaterThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "MetricsStaticCondition",
          time_range       = "-10m",
          trigger_type     = "ResolvedCritical",
          threshold        = 0,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    }
  }
}