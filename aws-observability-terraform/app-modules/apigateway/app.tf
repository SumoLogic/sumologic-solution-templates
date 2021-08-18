module "apigateway_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** No Metric Rules for API Gateway ********************** #

  # ********************** Fields ********************** #
  managed_fields = {
    "APIName" = {
      field_name = "apiname"
      data_type  = "String"
      state      = true
    }
  }

  # ********************** FERs ********************** #
  managed_field_extraction_rules = {
    "CloudTrailFieldExtractionRule" = {
      name             = "AwsObservabilityApiGatewayCloudTrailLogsFER"
      scope            = "account=* eventname eventsource \"apigateway.amazonaws.com\""
      parse_expression = <<EOT
              | json "eventSource", "awsRegion", "responseElements", "recipientAccountId" as eventSource, region, responseElements, accountid nodrop
              | where eventSource = "apigateway.amazonaws.com"
              | "aws/apigateway" as namespace
              | json field=responseElements "name" as ApiName nodrop
              | tolowercase(ApiName) as apiname
              | fields region, namespace, apiname, accountid
      EOT
      enabled          = true
    }
  }

  # ********************** Apps ********************** #
  managed_apps = {
    "APIGatewayApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/Api-Gateway-App.json"])
      folder_id    = var.app_folder_id
    }
  }

  # ********************** Monitors ********************** #
  managed_monitors = {
    "AWSAPIGatewayHigh5XXErrors" = {
      monitor_name         = "AWS API Gateway - High 5XX Errors"
      monitor_description  = "This alert fires where there are too many HTTP requests (>5%) with a response status of 5xx within an interval of 5 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/apigateway metric=5xxError Statistic=Sum account=* region=* apiname=* | sum by apiname, account, region, namespace"
        B = "Namespace=aws/apigateway metric=count Statistic=Sum account=* region=* apiname=* | sum by apiname, account, region, namespace"
        C = "#A * 100 / #B along account, region, namespace"
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
    "AWSAPIGatewayHigh4XXErrors" = {
      monitor_name         = "AWS API Gateway - High 4XX Errors"
      monitor_description  = "This alert fires where there are too many HTTP requests (>5%) with a response status of 4xx within an interval of 5 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/apigateway metric=4xxError Statistic=Sum account=* region=* apiname=* | sum by apiname, account, region, namespace"
        B = "Namespace=aws/apigateway metric=count Statistic=Sum account=* region=* apiname=* | sum by apiname, account, region, namespace"
        C = "#A * 100 / #B along apiname, account, region, namespace"
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
    "AWSAPIGatewayHighIntegrationLatency" = {
      monitor_name         = "AWS API Gateway - High Integration Latency"
      monitor_description  = "This alert fires when we detect that the average integration latency for a given API Gateway is greater than or equal to one second for 5 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/apigateway metric=IntegrationLatency statistic=Average account=* region=* apiname=* | avg by apiname, namespace, region, account"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 1000,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 1000,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSAPIGatewayHighLatency" = {
      monitor_name         = "AWS API Gateway - High Latency"
      monitor_description  = "This alert fires when we detect that the average latency for a given API Gateway is greater than or equal to one second for 5 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/apigateway metric=Latency statistic=Average account=* region=* apiname=* | avg by apiname, namespace, region, account"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 1000,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 1000,
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