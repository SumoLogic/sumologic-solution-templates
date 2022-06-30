module "sns_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** No Metric Rules for SNS ********************** #

  # ********************** Fields ********************** #
  /***
   managed_fields = {
     "TopicName" = {
       field_name = "topicname"
       data_type  = "String"
       state      = true
     }
   }
***/
  # ********************** FERs ********************** #
  managed_field_extraction_rules = {
    "SnsCloudTrailLogsFieldExtractionRule" = {
      name             = "AwsObservabilitySNSCloudTrailLogsFER"
      scope            = "account=* eventname eventsource \"sns.amazonaws.com\""
      parse_expression = <<EOT
              | json "userIdentity", "eventSource", "eventName", "awsRegion", "recipientAccountId", "requestParameters", "responseElements" as userIdentity, event_source, event_name, region, recipient_account_id, requestParameters, responseElements nodrop
              | where event_source = "sns.amazonaws.com"
              | json field=userIdentity "accountId", "type", "arn", "userName"  as accountid, type, arn, username nodrop
              | parse field=arn ":assumed-role/*" as user nodrop 
              | parse field=arn "arn:aws:iam::*:*" as accountid, user nodrop
              | json field=requestParameters "topicArn", "name", "resourceArn", "subscriptionArn" as req_topic_arn, req_topic_name, resource_arn, subscription_arn  nodrop 
              | json field=responseElements "topicArn" as res_topic_arn nodrop
              | if (isBlank(req_topic_arn), res_topic_arn, req_topic_arn) as topic_arn
              | if (isBlank(topic_arn), resource_arn, topic_arn) as topic_arn
              | parse field=topic_arn "arn:aws:sns:*:*:*" as region_temp, accountid_temp, topic_arn_name_temp nodrop
              | parse field=subscription_arn "arn:aws:sns:*:*:*:*" as region_temp, accountid_temp, topic_arn_name_temp, arn_value_temp nodrop
              | if (isBlank(req_topic_name), topic_arn_name_temp, req_topic_name) as topicname
              | if (isBlank(accountid), recipient_account_id, accountid) as accountid
              | "aws/sns" as namespace
              | fields region, namespace, topicname, accountid
      EOT
      enabled          = true
    }
  }

  # ********************** Apps ********************** #
  managed_apps = {
    "SNSApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/Sns-App.json"])
      folder_id    = var.app_folder_id
    }
  }


  # ********************** Monitors ********************** #
  /***
  managed_monitors = {
    "AWSAPIGatewayHigh5XXErrors" = {
      monitor_name         = "AWS API Gateway - High 5XX Errors"
      monitor_description  = "This alert fires where there are too many HTTP requests (>5%) with a response status of 5xx within an interval of 5 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/apigateway metric=5xxError Statistic=Sum account=* region=* apiname=* | sum by apiname, account, region, namespace"
        B = "Namespace=aws/apigateway metric=count Statistic=Sum account=* region=* apiname=* | sum by apiname, account, region, namespace"
        C = "#A * 100 / #B along account, region, namespace"
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
    "AWSAPIGatewayHigh4XXErrors" = {
      monitor_name         = "AWS API Gateway - High 4XX Errors"
      monitor_description  = "This alert fires where there are too many HTTP requests (>5%) with a response status of 4xx within an interval of 5 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/apigateway metric=4xxError Statistic=Sum account=* region=* apiname=* | sum by apiname, account, region, namespace"
        B = "Namespace=aws/apigateway metric=count Statistic=Sum account=* region=* apiname=* | sum by apiname, account, region, namespace"
        C = "#A * 100 / #B along apiname, account, region, namespace"
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
    "AWSAPIGatewayHighIntegrationLatency" = {
      monitor_name         = "AWS API Gateway - High Integration Latency"
      monitor_description  = "This alert fires when we detect that the average integration latency for a given API Gateway is greater than or equal to one second for 5 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/apigateway metric=IntegrationLatency statistic=Average account=* region=* apiname=* | avg by apiname, namespace, region, account"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 1000,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 1000,
          threshold_type   = "LessThan",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        }
      ]
      group_notifications      = var.group_notifications
      connection_notifications = var.connection_notifications
      email_notifications      = var.email_notifications
    },
    "AWSAPIGatewayHighLatency" = {
      monitor_name         = "AWS API Gateway - High Latency"
      monitor_description  = "This alert fires when we detect that the average latency for a given API Gateway is greater than or equal to one second for 5 minutes."
      monitor_monitor_type = "Metrics"
      monitor_parent_id    = var.monitor_folder_id
      monitor_is_disabled  = var.monitors_disabled
      queries = {
        A = "Namespace=aws/apigateway metric=Latency statistic=Average account=* region=* apiname=* | avg by apiname, namespace, region, account"
      }
      triggers = [
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "Critical",
          threshold        = 1000,
          threshold_type   = "GreaterThanOrEqual",
          occurrence_type  = "Always",
          trigger_source   = "AnyTimeSeries"
        },
        {
          detection_method = "StaticCondition",
          time_range       = "-5m",
          trigger_type     = "ResolvedCritical",
          threshold        = 1000,
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
  ***/
}