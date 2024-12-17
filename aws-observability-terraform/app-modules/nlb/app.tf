module "nlb_module" {
  source = "git::https://github.com/SumoLogic/terraform-sumologic-sumo-logic-integrations.git//sumologic?ref=sumo_246624"
  #source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** Metric Rules ********************** #
  managed_metric_rules = {
    "NLBMetricRule" = {
      metric_rule_name = "AwsObservabilityNLBMetricsEntityRule"
      match_expression = "Namespace=AWS/NetworkELB LoadBalancer=*"
      # Issue with metric rules creation when created in parallel. To handle that sleep is added.
      sleep = 11
      variables_to_extract = [
        {
          name        = "networkloadbalancer"
          tagSequence = "$LoadBalancer._1"
        }
      ]
    }
  }

  # ********************** Fields ********************** #
  # managed_fields = {
  #   "NetworkLoadBalancer" = {
  #     field_name = "networkloadbalancer"
  #     data_type  = "String"
  #     state      = true
  #   }
  # }

  # ********************** No FERs for Network Load Balancers ********************** #
  # managed_field_extraction_rules = {
  #   "NLBAccessLogsFieldExtractionRule" = {
  #     name             = "AwsObservabilityNlbAccessLogsFER"
  #     scope            = "account=* region=* namespace=aws/networkloadbalancer"
  #     parse_expression = <<EOT
  #             | parse "* * * * * * * * * * * * \"*\" \"*\" * * * \"*\"" as Type, DateTime, loadbalancer, Client, Target, RequestProcessingTime, TargetProcessingTime, ResponseProcessingTime, ElbStatusCode, TargetStatusCode, ReceivedBytes, SentBytes, Request, UserAgent, SslCipher, SslProtocol, TargetGroupArn, TraceId
  #             | tolowercase(loadbalancer) as loadbalancer
  #             | fields loadbalancer
  #     EOT
  #     enabled          = true
  #   }
  # }

  # ********************** Apps ********************** #
  managed_apps = {
    "NlbApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/Nlb-App.json"])
      folder_id    = var.app_folder_id
    }
  }

  # ********************** Monitors ********************** #
  managed_monitors = {
    "AWSNetworkLoadBalancerHighTLSNegotiationErrors" = {
      monitor_name         = "AWS Network Load Balancer - High TLS Negotiation Errors"
      monitor_description  = "This alert fires when we detect that there are too many TLS Negotiation Errors (>=10%) within an interval of 5 minutes for a given network load balancer"
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/NetworkELB metric=ClientTLSNegotiationErrorCount Statistic=sum account=* region=* LoadBalancer=* | sum by LoadBalancer, account, region, namespace"
        B = "Namespace=aws/NetworkELB metric=TargetTLSNegotiationErrorCount Statistic=sum account=* region=* LoadBalancer=* | sum by LoadBalancer, account, region, namespace"
        C = "(#A + #B) along LoadBalancer, account, region, namespace"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 10,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 10,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSNetworkLoadBalancerDeletionAlert" = {
      monitor_name         = "AWS Network Load Balancer - Deletion Alert"
      monitor_description  = "This alert fires when we detect greater than or equal to 2 network load balancers are deleted over a 5 minute time-period."
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* \"\"eventsource\":\"elasticloadbalancing.amazonaws.com\"\" \"errorCode\" \"2015-12-01\" | json \"eventSource\", \"eventName\",\"apiVersion\" as event_source, event_name, api_version nodrop | where event_source = \"elasticloadbalancing.amazonaws.com\" and api_version matches \"2015-12-01\" and namespace matches \"aws/networkelb\" | where event_name matches \"DeleteLoadBalancer\""
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 2,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 2,
          threshold_type   = "LessThan",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        }
      ],
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSNetworkLoadBalancerTargetsDeregistered" = {
      monitor_name         = "AWS Network Load Balancer - Targets Deregistered"
      monitor_description  = "This alert fires when we detect greater than or equal to 1 target is de-registered over a 5 minute time-period."
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* \"\"eventsource\":\"elasticloadbalancing.amazonaws.com\"\" \"errorCode\" \"2015-12-01\" | json \"eventSource\", \"eventName\",\"apiVersion\" as event_source, event_name, api_version nodrop | where event_source = \"elasticloadbalancing.amazonaws.com\" and api_version matches \"2015-12-01\" and namespace matches \"aws/networkelb\" | where event_name matches \"DeregisterTargets\""
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 1,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 1,
          threshold_type   = "LessThan",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        }
      ],
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSNetworkLoadBalancerHighUnhealthyHosts" = {
      monitor_name         = "AWS Network Load Balancer - High Unhealthy Hosts"
      monitor_description  = "This alert fires when we detect that are there are too many unhealthy hosts (>=10%) within an interval of 5 minutes for a given network load balancer"
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/NetworkELB metric=UnHealthyHostCount Statistic=sum account=* region=* LoadBalancer=* AvailabilityZone=* | sum by LoadBalancer, AvailabilityZone, account, region, namespace"
        B = "Namespace=aws/NetworkELB metric=HealthyHostCount Statistic=sum account=* region=* LoadBalancer=* AvailabilityZone=* | sum by LoadBalancer, AvailabilityZone, account, region, namespace"
        C = "#A * 100 / (#A + #B) along LoadBalancer, AvailabilityZone, account, region, namespace"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 10,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 10,
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