module "dynamodb_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** No Metric Rules for DynamoDB ********************** #

  # ********************** Required Fields and FERs are created at aws-observability-terraform/field.tf ********************** #

  # ********************** Apps ********************** #
  managed_apps = {
    "DynamoDBApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/DynamoDb-App.json"])
      folder_id    = var.app_folder_id
    }
  }

  # ********************** Monitors ********************** #
  managed_monitors = {
    "AWSDynamoDBMultipleTablesdeleted" = {
      monitor_name         = "AWS DynamoDB - Multiple Tables deleted"
      monitor_description  = "This alert fires when five or more tables are deleted within 10 minutes."
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* namespace=aws/dynamodb eventSource \"dynamodb.amazonaws.com\"\n| json \"eventSource\", \"eventName\", \"requestParameters.tableName\", \"sourceIPAddress\", \"userIdentity.userName\", \"userIdentity.sessionContext.sessionIssuer.userName\" as event_source, event_name, tablename, SourceIp, UserName, ContextUserName nodrop\n| where event_source = \"dynamodb.amazonaws.com\" and event_name = \"DeleteTable\"\n| if (isEmpty(UserName), ContextUserName, UserName) as user\n| count by _messageTime, account, region, namespace, event_name, user, tablename\n| formatDate(_messageTime, \"MM/dd/yyyy HH:mm:ss:SSS Z\") as message_date\n| fields message_date, account, region, namespace, event_name, user, tablename\n| fields -_messageTime"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-15m",
          trigger_type     = "Critical",
          threshold        = 5,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-15m",
          trigger_type     = "ResolvedCritical",
          threshold        = 5,
          threshold_type   = "LessThan",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSDynamoDBHighAccountProvisionedReadCapacity" = {
      monitor_name         = "AWS DynamoDB - High Account Provisioned Read Capacity"
      monitor_description  = "This alert fires when we detect that the average read capacity provisioned for an account for a time interval of 5 minutes is greater than or equal to 80%. High values indicate requests to the database are being throttled, which could further indicate that your application may not be working as intended."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/dynamodb metric=AccountProvisionedReadCapacityUtilization statistic=Average account=* region=* | avg by namespace, region, account"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 80,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 80,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSDynamoDBHighMaxProvisionedTableWriteCapacity" = {
      monitor_name         = "AWS DynamoDB - High Max Provisioned Table Write Capacity"
      monitor_description  = "This alert fires when we detect that the average percentage of write provisioned capacity used by the highest write provisioned table of an account for a time interval of 5 minutes is great than or equal to 80%. High values indicate requests to the database are being throttled, which could further indicate that your application may not be working as intended."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/dynamodb metric=MaxProvisionedTableWriteCapacityUtilization statistic=Average account=* region=* | avg by namespace, region, account"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 80,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 80,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ],
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSDynamoDBHighMaxProvisionedTableReadCapacity" = {
      monitor_name         = "AWS DynamoDB - High Max Provisioned Table Read Capacity"
      monitor_description  = "This alert fires when we detect that the average percentage of read provisioned capacity used by the highest read provisioned table of an account for a time interval of 5 minutes is great than or equal to 80%. High values indicate requests to the database are being throttled, which could further indicate that your application may not be working as intended."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/dynamodb metric=MaxProvisionedTableReadCapacityUtilization statistic=Average account=* region=* | avg by namespace, region, account"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 80,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 80,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ],
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSDynamoDBHighAccountProvisionedWriteCapacity" = {
      monitor_name         = "AWS DynamoDB - High Account Provisioned Write Capacity"
      monitor_description  = "This alert fires when we detect that the average write capacity provisioned for an account for a time interval of 5 minutes is greater than or equal to 80%. High values indicate requests to the database are being throttled, which could further indicate that your application may not be working as intended."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "Namespace=aws/dynamodb metric=AccountProvisionedWriteCapacityUtilization statistic=Average account=* region=* | avg by namespace, region, account"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 80,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 80,
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