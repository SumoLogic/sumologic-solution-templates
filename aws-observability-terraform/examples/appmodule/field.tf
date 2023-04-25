# Wait resource
resource "time_sleep" "wait_for_10_seconds" {
  create_duration = "10s"
}

# common fields
resource "sumologic_field" "account" {
    data_type  = "String"
    field_name = "account"
    state      = "Enabled"
}

# common fields
resource "sumologic_field" "region" {
    data_type  = "String"
    field_name = "region"
    state      = "Enabled"
}

# common fields
resource "sumologic_field" "accountid" {
    data_type  = "String"
    field_name = "accountid"
    state      = "Enabled"
}

# common fields
resource "sumologic_field" "namespace" {
    data_type  = "String"
    field_name = "namespace"
    state      = "Enabled"
}

# Used in ALB
resource "sumologic_field" "loadbalancer" {
    data_type  = "String"
    field_name = "loadbalancer"
    state      = "Enabled"
}

# Used in Classic LB
resource "sumologic_field" "loadbalancername" {
    data_type  = "String"
    field_name = "loadbalancername"
    state      = "Enabled"
}

# Used in API gateway
resource "sumologic_field" "apiname" {
    data_type  = "String"
    field_name = "apiname"
    state      = "Enabled"
}

# Used in DynamoDB
resource "sumologic_field" "tablename" {
    data_type  = "String"
    field_name = "tablename"
    state      = "Enabled"
}

# Used in EC2
resource "sumologic_field" "instanceid" {
    data_type  = "String"
    field_name = "instanceid"
    state      = "Enabled"
}

# Used in ECS
resource "sumologic_field" "clustername" {
    data_type  = "String"
    field_name = "clustername"
    state      = "Enabled"
}

# Used in Elasticache
resource "sumologic_field" "cacheclusterid" {
    data_type  = "String"
    field_name = "cacheclusterid"
    state      = "Enabled"
}

# Used in Lambda
resource "sumologic_field" "functionname" {
    data_type  = "String"
    field_name = "functionname"
    state      = "Enabled"
}

# Used in NLB
resource "sumologic_field" "networkloadbalancer" {
    data_type  = "String"
    field_name = "networkloadbalancer"
    state      = "Enabled"
}

# Used in RDS
resource "sumologic_field" "dbidentifier" {
    data_type  = "String"
    field_name = "dbidentifier"
    state      = "Enabled"
}
resource "sumologic_field" "dbclusteridentifier" {
    data_type  = "String"
    field_name = "dbclusteridentifier"
    state      = "Enabled"
}
resource "sumologic_field" "dbinstanceidentifier" {
    data_type  = "String"
    field_name = "dbinstanceidentifier"
    state      = "Enabled"
}

# Used in SNS
resource "sumologic_field" "topicname" {
    data_type  = "String"
    field_name = "topicname"
    state      = "Enabled"
}

resource "sumologic_field" "queuename" {
    data_type  = "String"
    field_name = "queuename"
    state      = "Enabled"
}

# ALB access log FER
resource "sumologic_field_extraction_rule" "AwsObservabilityAlbAccessLogsFER" {
      depends_on = [time_sleep.wait_for_10_seconds]
      name = "AwsObservabilityAlbAccessLogsFER"
      scope = "account=* region=* (http or https or h2 or grpcs or ws or wss)"
      parse_expression = <<EOT
              | parse "* * * * * * * * * * * * \"*\" \"*\" * * * \"*\"" as Type, DateTime, loadbalancer, Client, Target, RequestProcessingTime, TargetProcessingTime, ResponseProcessingTime, ElbStatusCode, TargetStatusCode, ReceivedBytes, SentBytes, Request, UserAgent, SslCipher, SslProtocol, TargetGroupArn, TraceId
              | where Type in ("http", "https", "h2", "grpcs", "ws", "wss")
              | where !isBlank(loadbalancer)
              | "aws/applicationelb" as namespace
              | tolowercase(loadbalancer) as loadbalancer | fields loadbalancer, namespace
      EOT
      enabled = true
}

# API Gateway CloudTrail FER
resource "sumologic_field_extraction_rule" "AwsObservabilityApiGatewayCloudTrailLogsFER" {
      depends_on = [time_sleep.wait_for_10_seconds]
      name = "AwsObservabilityApiGatewayCloudTrailLogsFER"
      scope = "account=* eventname eventsource \"apigateway.amazonaws.com\""
      parse_expression = <<EOT
              | json "eventSource", "awsRegion", "responseElements", "recipientAccountId" as eventSource, region, responseElements, accountid nodrop
              | where eventSource = "apigateway.amazonaws.com"
              | "aws/apigateway" as namespace
              | json field=responseElements "name" as ApiName nodrop
              | tolowercase(ApiName) as apiname
              | fields region, namespace, apiname, accountid
      EOT
      enabled = true
}

# DynamoDB CloudTrail FER
resource "sumologic_field_extraction_rule" "AwsObservabilityDynamoDBCloudTrailLogsFER" {
      depends_on = [time_sleep.wait_for_10_seconds]
      name = "AwsObservabilityDynamoDBCloudTrailLogsFER"
      scope = "account=* eventname eventsource \"dynamodb.amazonaws.com\""
      parse_expression = <<EOT
              | json "eventSource", "awsRegion", "requestParameters.tableName", "recipientAccountId" as eventSource, region, tablename, accountid nodrop
              | where eventSource = "dynamodb.amazonaws.com"
              | "aws/dynamodb" as namespace
              | tolowercase(tablename) as tablename
              | fields region, namespace, tablename, accountid
      EOT
      enabled = true
}

# EC2 CloudTrail FER
resource "sumologic_field_extraction_rule" "AwsObservabilityEC2CloudTrailLogsFER" {
      depends_on = [time_sleep.wait_for_10_seconds]
      name = "AwsObservabilityEC2CloudTrailLogsFER"
      scope = "account=* eventname eventsource \"ec2.amazonaws.com\""
      parse_expression = <<EOT
              | json "eventSource", "awsRegion", "requestParameters", "responseElements", "recipientAccountId" as eventSource, region, requestParameters, responseElements, accountid nodrop
              | where eventSource = "ec2.amazonaws.com"
              | "aws/ec2" as namespace
              | json field=requestParameters "instanceType", "instancesSet", "instanceId", "DescribeInstanceCreditSpecificationsRequest.InstanceId.content" as req_instancetype, req_instancesSet, req_instanceid_1, req_instanceid_2 nodrop
              | json field=req_instancesSet "item", "items" as req_instancesSet_item, req_instancesSet_items nodrop
              | parse regex field=req_instancesSet_item "\"instanceId\":\s*\"(?<req_instanceid_3>.*?)\"" nodrop
              | parse regex field=req_instancesSet_items "\"instanceId\":\s*\"(?<req_instanceid_4>.*?)\"" nodrop
              | json field=responseElements "instancesSet.items" as res_responseElements_items nodrop
              | parse regex field=res_responseElements_items "\"instanceType\":\s*\"(?<res_instanceType>.*?)\"" nodrop
              | parse regex field=res_responseElements_items "\"instanceId\":\s*\"(?<res_instanceid>.*?)\"" nodrop
              | if (!isBlank(req_instanceid_1), req_instanceid_1,  if (!isBlank(req_instanceid_2), req_instanceid_2, if (!isBlank(req_instanceid_3), req_instanceid_3, if (!isBlank(req_instanceid_4), req_instanceid_4, "")))) as req_instanceid
              | if (!isBlank(req_instanceid), req_instanceid, res_instanceid) as instanceid
              | if (!isBlank(req_instancetype), req_instancetype, res_instancetype) as instanceType 
              | tolowercase(instanceid) as instanceid
              | fields region, namespace, accountid, instanceid
      EOT
      enabled = true
}

# ECS CloudTrail FER
resource "sumologic_field_extraction_rule" "AwsObservabilityECSCloudTrailLogsFER" {
      depends_on = [time_sleep.wait_for_10_seconds]
      name = "AwsObservabilityECSCloudTrailLogsFER"
      scope = "account=* eventname eventsource \"ecs.amazonaws.com\""
      parse_expression = <<EOT
              | json "eventSource", "awsRegion", "requestParameters", "recipientAccountId" as eventSource, region, requestParameters, accountid nodrop
              | json field=requestParameters "cluster" as clustername nodrop
              | where eventSource = "ecs.amazonaws.com"
              | "aws/ecs" as namespace
              | tolowercase(clustername) as clustername
              | fields region, namespace, clustername, accountid
      EOT
      enabled = true
}

# ElasticCache CloudTrail FER
resource "sumologic_field_extraction_rule" "AwsObservabilityElastiCacheCloudTrailLogsFER" {
      depends_on = [time_sleep.wait_for_10_seconds]
      name = "AwsObservabilityElastiCacheCloudTrailLogsFER"
      scope = "account=* eventname eventsource \"elasticache.amazonaws.com\""
      parse_expression = <<EOT
              | json "eventSource", "awsRegion", "requestParameters.cacheClusterId", "responseElements.cacheClusterId", "recipientAccountId" as eventSource, region, req_cacheClusterId, res_cacheClusterId, accountid nodrop
              | where eventSource = "elasticache.amazonaws.com"
              | if (!isEmpty(req_cacheClusterId), req_cacheClusterId, res_cacheClusterId) as cacheclusterid
              | "aws/elasticache" as namespace
              | tolowercase(cacheclusterid) as cacheclusterid
              | fields region, namespace, cacheclusterid, accountid
      EOT
      enabled = true
}

# CLB Access Logs FER
resource "sumologic_field_extraction_rule" "AwsObservabilityElbAccessLogsFER" {
      depends_on = [time_sleep.wait_for_10_seconds]
      name = "AwsObservabilityElbAccessLogsFER"
      scope = "account=* region=*"
      parse_expression = <<EOT
        | parse "* * * * * * * * * * * \"*\" \"*\" * *" as datetime, loadbalancername, client, backend, request_processing_time, backend_processing_time, response_processing_time, elb_status_code, backend_status_code, received_bytes, sent_bytes, request, user_agent, ssl_cipher, ssl_protocol
        | parse regex field=datetime "(?<datetimevalue>\d{0,4}-\d{0,2}-\d{0,2}T\d{0,2}:\d{0,2}:\d{0,2}\.\d+Z)" 
        | where !isBlank(loadbalancername) and !isBlank(datetimevalue)
        | "aws/elb" as namespace
        | tolowercase(loadbalancername) as loadbalancername | fields loadbalancername, namespace
      EOT
      enabled = true
}

# Lambda CloudTrail FER
resource "sumologic_field_extraction_rule" "AwsObservabilityFieldExtractionRule" {
      depends_on = [time_sleep.wait_for_10_seconds]
      name = "AwsObservabilityFieldExtractionRule"
      scope = "account=* eventname eventsource \"lambda.amazonaws.com\""
      parse_expression = <<EOT
              | json "eventSource", "awsRegion", "requestParameters", "recipientAccountId" as eventSource, region, requestParameters, accountid nodrop
              | where eventSource = "lambda.amazonaws.com"
              | json field=requestParameters "functionName", "resource" as functionname, resource nodrop
              | parse regex field=functionname "\w+:\w+:\S+:[\w-]+:\S+:\S+:(?<functionname>[\S]+)$" nodrop
              | parse field=resource "arn:aws:lambda:*:function:*" as f1, functionname2 nodrop
              | if (isEmpty(functionname), functionname2, functionname) as functionname
              | "aws/lambda" as namespace
              | tolowercase(functionname) as functionname
              | fields region, namespace, functionname, accountid
      EOT
      enabled = true
}

# Lambda CloudWatch FER
resource "sumologic_field_extraction_rule" "AwsObservabilityLambdaCloudWatchLogsFER" {
      depends_on = [time_sleep.wait_for_10_seconds]
      name = "AwsObservabilityLambdaCloudWatchLogsFER"
      scope = "account=* region=* _sourceHost=/aws/lambda/*"
      parse_expression = <<EOT
              | parse field=_sourceHost "/aws/lambda/*" as functionname
              | tolowercase(functionname) as functionname
              | "aws/lambda" as namespace
              | fields functionname, namespace
      EOT
      enabled = true
}

# Generic CloudWatch FER
resource "sumologic_field_extraction_rule" "AwsObservabilityGenericCloudWatchLogsFER" {
      depends_on = [time_sleep.wait_for_10_seconds]
      name = "AwsObservabilityGenericCloudWatchLogsFER"
      scope = "account=* region=* _sourceHost=/aws/*"
      parse_expression = <<EOT
              | "unknown" as namespace
              | if (_sourceHost matches "/aws/lambda/*", "aws/lambda", namespace) as namespace
              | if (_sourceHost matches "/aws/rds/*", "aws/rds", namespace) as namespace
              | if (_sourceHost matches "/aws/ecs/containerinsights/*", "ecs/containerinsights", namespace) as namespace
              | if (_sourceHost matches "/aws/kinesisfirehose/*", "aws/firehose", namespace) as namespace
              | fields namespace
      EOT
      enabled = true
}

# RDS CloudTrail FER
resource "sumologic_field_extraction_rule" "AwsObservabilityRdsCloudTrailLogsFER" {
      depends_on = [time_sleep.wait_for_10_seconds]
      name = "AwsObservabilityRdsCloudTrailLogsFER"
      scope = "account=* eventname eventsource \"rds.amazonaws.com\""
      parse_expression = <<EOT
              | json "eventSource", "awsRegion", "requestParameters", "responseElements", "recipientAccountId" as eventSource, region, requestParameters, responseElements, accountid nodrop
              | where eventSource = "rds.amazonaws.com"
              | "aws/rds" as namespace
              | json field=requestParameters "dBInstanceIdentifier", "resourceName", "dBClusterIdentifier" as dBInstanceIdentifier1, resourceName, dBClusterIdentifier1 nodrop
              | json field=responseElements "dBInstanceIdentifier" as dBInstanceIdentifier3 nodrop | json field=responseElements "dBClusterIdentifier" as dBClusterIdentifier3 nodrop
              | parse field=resourceName "arn:aws:rds:*:db:*" as f1, dBInstanceIdentifier2 nodrop | parse field=resourceName "arn:aws:rds:*:cluster:*" as f1, dBClusterIdentifier2 nodrop
              | if (resourceName matches "arn:aws:rds:*:db:*", dBInstanceIdentifier2, if (!isEmpty(dBInstanceIdentifier1), dBInstanceIdentifier1, dBInstanceIdentifier3) ) as dBInstanceIdentifier
              | if (resourceName matches "arn:aws:rds:*:cluster:*", dBClusterIdentifier2, if (!isEmpty(dBClusterIdentifier1), dBClusterIdentifier1, dBClusterIdentifier3) ) as dBClusterIdentifier
              | if (isEmpty(dBInstanceIdentifier), dBClusterIdentifier, dBInstanceIdentifier) as dbidentifier
              | tolowercase(dbidentifier) as dbidentifier
              | fields region, namespace, dBInstanceIdentifier, dBClusterIdentifier, dbidentifier, accountid
      EOT
      enabled = true
}

# SNS CloudTrail FER
resource "sumologic_field_extraction_rule" "AwsObservabilitySNSCloudTrailLogsFER" {
      depends_on = [time_sleep.wait_for_10_seconds]
      name = "AwsObservabilitySNSCloudTrailLogsFER"
      scope = "account=* eventname eventsource \"sns.amazonaws.com\""
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
      enabled = true
}

# SQS CloudTrail FER
resource "sumologic_field_extraction_rule" "AwsObservabilitySQSCloudTrailLogsFER" {
      depends_on = [time_sleep.wait_for_10_seconds]
      name = "AwsObservabilitySQSCloudTrailLogsFER"
      scope = "account=* eventsource sqs.amazonaws.com"
      parse_expression = <<EOT
              | json "userIdentity", "eventSource", "eventName", "awsRegion", "recipientAccountId", "requestParameters", "responseElements", "sourceIPAddress" as userIdentity, event_source, event_name, region, recipient_account_id, requestParameters, responseElements, src_ip  nodrop
              | json field=userIdentity "accountId", "type", "arn", "userName" as accountid, type, arn, username nodrop
              | json field=requestParameters "queueUrl" as queueUrlReq nodrop
              | json field=responseElements "queueUrl" as queueUrlRes nodrop
              | where event_source="sqs.amazonaws.com"
              | if(event_name="CreateQueue", queueUrlRes, queueUrlReq) as queueUrl
              | parse regex field=queueUrl "(?<queueName>[^\/]*$)"
              | if (isBlank(recipient_account_id), accountid, recipient_account_id) as accountid
              | toLowerCase(queuename) as queuename
              | "aws/sqs" as namespace
              | fields region, namespace, queuename, accountid
      EOT
      enabled = true
}