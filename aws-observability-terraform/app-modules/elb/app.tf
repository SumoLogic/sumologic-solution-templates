module "classic_elb_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** Required Fields and FERs are created at aws-observability-terraform/field.tf ********************** #

  # ********************** Apps ********************** #
  managed_apps = {
    "ClassicLBApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/Classic-lb-App.json"])
      folder_id    = var.app_folder_id
    }
  }

  # ********************** Monitors ********************** #
  managed_monitors = {
    "AWSClassicLoadBalancerAccessfromHighlyMaliciousSources" = {
      monitor_name         = "AWS Classic Load Balancer - Access from Highly Malicious Sources"
      monitor_description  = "This alert fires when the Classic load balancer is accessed from highly malicious IP addresses within last 5 minutes."
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* namespace=aws/elb\n| parse \"* * * * * * * * * * * \\\"*\\\" \\\"*\\\" * *\" as datetime, loadbalancername, client, backend, request_processing_time, backend_processing_time, response_processing_time, elb_status_code, backend_status_code, received_bytes, sent_bytes, request, user_agent, ssl_cipher, ssl_protocol\n| parse regex \"(?<ClientIp>\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})\" multi\n| where ClientIp != \"0.0.0.0\" and ClientIp != \"127.0.0.1\"\n| count as ip_count by ClientIp, loadbalancername, account, region, namespace\n| lookup type, actor, raw, threatlevel as MaliciousConfidence from sumo://threat/cs on threat=ClientIp \n| json field=raw \"labels[*].name\" as LabelName \n| replace(LabelName, \"\\\\/\",\"->\") as LabelName\n| replace(LabelName, \"\\\"\",\" \") as LabelName\n| where type=\"ip_address\" and MaliciousConfidence=\"high\"\n| if (isEmpty(actor), \"Unassigned\", actor) as Actor\n| sum (ip_count) as ThreatCount by ClientIp, loadbalancername, account, region, namespace, MaliciousConfidence, Actor, LabelName"
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
    "AWSClassicLoadBalancerHigh4XXErrors" = {
      monitor_name         = "AWS Classic Load Balancer - High 4XX Errors"
      monitor_description  = "This alert fires where there are too many HTTP requests (>5%) with a response status of 4xx within an interval of 5 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/elb metric=HTTPCode_ELB_4XX Statistic=Sum account=* region=* loadbalancername=* | sum by loadbalancername, account, region, namespace"
        B = "Namespace=aws/elb metric=RequestCount Statistic=Sum account=* region=* loadbalancername=* | sum by loadbalancername, account, region, namespace"
        C = "#A * 100 / #B along loadbalancername, account, region, namespace"
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
    "AWSClassicLoadBalancerHighLatency" = {
      monitor_name         = "AWS Classic Load Balancer - High Latency"
      monitor_description  = "This alert fires when we detect that the average latency for a given Classic load balancer within a time interval of 5 minutes is greater than or equal to three seconds."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/elb metric=Latency Statistic=Average account=* region=* loadbalancername=* | eval(_value*1000) | sum by account, region, namespace, loadbalancername"
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
    "AWSClassicLoadBalancerHigh5XXErrors" = {
      monitor_name         = "AWS Classic Load Balancer - High 5XX Errors"
      monitor_description  = "This alert fires where there are too many HTTP requests (>5%) with a response status of 5xx within an interval of 5 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/elb metric=HTTPCode_ELB_5XX Statistic=Sum account=* region=* loadbalancername=* | sum by loadbalancername, account, region, namespace"
        B = "Namespace=aws/elb metric=RequestCount Statistic=Sum account=* region=* loadbalancername=* | sum by loadbalancername, account, region, namespace"
        C = "#A * 100 / #B along loadbalancername, account, region, namespace"
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