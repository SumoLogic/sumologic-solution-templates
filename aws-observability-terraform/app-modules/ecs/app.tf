module "ecs_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** No Metric Rules for ECS ********************** #

  # ********************** Fields ********************** #
  # managed_fields = {
  #   "ClusterName" = {
  #     field_name = "clustername"
  #     data_type  = "String"
  #     state      = true
  #   }
  # }

  # ********************** FERs ********************** #
  managed_field_extraction_rules = {
    "CloudTrailFieldExtractionRule" = {
      name             = "AwsObservabilityECSCloudTrailLogsFER"
      scope            = "account=* eventname eventsource \"ecs.amazonaws.com\""
      parse_expression = <<EOT
              | json "eventSource", "awsRegion", "requestParameters", "recipientAccountId" as eventSource, region, requestParameters, accountid nodrop
              | json field=requestParameters "cluster" as clustername nodrop
              | where eventSource = "ecs.amazonaws.com"
              | "aws/ecs" as namespace
              | fields region, namespace, clustername, accountid
      EOT
      enabled          = true
    }
  }

  # ********************** Apps ********************** #
  managed_apps = {
    "ecsApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/Ecs-App.json"])
      folder_id    = var.app_folder_id
    }
  }

  # ********************** Monitors ********************** #
  managed_monitors = {
    "AmazonECSHighCPUUtilization" = {
      monitor_name         = "Amazon ECS - High CPU Utilization"
      monitor_description  = "This alert fires when the average CPU utilization within a 5 minute interval for a service within a cluster is high (>=85%)."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/ecs metric=CPUUtilization statistic=Average account=* region=* ClusterName=* ServiceName=* | avg by ClusterName, ServiceName, account, region, namespace"
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
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AmazonECSHighMemoryUtilization" = {
      monitor_name         = "Amazon ECS - High Memory Utilization"
      monitor_description  = "This alert fires when the average memory utilization within a 5 minute interval for a service within a cluster is high (>=85%)."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/ecs metric=MemoryUtilization statistic=Average  account=* region=* ClusterName=* ServiceName=* | avg by ClusterName, ServiceName, account, region, namespace"
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
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    }
  }
}