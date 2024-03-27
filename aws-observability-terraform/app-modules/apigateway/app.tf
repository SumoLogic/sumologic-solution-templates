module "apigateway_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** No Metric Rules for API Gateway ********************** #

  # ********************** Required Fields and FERs are created at aws-observability-terraform/field.tf ********************** #

  # ********************** Apps ********************** #
  managed_apps = {
    "APIGatewayApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/Api-Gateway-App.json"])
      folder_id    = var.app_folder_id
    }
  }

  # ********************** Metric Rules ********************** #
  managed_metric_rules = {
    "ApiNameMetricRule" = {
      metric_rule_name = "AwsObservabilityApiGatewayApiNameMetricsEntityRule"
      match_expression = "Namespace=AWS/ApiGateway apiid=*"
      sleep            = 0
      variables_to_extract = [
        {
          name        = "apiname"
          tagSequence = "$apiid._1"
        }
      ]
    }
  }

  # ********************** Monitors ********************** #
  managed_monitors = {
    "AWSAPIGatewayServerSideErrors" = {
      monitor_name         = "AWS API Gateway - High Server-Side Errors"
      monitor_description  = "This alert fires where there are too many API requests (>5%) with server-side errors within 5 minutes. This can be caused by 5xx errors from your integration, permission issues, or other factors preventing successful invocation of the integration, such as the integration being throttled or deleted."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/apigateway (metric=5XX or metric=5xxError or metric=ExecutionError) Statistic=Average account=* region=* apiname=* stage=* !(route=*) !(resource=*) | avg by apiname, namespace, region, account, stage"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 0.05,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 0.05,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSAPIGatewayHighClientSideErrors" = {
      monitor_name         = "AWS API Gateway - High Client-Side Errors"
      monitor_description  = "This alert fires where there are too many API requests (>5%) with client-side errors within 5 minutes. This can indicate an issue in the authorisation or client request parameters. It could also mean that a resource was removed or a client is requesting one that doesn't exist.Errors could also be caused by exceeding the configured throttling limit."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/apigateway (metric=4XX or metric=4xxError or metric=ClientError) Statistic=Average account=* region=* apiname=* stage=* !(route=*) !(resource=*) | avg by apiname, namespace, region, account, stage"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 0.05,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 0.05,
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
      monitor_description  = "This alert fires when we detect the high integration latency for the API requests in a stage within 5 minutes. This alarm is recommended for WebSocket APIs by AWS, and optional for other APIs because they already have separate alarm recommendations for the Latency metric. You can correlate the IntegrationLatency metric value with the corresponding latency metric of your backend such as the Duration metric for Lambda integrations. This helps you determine whether the API backend is taking more time to process requests from clients due to performance issues or if there is some other overhead from initialization or cold start."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "account=* region=* Namespace=aws/apigateway metric=IntegrationLatency statistic=p90 apiname=* stage=* !(route=*) !(resource=*) | avg by apiname, namespace, region, account, stage"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 2000,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 2000,
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
      monitor_description  = "This alert fires when we detect the high Latency in a stage within 5 minutes for REST and HTTP API. Find the IntegrationLatency metric value to check the API backend latency. If the two metrics are mostly aligned, the API backend is the source of higher latency and you should investigate there for issues. View this metric per resource and method and narrow down the source of the latency."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "account=* region=* Namespace=aws/apigateway metric=Latency statistic=p90 apiname=* stage=* !(route=*) !(resource=*) | avg by apiname, namespace, region, account, stage"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 2500,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 2500,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSAPIGatewayHighAuthorizerErrors" = {
      monitor_name         = "AWS API Gateway - High Authorizer Errors"
      monitor_description  = "This alert fires where there are too many API requests (>5%) with authorizer errors within 5 minutes."
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* namespace=aws/apigateway apiname=* apiid stage domainname requestId authorizerError\n| json \"status\", \"authorizerError\", \"apiid\", \"stage\" as status, authorizerError, apiid, stage \n| if (!(authorizerError matches \"-\") and !(status matches \"2*\"), 1, 0) as is_authorizerError \n| sum(is_authorizerError) as is_authorizerError_count, count as totalRequests by apiid, stage \n| (is_authorizerError_count*100/totalRequests) as authorizerError_percent \n| fields authorizerError_percent, apiid, stage"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 5,
          threshold_type   = "GreaterThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 5,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSAPIGatewayHighIntegrationErrors" = {
      monitor_name         = "AWS API Gateway - High Integration Errors"
      monitor_description  = "This alert fires where there are too many API requests (>5%) with integration errors within 5 minutes."
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* namespace=aws/apigateway apiname=* apiid stage domainname requestId integrationError\n| json \"status\", \"integrationError\", \"apiid\", \"stage\" as status, integrationError, apiid, stage \n| if (!(integrationError matches \"-\") and !(status matches \"2*\"), 1, 0) as is_integrationError \n| sum(is_integrationError) as integrationError_count, count as totalRequests by apiid, stage \n| (integrationError_count*100/totalRequests) as integrationError_percent \n| fields integrationError_percent, apiid, stage"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 5,
          threshold_type   = "GreaterThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 5,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSAPIGatewayHighWAFErrors" = {
      monitor_name         = "AWS API Gateway - High WAF Errors"
      monitor_description  = "This alert fires where there are too many API requests (>5%) with WAF errors within 5 minutes."
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* namespace=aws/apigateway apiname=* apiid stage domainname requestId \n| json  \"status\", \"apiid\", \"stage\", \"wafResponseCode\" as  status, apiid, stage, wafResponseCode \n| if (wafResponseCode==\"WAF_BLOCK\" and !(status matches \"2*\"), 1, 0) as is_wafError \n| sum(is_wafError) as is_wafError_count, count as totalRequests by apiid, stage \n| (is_wafError_count*100/totalRequests) as wafError_percent \n| fields wafError_percent, apiid, stage"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 5,
          threshold_type   = "GreaterThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 5,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSAPIGatewayHighWAFLatency" = {
      monitor_name         = "AWS API Gateway - High WAF Latency"
      monitor_description  = "This alert fires when we detect the high WAF latency for the REST and WebSocket API requests in a stage within 5 minutes."
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* namespace=* apiname=* apiid stage domainname requestId wafLatency \n| json \"wafLatency\", \"apiId\", \"stage\" as wafLatency, apiid, stage \n| pct(wafLatency, 90) as wafLatency90th by apiid,stage"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 1000,
          threshold_type   = "GreaterThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 1000,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSAPIGatewayLowTrafficAPI" = {
      monitor_name         = "AWS API Gateway - Low Traffic API"
      monitor_description  = "This alert fires where there is low message traffic volume for the API within 5 minutes. This can indicate an issue with the application calling the API such as using incorrect endpoints. It could also indicate an issue with the configuration or permissions of the API making it unreachable for clients. This alarm is not recommended for APIs that don't expect constant and consistent traffic."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/apigateway (metric=ConnectCount OR metric=Count) statistic=SampleCount account=* region=* apiname=* stage=* !(route=*) !(resource=*) | quantize using sum | sum by apiname, namespace, region, account, stage"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-10m",
          trigger_type     = "Critical",
          threshold        = 1,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-10m",
          trigger_type     = "ResolvedCritical",
          threshold        = 1,
          threshold_type   = "GreaterThan",
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