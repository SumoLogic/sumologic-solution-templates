module "ec2metrics_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** No Metric Rules for EC2 Metrics ********************** #

  # ********************** Fields ********************** #
  managed_fields = {
    "InstanceId" = {
      field_name = "instanceid"
      data_type  = "String"
      state      = true
    }
  }

  # ********************** No FERs for EC2 Metrics ********************** #

  # ********************** Apps ********************** #
  managed_apps = {
    "EC2MetricsApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/EC2-Metrics-App.json"])
      folder_id    = var.app_folder_id
    }
  }

  # ********************** Monitors ********************** #
  managed_monitors = {
    "AWSEC2HighCPUSysUtilization" = {
      monitor_name         = "AWS EC2 - High System CPU Utilization"
      monitor_description  = "This alert fires when the average system CPU utilization within a 5 minute interval for an EC2 instance is high (>=85%)."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/ec2 metric=CPU_Sys account=* region=* instanceid=* | avg by account, region, namespace, instanceid"
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
    "AWSEC2HighCPUTotalUtilization" = {
      monitor_name         = "AWS EC2 - High Total CPU Utilization"
      monitor_description  = "This alert fires when the average total CPU utilization within a 5 minute interval for an EC2 instance is high (>=85%)."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/ec2 metric=CPU_Total account=* region=* instanceid=* | avg by account, region, namespace, instanceid"
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
    "AWSEC2HighMemoryUtilization" = {
      monitor_name         = "AWS EC2 - High Memory Utilization"
      monitor_description  = "This alert fires when the average memory utilization within a 5 minute interval for an EC2 instance is high (>=85%)."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/ec2 metric=Mem_UsedPercent account=* region=* instanceid=* | avg by account, region, namespace, instanceid"
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
    "AWSEC2HighDiskUtilization" = {
      monitor_name         = "AWS EC2 - High Disk Utilization"
      monitor_description  = "This alert fires when the average disk utilization within a 5 minute time interval for an EC2 instance is high (>=85%)."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/ec2 metric=Disk_UsedPercent account=* region=* instanceid=* | avg by account, region, namespace, instanceid, devname"
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