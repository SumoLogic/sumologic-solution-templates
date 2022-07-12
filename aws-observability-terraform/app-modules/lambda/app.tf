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
    }
  }
}