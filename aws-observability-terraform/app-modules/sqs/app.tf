module "sqs_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** No Metric Rules for SQS ********************** #

  # ********************** Required Fields and FERs are created at aws-observability-terraform/field.tf ********************** #

  # ********************** Apps ********************** #
  managed_apps = {
    "SQSApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/Sqs-App.json"])
      folder_id    = var.app_folder_id
    }
  }


  # ********************** Monitors ********************** #
  
  managed_monitors = {
    "AWSSNSAccessfromHighlyMaliciousSources" = {
      monitor_name         = "AWS SQS -  Messages not deleted but visible"
      monitor_description  = "This alert fires when an Application AWS - SQS has messages deleted but not visible"
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      "queries": [
      {
        "rowId": "A",
        "query": "metric=NumberOfMessagesDeleted Statistic=sum region = * account=* queuename=* namespace=aws/sqs | avg by queuename "
      },
      {
        "rowId": "B",
        "query": "metric=ApproximateNumberOfMessagesVisible Statistic=sum region = * account=* queuename=* namespace=aws/sqs | avg by queuename"
      },
      {
        "rowId": "C",
        "query": "metric=NumberOfMessagesReceived Statistic=sum region = * account=* queuename=* namespace=aws/sqs | avg by queuename"
      },
      {
        "rowId": "D",
        "query": "(#C-#A)/#B"
      }
    ],
      triggers = [
        {
          detection_method = "MetricsStaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 5,
          threshold_type   = "GreaterThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "MetricsStaticCondition",
          time_range       = "-5m",
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
    },
    "AWSSNSAccessfromHighlyMaliciousSources" = {
      monitor_name         = "AWS SQS -  Queue has stopped receiving messages"
      monitor_description  = "This alert fires when an Application AWS - SQS queue has stopped receiving messages for the last 24 hours"
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "metric=NumberOfMessagesReceived Statistic=Sum region=* account=* queuename=* namespace=aws/sqs | sum by queuename"
      }
      triggers = [
        {
          detection_method = "MetricsStaticCondition",
          time_range       = "-1d",
          trigger_type     = "Critical",
          threshold        = 0,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "MetricsStaticCondition",
          time_range       = "-1d",
          trigger_type     = "ResolvedCritical",
          threshold        = 0,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSSNSAccessfromHighlyMaliciousSources" = {
      monitor_name         = "AWS SQS -  Access from Highly Malicious Sources"
      monitor_description  = "This alert fires when an Application AWS - SQS is accessed from highly malicious IP addresses within last 5 minutes"
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "account=* \"\\\"eventsource\\\":\\\"sqs.amazonaws.com\\\"\" \n| json \"eventSource\",\"eventName\" nodrop \n| json \"userIdentity.type\", \"userIdentity.arn\", \"userIdentity.userName\", \"userIdentity.accountId\", \"awsRegion\", \"responseElements.queueUrl\", \"requestParameters.queueUrl\", \"sourceIPAddress\" as type, arn, userName, accountId, region, queueUrlRes, queueUrlReq, src_ip nodrop \n| if(eventName=\"CreateQueue\",queueUrlRes,queueUrlReq) as queueUrl\n| parse regex field= queueUrl \"(?<queueName>[^\\/]*$)\"\n| fields - queueUrlRes,queueUrlReq\n| where eventSource=\"sqs.amazonaws.com\"\n| count as ip_count by src_ip, event_name, region, accountid,user_type\n| lookup type, actor, raw, threatlevel as malicious_confidence from sumo://threat/cs on threat=src_ip\n| where type=\"ip_address\" and malicious_confidence = \"high\""
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
  }
}