module "sqs_module" {
  source = "git::https://github.com/SumoLogic/terraform-sumologic-sumo-logic-integrations.git//sumologic?ref=sumo_246624"
  #source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

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
      monitor_evaluation_delay = "4m"
      queries =  {
        A =  "metric=ApproximateAgeOfOldestMessage Statistic=avg region=* account=* queuename=* namespace=aws/sqs | avg by account,region,namespace,queuename "
      },
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
    "AWSSQSMessagesNotProcessed" = {
      monitor_name         = "AWS SQS -  Messages not processed"
      monitor_description  = "This alert fires when we detect messages that have been received by a consumer, but have not been processed (deleted/failed). That is, the average number of messages that are in flight are >=20 for an interval of 5 minutes"
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A =  "metric=ApproximateNumberOfMessagesNotVisible Statistic=avg region = * account=* queuename=* namespace=aws/sqs | avg by account, region, namespace, queuename "
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
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* namespace=\"aws/sqs\" eventname eventsource \"sqs.amazonaws.com\" sourceIPAddress\n| json \"userIdentity\", \"eventSource\", \"eventName\", \"awsRegion\", \"recipientAccountId\", \"requestParameters\", \"responseElements\", \"sourceIPAddress\",\"errorCode\", \"errorMessage\" as userIdentity, event_source, event_name, region, recipient_account_id, requestParameters, responseElements, src_ip, error_code, error_message nodrop\n| json field=userIdentity \"accountId\", \"type\", \"arn\", \"userName\" as accountid, type, arn, username nodrop\n| json field=requestParameters \"queueUrl\" as queueUrlReq nodrop \n| json field=responseElements \"queueUrl\" as queueUrlRes nodrop\n| where event_source=\"sqs.amazonaws.com\" and !(src_ip matches \"*.amazonaws.com\")\n| if(event_name=\"CreateQueue\", queueUrlRes, queueUrlReq) as queueUrl \n| parse regex field=queueUrl \"(?<queueName>[^\\/]*$)\"\n| if (isBlank(recipient_account_id), accountid, recipient_account_id) as accountid\n| if (isEmpty(error_code), \"Success\", \"Failure\") as event_status \n| count as ip_count by src_ip\n| lookup type, actor, raw, threatlevel as malicious_confidence from sumo://threat/cs on threat=src_ip\n| json field=raw \"labels[*].name\" as label_name \n| replace(label_name, \"\\\\/\",\"->\") as label_name\n| replace(label_name, \"\\\"\",\" \") as label_name\n| if (isEmpty(actor), \"Unassigned\", actor) as actor\n| where type=\"ip_address\" and malicious_confidence = \"high\"\n| sort by ip_count, src_ip\n| fields src_ip, malicious_confidence, actor, label_name"
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
      monitor_description  = "This alert fires when we detect that the queue has stopped receiving messages. That is, the average number of messages received in the queue <1 for an interval of 30 minutes"
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "metric=NumberOfMessagesReceived Statistic=avg region=* account=* queuename=* namespace=aws/sqs | avg by account, region, namespace, queuename "
      },
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