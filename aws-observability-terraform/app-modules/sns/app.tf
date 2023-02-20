module "sns_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** No Metric Rules for SNS ********************** #

  # ********************** Required Fields and FERs are created at aws-observability-terraform/field.tf ********************** #

  # ********************** Apps ********************** #
  managed_apps = {
    "SNSApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/Sns-App.json"])
      folder_id    = var.app_folder_id
    }
  }


  # ********************** Monitors ********************** #
  
  managed_monitors = {
    "AWSSNSFailedNotifications" = {
      monitor_name         = "AWS SNS - Failed Notifications"
      monitor_description  = "This alert fires where there are many failed notifications (>=5) within an interval of 5 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "4m"
      queries = {
        A = "account=* region=* namespace=aws/sns TopicName=* metric=NumberOfNotificationsFailed Statistic=Sum \n| sum by account, region, TopicName"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 2,
          threshold_type   = "GreaterThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 2,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSSNSFailedEvents" = {
      monitor_name         = "AWS SNS - Failed Events"
      monitor_description  = "This alert fires when an SNS app has high number of failed events (>5) within last 5 minutes"
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {
        A = "account=* region=* namespace=aws/sns \"\\\"eventsource\\\":\\\"sns.amazonaws.com\\\"\" errorCode \n| json \"userIdentity\", \"eventSource\", \"eventName\", \"awsRegion\", \"sourceIPAddress\", \"userAgent\", \"eventType\", \"recipientAccountId\", \"requestParameters\", \"responseElements\", \"requestID\", \"errorCode\", \"errorMessage\" as userIdentity, event_source, event_name, region, src_ip, user_agent, event_type, recipient_account_id, requestParameters, responseElements, request_id, error_code, error_message nodrop \n| where event_source = \"sns.amazonaws.com\" and !isblank(error_code) \n| json field=userIdentity \"accountId\", \"type\", \"arn\", \"userName\"  as accountid, type, arn, username nodrop \n| parse field=arn \":assumed-role/*\" as user nodrop \n| parse field=arn \"arn:aws:iam::*:*\" as accountId, user nodrop \n| json field=requestParameters \"topicArn\", \"name\", \"resourceArn\", \"subscriptionArn\" as req_topic_arn, req_topic_name, resource_arn, subscription_arn  nodrop \n| json field=responseElements \"topicArn\" as res_topic_arn nodrop \n| if (isBlank(req_topic_arn), res_topic_arn, req_topic_arn) as topic_arn \n| if (isBlank(topic_arn), resource_arn, topic_arn) as topic_arn \n| parse field=topic_arn \"arn:aws:sns:*:*:*\" as region_temp, accountid_temp, topic_arn_name_temp nodrop \n| parse field=subscription_arn \"arn:aws:sns:*:*:*:*\" as region_temp, accountid_temp, topic_arn_name_temp, arn_value_temp nodrop \n| if (isBlank(req_topic_name), topic_arn_name_temp, req_topic_name) as topicname \n| if (isBlank(accountid), recipient_account_id, accountid) as accountid \n| if (isEmpty(error_code), \"Success\", \"Failure\") as event_status \n| if (isEmpty(username), user, username) as user \n| count as event_count by event_name, error_code, error_message, region, src_ip, accountid, user, type, request_id, topicname, topic_arn, user_agent"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 5,
          threshold_type   = "GreaterThan",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 5,
          threshold_type   = "LessThanOrEqual",
          occurrence_type  = "ResultCount",
          trigger_source   = "AllResults"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSSNSAccessfromHighlyMaliciousSources" = {
      monitor_name         = "AWS SNS - Access from Highly Malicious Sources"
      monitor_description  = "This alert fires when an Application AWS - SNS is accessed from highly malicious IP addresses within last 5 minutes"
      monitor_monitor_type = "Logs"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      monitor_evaluation_delay = "0m"
      queries = {   
        A = "account=* region=* namespace=aws/sns \"\\\"eventsource\\\":\\\"sns.amazonaws.com\\\"\" sourceIPAddress \n| json \"userIdentity\", \"eventSource\", \"eventName\", \"awsRegion\", \"sourceIPAddress\", \"userAgent\", \"eventType\", \"recipientAccountId\", \"requestParameters\", \"responseElements\", \"requestID\", \"errorCode\", \"errorMessage\" as userIdentity, event_source, event_name, region, src_ip, user_agent, event_type, recipient_account_id, requestParameters, responseElements, request_id, error_code, error_message nodrop \n| where event_source = \"sns.amazonaws.com\" \n| json field=userIdentity \"accountId\", \"type\", \"arn\", \"userName\"  as accountid, user_type, arn, username nodrop \n| parse field=arn \":assumed-role/*\" as user nodrop \n| parse field=arn \"arn:aws:iam::*:*\" as accountid, user nodrop \n| json field=requestParameters \"topicArn\", \"name\", \"resourceArn\", \"subscriptionArn\" as req_topic_arn, req_topic_name, resource_arn, subscription_arn  nodrop \n| json field=responseElements \"topicArn\" as res_topic_arn nodrop \n| if (isBlank(req_topic_arn), res_topic_arn, req_topic_arn) as topic_arn \n| if (isBlank(topic_arn), resource_arn, topic_arn) as topic_arn \n| parse field=topic_arn \"arn:aws:sns:*:*:*\" as region_temp, accountid_temp, topic_arn_name_temp nodrop \n| parse field=subscription_arn \"arn:aws:sns:*:*:*:*\" as region_temp, accountid_temp, topic_arn_name_temp, arn_value_temp nodrop \n| if (isBlank(req_topic_name), topic_arn_name_temp, req_topic_name) as topicname \n| if (isBlank(accountid), recipient_account_id, accountid) as accountid \n| if (isEmpty(error_code), \"Success\", \"Failure\") as event_status \n| if (isEmpty(username), user_type, username) as user_type \n| count as ip_count by src_ip, event_name, region, accountid,user_type \n| lookup type, actor, raw, threatlevel as malicious_confidence from sumo://threat/cs on threat=src_ip \n| where type=\"ip_address\" and malicious_confidence = \"high\" \n| json field=raw \"labels[*].name\" as label_name \n| replace(label_name, \"\\\\/\",\"->\") as label_name \n| replace(label_name, \"\\\"\",\" \") as label_name \n| if (isEmpty(actor), \"Unassigned\", actor) as actor \n| sum(ip_count) as threat_count by src_ip, event_name, region, accountid, malicious_confidence, actor, label_name"

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
    }
  }
  
}