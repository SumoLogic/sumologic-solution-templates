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
    "AWSSQSMessageProcessingNotFastEnough" = {
      monitor_name         = "AWS SQS -  Message processing not fast enough"
      monitor_description  = "This alert fires when we detect message processing is not fast enough. That is, the average approximate age of the oldest non-deleted message in the queue is more than 5 seconds for an interval of 5 minutes"
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      "queries": [
      {
        "rowId": "A",
        "query": "metric=ApproximateAgeOfOldestMessage Statistic=avg region=* account=* queuename=* namespace=aws/sqs | avg by account,region,namespace,queuename "
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
    "AWSSQSMessagesNotProcessed" = {
      monitor_name         = "AWS SQS -  Messages not processed"
      monitor_description  = "This alert fires when we detect messages that have been received by a consumer, but have not been processed (deleted/failed). That is, the average number of messages that are in flight are >=20 for an interval of 5 minutes"
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        "rowId": "A",
        "query": "metric=ApproximateNumberOfMessagesNotVisible Statistic=avg region = * account=* queuename=* namespace=aws/sqs | avg by account, region, namespace, queuename "
      }
      triggers = [
        {
          detection_method = "MetricsStaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 20,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "MetricsStaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 20,
          threshold_type   = "LessThan",
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
     "AWSSQSQueueHasStoppedReceivingMessages" = {
      monitor_name         = "AWS SQS - Queue has stopped receiving messages"
      monitor_description  = "This alert fires when we detect that the queue has stopped receiving messages. That is, the average number of messages received in the queue <1 for an interval of 30 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      "queries": [
      {
        "rowId": "A",
        "query": "metric=NumberOfMessagesReceived Statistic=avg region=* account=* queuename=* namespace=aws/sqs | avg by account, region, namespace, queuename "
      }
    ],
      triggers = [
        {
          detection_method = "MetricsStaticCondition",
          time_range       = "-30m",
          trigger_type     = "Critical",
          threshold        = 1,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "MetricsStaticCondition",
          time_range       = "-30m",
          trigger_type     = "ResolvedCritical",
          threshold        = 1,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
  }
}