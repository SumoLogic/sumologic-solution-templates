# The below module is used to install AWS and Sumo Logic resources to collect logs and metrics from AWS into Sumo Logic.
# NOTE - For multi account and multi region deployment, copy the module and provide different aws provider for region and account.
#
module "collection-module" {
  source = "../../../source-module"

  aws_account_alias         = var.aws_account_alias
  sumologic_organization_id = var.sumologic_organization_id
  access_id                 = var.sumologic_access_id
  access_key                = var.sumologic_access_key
  environment               = var.sumologic_environment

  sumologic_existing_collector_details = {
    create_collector = var.create_collector
    collector_id = var.collector_id
  }

  # ALB logs
  # elb_source_url = "https://api.sumologic.com/api/v1/collectors/185689129/sources/916197188"
  collect_elb_logs = var.collect_elb

  # CLB logs
  # classic_lb_log_source_url = "https://api.sumologic.com/api/v1/collectors/185689129/sources/916197188"
  collect_classic_lb_logs = var.collect_classic_lb

  # CW logs 
  # logs_source_url = "https://api.sumologic.com/api/v1/collectors/185689129/sources/915277706"
  collect_cloudwatch_logs = var.collect_logs_cloudwatch
  
  # Enable Collection of Cloudtrail logs
  collect_cloudtrail_logs   = var.collect_cloudtrail

  # Collect CW metrics
  collect_cloudwatch_metrics = var.collect_metric_cloudwatch

  # RCE
  collect_root_cause_data = var.collect_rce

  # wait_for_seconds = "10"
}