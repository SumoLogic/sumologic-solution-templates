output "collection_folder_id" {
  value       = module.collection-module
  description = "This output contains sumologic Collections output."
  sensitive = true
}

output "sumologic_collector" {
  value       = "${(var.executeTest1 || var.executeTest3) ? module.collection-module.sumologic_collector.collector.id : ""}"
  description = "This output contains sumologic collector id."
}

output "aws_s3" {
  value       = "${var.executeTest1 ? module.collection-module.aws_s3_bucket.s3_bucket.id:""}"
  description = "This output contains AWS S3 bucket name."
}

output "aws_sns_topic" {
  value       = "${var.executeTest1 ? module.collection-module.aws_sns_topic.sns_topic.arn:""}"
  description = "This output contains AWS SNS topic arn."
}

output "aws_iam_role" {
  value       = "${var.executeTest2 == false ? module.collection-module.aws_iam_role.sumologic_iam_role.name:""}"
  description = "This output contains IAM role arn."
}

output "sumologic_cloudtrail_source" {
  value       = "${var.collect_cloudtrail == true ? module.collection-module.cloudtrail_source.id : ""}"
  description = "This output contains sumologic CloudTrail source id."
}

# Comment in case of test 4
# output "aws_cloudtrail_name" {
#   value       = "${var.collect_cloudtrail == true ? module.collection-module.aws_cloudtrail.cloudtrail.name : ""}"
#   description = "This output contains CloudTrail Name."
# }

output "cloudtrail_sns_topic" {
  value       = "${var.executeTest4 ? module.collection-module.cloudtrail_sns_topic.sns_topic.arn:""}"
  description = "This output contains AWS SNS topic arn."
}

output "cloudtrail_sns_sub" {
  value       = "${var.collect_cloudtrail == true ? module.collection-module.cloudtrail_sns_subscription.arn : ""}"
  description = "This output contains Cloudtrail AWS SNS subscription arn."
}

output "sumologic_kinesis_firehose_for_metrics_source" {
  value       = "${var.collect_metric_cloudwatch == "Kinesis Firehose Metrics Source" ? module.collection-module.kinesis_firehose_for_metrics_source.id : ""}"
  description = "This output contains sumologic kinesis firehose for metrics source id."
}

output "kf_metrics_stream" {
  value       = "${var.collect_metric_cloudwatch == "Kinesis Firehose Metrics Source" ? module.collection-module.aws_kinesis_firehose_metrics_delivery_stream.name : ""}"
  description = "This output contains Kinesis Firehose for metrics stream Name."
}

output "cw_metrics_stream" {
  value       = "${var.collect_metric_cloudwatch == "Kinesis Firehose Metrics Source" ? module.collection-module.aws_cloudwatch_metric_stream.name : ""}"
  description = "This output contains CloudWatch metrics stream Name."
}

# output "sumologic_cloudwatch_metrics_source" {
#   value       = "${var.collect_metric_cloudwatch == "CloudWatch Metrics Source" ? module.collection-module.cloudwatch_metrics_source.id : ""}"
#   description = "This output contains sumologic CloudWatch metrics source id."
# }

output "sumologic_kinesis_firehose_for_logs_source" {
  value       = "${var.collect_logs_cloudwatch == "Kinesis Firehose Log Source" ? module.collection-module.kinesis_firehose_for_logs_source.id : ""}"
  description = "This output contains sumologic kinesis firehose for logs source id."
}

output "kf_logs_auto_enable_stack" {
  value       = "${var.collect_logs_cloudwatch == "Kinesis Firehose Log Source" ? module.collection-module.kinesis_firehose_for_logs_auto_subscribe_stack.auto_enable_logs_subscription.id : ""}"
  description = "This output contains Kinesis Firehose for logs auto enable CloudFormation Name."
}

output "kf_logs_stream" {
  value       = "${var.collect_logs_cloudwatch == "Kinesis Firehose Log Source" ? module.collection-module.aws_kinesis_firehose_logs_delivery_stream.name : ""}"
  description = "This output contains Kinesis Firehose for logs stream Name."
}

output "sumologic_cloudwatch_logs_source" {
  value       = "${var.collect_logs_cloudwatch == "Lambda Log Forwarder" ? module.collection-module.cloudwatch_logs_source.id : ""}"
  description = "This output contains sumologic CloudWatch log source id."
}

output "cw_logs_auto_enable_stack" {
  value       = "${var.collect_logs_cloudwatch == "Lambda Log Forwarder" ? module.collection-module.cloudwatch_logs_auto_subscribe_stack.auto_enable_logs_subscription.id : ""}"
  description = "This output contains CloudWatch logs cloudFormation stack."
}

output "log_forwarder_lambda_name" {
  value       = "${var.collect_logs_cloudwatch == "Lambda Log Forwarder" ? module.collection-module.cloudwatch_logs_lambda_function.id : ""}"
  description = "This output contains Lambda logs forwarder Function Name."
}

output "sumologic_classic_lb_source" {
  value       = "${var.collect_classic_lb == true ? module.collection-module.classic_lb_source.id : ""}"
  description = "This output contains sumologic Classic ELB source id."
}

output "classic_lb_sns_topic" {
  value       = "${var.executeTest4 ? module.collection-module.classic_lb_sns_topic.sns_topic.arn:""}"
  description = "This output contains AWS SNS topic arn."
}

output "classic_lb_sns_sub" {
  value       = "${var.collect_classic_lb == true ? module.collection-module.classic_lb_sns_subscription.arn : ""}"
  description = "This output contains Classic ELB AWS SNS subscription arn."
}

output "clb_auto_enable_stack" {
  value       = "${var.collect_classic_lb == true ? module.collection-module.classic_lb_auto_enable_stack.auto_enable_access_logs.id : ""}"
  description = "This output contains CLB auto enable CloudFormation Name."
}

output "sumologic_elb_source" {
  value       = "${var.collect_elb == true ? module.collection-module.elb_source.id : ""}"
  description = "This output contains sumologic ALB source id."
}

output "alb_sns_topic" {
  value       = "${var.executeTest4 ? module.collection-module.elb_sns_topic.sns_topic.arn:""}"
  description = "This output contains AWS SNS topic arn."
}

output "alb_sns_sub" {
  value       = "${var.collect_elb == true ? module.collection-module.elb_sns_subscription.arn : ""}"
  description = "This output contains ALB AWS SNS subscription arn."
}

output "alb_auto_enable_stack" {
  value       = "${var.collect_elb == true ? module.collection-module.elb_auto_enable_stack.auto_enable_access_logs.id : ""}"
  description = "This output contains ALB auto enable CloudFormation Name."
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