module "alb_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** No Metric Rules for ALB ********************** #

  # ********************** Fields ********************** #
  # managed_fields = {
  #   "LoadBalancer" = {
  #     field_name = "loadbalancer"
  #     data_type  = "String"
  #     state      = true
  #   }
  # }

  # ********************** FERs ********************** #
  managed_field_extraction_rules = {
    "AlbAccessLogsFieldExtractionRule" = {
      name             = "AwsObservabilityAlbAccessLogsFER"
      scope            = "account=* region=* (http or https or h2 or grpcs or ws or wss)"
      parse_expression = <<EOT
              | parse "* * * * * * * * * * * * \"*\" \"*\" * * * \"*\"" as Type, DateTime, loadbalancer, Client, Target, RequestProcessingTime, TargetProcessingTime, ResponseProcessingTime, ElbStatusCode, TargetStatusCode, ReceivedBytes, SentBytes, Request, UserAgent, SslCipher, SslProtocol, TargetGroupArn, TraceId
              | where Type in ("http","https","h2","grpcs","ws","wss")
              | where !isBlank(loadbalancer)
              | "aws/applicationelb" as namespace
              | tolowercase(loadbalancer) as loadbalancer | fields loadbalancer, namespace
      EOT
      enabled          = true
    }
  }

  # ********************** Apps ********************** #
  managed_apps = {
    "ALBApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/Alb-App.json"])
      folder_id    = var.app_folder_id
    }
  }

  # ********************** Monitors ********************** #
  managed_monitors = {
    "AWSApplicationLoadBalancerAccessfromHighlyMaliciousSources" = {
      monitor_name         = "AWS Application Load Balancer - Access from Highly Malicious Sources"
      monitor_description  = "This alert fires when an Application load balancer is accessed from highly malicious IP addresses within last 5 minutes"
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "account=* region=* namespace=aws/applicationelb\n| parse \"* * * * * * * * * * * * \\\"*\\\" \\\"*\\\" * * * \\\"*\\\"\" as Type, DateTime, loadbalancer, Client, Target, RequestProcessingTime, TargetProcessingTime, ResponseProcessingTime, ElbStatusCode, TargetStatusCode, ReceivedBytes, SentBytes, Request, UserAgent, SslCipher, SslProtocol, TargetGroupArn, TraceId\n| parse regex \"(?<ClientIp>\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})\" multi\n| where ClientIp != \"0.0.0.0\" and ClientIp != \"127.0.0.1\"\n| count as ip_count by ClientIp, loadbalancer, account, region, namespace\n| lookup type, actor, raw, threatlevel as MaliciousConfidence from sumo://threat/cs on threat=ClientIp \n| json field=raw \"labels[*].name\" as LabelName \n| replace(LabelName, \"\\\\/\",\"->\") as LabelName\n| replace(LabelName, \"\\\"\",\" \") as LabelName\n| where type=\"ip_address\" and MaliciousConfidence=\"high\"\n| if (isEmpty(actor), \"Unassigned\", actor) as Actor\n| sum (ip_count) as ThreatCount by ClientIp, loadbalancer, account, region, namespace, MaliciousConfidence, Actor, LabelName"
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
    "AWSApplicationLoadBalancerHigh4XXErrors" = {
      monitor_name         = "AWS Application Load Balancer - High 4XX Errors"
      monitor_description  = "This alert fires where there are too many HTTP requests (>5%) with a response status of 4xx within an interval of 5 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/applicationelb metric=HTTPCode_ELB_4XX_Count Statistic=Sum account=* region=* loadbalancer=* | sum by loadbalancer, account, region, namespace"
        B = "Namespace=aws/applicationelb metric=RequestCount Statistic=Sum account=* region=* loadbalancer=* | sum by loadbalancer, account, region, namespace"
        C = "#A * 100 / #B along loadbalancer, account, region, namespace"
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
    "AWSApplicationLoadBalancerHighLatency" = {
      monitor_name         = "AWS Application Load Balancer - High Latency"
      monitor_description  = "This alert fires when we detect that the average latency for a given Application load balancer within a time interval of 5 minutes is greater than or equal to three seconds."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/applicationelb metric=TargetResponseTime Statistic=Average account=* region=* loadbalancer=* | eval(_value*1000) | sum by account, region, namespace, loadbalancer"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 3000,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 3000,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ],
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSApplicationLoadBalancerHigh5XXErrors" = {
      monitor_name         = "AWS Application Load Balancer - High 5XX Errors"
      monitor_description  = "This alert fires where there are too many HTTP requests (>5%) with a response status of 5xx within an interval of 5 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/applicationelb metric=HTTPCode_ELB_5XX_Count Statistic=Sum account=* region=* loadbalancer=* | sum by loadbalancer, account, region, namespace"
        B = "Namespace=aws/applicationelb metric=RequestCount Statistic=Sum account=* region=* loadbalancer=* | sum by loadbalancer, account, region, namespace"
        C = "#A * 100 / #B along loadbalancer, account, region, namespace"
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
    }
  }
}