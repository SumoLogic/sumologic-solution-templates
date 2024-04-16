output "apps_folder_id" {
  value       = module.sumo-module.sumologic_apps_folder.id
  description = "This output contains sumologic apps folder."
}

output "alb_apps_folder_id" {
  value       = module.sumo-module.sumologic_content_alb.ALBApp.id
  description = "This output contains sumologic ALB apps folder."
}

output "apigateway_apps_folder_id" {
  value       = module.sumo-module.sumologic_content_apigateway.APIGatewayApp.id
  description = "This output contains sumologic API Gateway apps folder."
}

output "dynamodb_apps_folder_id" {
  value       = module.sumo-module.sumologic_content_dynamodb.DynamoDBApp.id
  description = "This output contains sumologic DynamoDB apps folder."
}

output "ec2metrics_apps_folder_id" {
  value       = module.sumo-module.sumologic_content_ec2metrics.EC2MetricsApp.id
  description = "This output contains sumologic EC2 host metrics apps folder."
}

output "ec2CWmetrics_apps_folder_id" {
  value       = module.sumo-module.sumologic_content_ec2metrics.EC2CWMetricsApp.id
  description = "This output contains sumologic EC2 CW metrics apps folder."
}

output "ecs_apps_folder_id" {
  value       = module.sumo-module.sumologic_content_ecs.ecsApp.id
  description = "This output contains sumologic ECS apps folder."
}

output "elasticache_apps_folder_id" {
  value       = module.sumo-module.sumologic_content_elasticache.ElastiCacheApp.id
  description = "This output contains sumologic ElastiCacheApp apps folder."
}

output "clb_apps_folder_id" {
  value       = module.sumo-module.sumologic_content_elb.ClassicLBApp.id
  description = "This output contains sumologic CLB apps folder."
}

output "lambda_apps_folder_id" {
  value       = module.sumo-module.sumologic_content_lambda.LambdaApp.id
  description = "This output contains sumologic Lambda apps folder."
}

output "nlb_apps_folder_id" {
  value       = module.sumo-module.sumologic_content_nlb.NlbApp.id
  description = "This output contains sumologic NLB apps folder."
}

output "overview_apps_folder_id" {
  value       = module.sumo-module.sumologic_content_overview.OverviewApp.id
  description = "This output contains sumologic Overview apps folder."
}

output "rds_apps_folder_id" {
  value       = module.sumo-module.sumologic_content_rds.RdsApp.id
  description = "This output contains sumologic RDS apps folder."
}

output "sns_apps_folder_id" {
  value       = module.sumo-module.sumologic_content_sns.SNSApp.id
  description = "This output contains sumologic SNS apps folder."
}

output "sqs_apps_folder_id" {
  value       = module.sumo-module.sumologic_content_sqs.SQSApp.id
  description = "This output contains sumologic SQS apps folder."
}

output "monitors_folder_id" {
  value       = module.sumo-module.sumologic_monitors_folder.id
  description = "This output contains sumologic monitors folder."
}

output "hierarchy_id" {
  value       = module.sumo-module.sumologic_hierarchy.id
  description = "This output contains sumologic hierarchy id."
}

# API gateway FER id
output "sumologic_field_extraction_rule_apigateway" {
  value       = sumologic_field_extraction_rule.AwsObservabilityApiGatewayCloudTrailLogsFER.id
  description = "This output contains sumologic API gateway field extraction rule id."
}

# API gateway FER id
output "sumologic_field_extraction_rule_apigateway_access_logs" {
  value       = sumologic_field_extraction_rule.AwsObservabilityApiGatewayAccessLogsFER.id
  description = "This output contains sumologic API gateway Access Logs field extraction rule id."
}

# ALB FER id
output "sumologic_field_extraction_rule_alb" {
  value       = sumologic_field_extraction_rule.AwsObservabilityAlbAccessLogsFER.id
  description = "This output contains sumologic ALB field extraction rule id."
}

# CLB FER id
output "sumologic_field_extraction_rule_elb" {
  value       = sumologic_field_extraction_rule.AwsObservabilityElbAccessLogsFER.id
  description = "This output contains sumologic CLB field extraction rule id."
}

# DynamoDB FER id
output "sumologic_field_extraction_rule_dynamodb" {
  value       = sumologic_field_extraction_rule.AwsObservabilityDynamoDBCloudTrailLogsFER.id
  description = "This output contains sumologic dynamoDB field extraction rule id."
}

# Elasticache FER id
output "sumologic_field_extraction_rule_elasticache" {
  value       = sumologic_field_extraction_rule.AwsObservabilityElastiCacheCloudTrailLogsFER.id
  description = "This output contains sumologic Elasticache field extraction rule id."
}

# ECS FER id
output "sumologic_field_extraction_rule_ecs" {
  value       = sumologic_field_extraction_rule.AwsObservabilityECSCloudTrailLogsFER.id
  description = "This output contains sumologic ECS field extraction rule id."
}

# EC2 FER id
output "sumologic_field_extraction_rule_ec2metrics" {
  value       = sumologic_field_extraction_rule.AwsObservabilityEC2CloudTrailLogsFER.id
  description = "This output contains sumologic EC2 field extraction rule id."
}

# Lambda CloudTrail FER id
output "sumologic_field_extraction_rule_lambda" {
  value       = sumologic_field_extraction_rule.AwsObservabilityFieldExtractionRule.id
  description = "This output contains sumologic Lambda cloudtrail field extraction rule id."
}

# Lambda CloudWatch FER id
output "sumologic_field_extraction_rule_lambda_cw" {
  value       = sumologic_field_extraction_rule.AwsObservabilityLambdaCloudWatchLogsFER.id
  description = "This output contains sumologic Lambda cloudwatch field extraction rule id."
}

# RDS FER id
output "sumologic_field_extraction_rule_rds" {
  value       = sumologic_field_extraction_rule.AwsObservabilityRdsCloudTrailLogsFER.id
  description = "This output contains sumologic RDS field extraction rule id."
}

# CloudWatch generic FER id
output "sumologic_field_extraction_rule_cw" {
  value       = sumologic_field_extraction_rule.AwsObservabilityGenericCloudWatchLogsFER.id
  description = "This output contains sumologic CloudWatch logs generic field extraction rule id."
}

# SNS FER id
output "sumologic_field_extraction_rule_sns" {
  value       = sumologic_field_extraction_rule.AwsObservabilitySNSCloudTrailLogsFER.id
  description = "This output contains sumologic SNS field extraction rule id."
}

# SQS FER id
output "sumologic_field_extraction_rule_sqs" {
  value       = sumologic_field_extraction_rule.AwsObservabilitySQSCloudTrailLogsFER.id
  description = "This output contains sumologic SQS field extraction rule id."
}

# NLB Metric rule
output "sumologic_metric_rule_nlb" {
  value       = module.sumo-module.sumologic_metric_rules_nlb.NLBMetricRule.triggers.name
  description = "This output contains sumologic NLB metric rule name."
}

# API Gateway Metric rule
output "sumologic_metric_rule_api_gw" {
  # value       = module.sumo-module.sumologic_metric_rules_api_gw.ApiNameMetricRule.triggers.name
  value       = module.sumo-module.sumologic_metric_rules_api_gw.ApiNameMetricRule.triggers.name
  description = "This output contains sumologic API Gateway metric rule name."
}

# RDS Cluster Metric rule
output "sumologic_metric_rule_rds_cluster" {
  value       = module.sumo-module.sumologic_metric_rules_rds.ClusterMetricRule.triggers.name
  description = "This output contains sumologic RDS cluster metric rule name."
}

# RDS Instance Metric rule
output "sumologic_metric_rule_rds_instance" {
  value       = module.sumo-module.sumologic_metric_rules_rds.InstanceMetricRule.triggers.name
  description = "This output contains sumologic RDS instance metric rule name."
}

output "sumologic_field_account" {
  value       = sumologic_field.account.id
  description = "This output contains sumologic Account field id."
}

output "sumologic_field_region" {
  value       = sumologic_field.region.id
  description = "This output contains sumologic Region field id."
}

output "sumologic_field_accountid" {
  value       = sumologic_field.accountid.id
  description = "This output contains sumologic accountid field id."
}

output "sumologic_field_namespace" {
  value       = sumologic_field.namespace.id
  description = "This output contains sumologic namespace field id."
}

output "sumologic_field_loadbalancer" {
  value       = sumologic_field.loadbalancer.id
  description = "This output contains sumologic loadbalancer field id."
}

output "sumologic_field_loadbalancername" {
  value       = sumologic_field.loadbalancername.id
  description = "This output contains sumologic loadbalancername field id."
}

output "sumologic_field_apiname" {
  value       = sumologic_field.apiname.id
  description = "This output contains sumologic apiname field id."
}

output "sumologic_field_tablename" {
  value       = sumologic_field.tablename.id
  description = "This output contains sumologic tablename field id."
}

output "sumologic_field_instanceid" {
  value       = sumologic_field.instanceid.id
  description = "This output contains sumologic instanceid field id."
}

output "sumologic_field_clustername" {
  value       = sumologic_field.clustername.id
  description = "This output contains sumologic clustername field id."
}

output "sumologic_field_cacheclusterid" {
  value       = sumologic_field.cacheclusterid.id
  description = "This output contains sumologic cacheclusterid field id."
}

output "sumologic_field_functionname" {
  value       = sumologic_field.functionname.id
  description = "This output contains sumologic functionname field id."
}

output "sumologic_field_networkloadbalancer" {
  value       = sumologic_field.networkloadbalancer.id
  description = "This output contains sumologic networkloadbalancer field id."
}

output "sumologic_field_dbidentifier" {
  value       = sumologic_field.dbidentifier.id
  description = "This output contains sumologic dbidentifier field id."
}

output "sumologic_field_topicname" {
  value       = sumologic_field.topicname.id
  description = "This output contains sumologic topicname field id."
}

output "sumologic_field_queuename" {
  value       = sumologic_field.queuename.id
  description = "This output contains sumologic queuename field id."
}

output "sumologic_field_dbclusteridentifier" {
  value       = sumologic_field.dbclusteridentifier.id
  description = "This output contains sumologic dbclusteridentifier field id."
}

output "sumologic_field_dbinstanceidentifier" {
  value       = sumologic_field.dbinstanceidentifier.id
  description = "This output contains sumologic dbinstanceidentifier field id."
}

output "sumologic_field_apiid" {
  value       = sumologic_field.apiid.id
  description = "This output contains sumologic apiid field id."
}