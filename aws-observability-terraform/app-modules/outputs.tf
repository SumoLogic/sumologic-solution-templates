output "sumologic_field_overview" {
  value       = module.overview_app.sumologic_field
  description = "This output contains fields required for overview app."
}

output "sumologic_content_overview" {
  value       = module.overview_app.sumologic_content
  description = "This output contains alb App."
}

output "sumologic_field_alb" {
  value       = module.alb_app.sumologic_field
  description = "This output contains fields required for overview app."
}

output "sumologic_field_extraction_rule_alb" {
  value       = module.alb_app.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for alb app."
}

output "sumologic_content_alb" {
  value       = module.alb_app.sumologic_content
  description = "This output contains alb App."
}

output "sumologic_field_elb" {
  value       = module.elb_app.sumologic_field
  description = "This output contains fields required for overview app."
}

output "sumologic_field_extraction_rule_elb" {
  value       = module.elb_app.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for alb app."
}

output "sumologic_content_elb" {
  value       = module.elb_app.sumologic_content
  description = "This output contains alb App."
}

output "sumologic_field_dynamodb" {
  value       = module.dynamodb_app.sumologic_field
  description = "This output contains fields required for dynamodb app."
}

output "sumologic_field_extraction_rule_dynamodb" {
  value       = module.dynamodb_app.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for dynamodb app."
}

output "sumologic_content_dynamodb" {
  value       = module.dynamodb_app.sumologic_content
  description = "This output contains dynamodb App."
}

output "sumologic_field_apigateway" {
  value       = module.apigateway_app.sumologic_field
  description = "This output contains fields required for apigateway app."
}

output "sumologic_field_extraction_rule_apigateway" {
  value       = module.apigateway_app.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for apigateway app."
}

output "sumologic_content_apigateway" {
  value       = module.apigateway_app.sumologic_content
  description = "This output contains apigateway App."
}

output "sumologic_field_ec2metrics" {
  value       = module.ec2metrics_app.sumologic_field
  description = "This output contains fields required for EC2 Metrics app."
}

output "sumologic_content_ec2metrics" {
  value       = module.ec2metrics_app.sumologic_content
  description = "This output contains EC2 Metrics App."
}

output "sumologic_field_rds" {
  value       = module.rds_app.sumologic_field
  description = "This output contains fields required for rds app."
}

output "sumologic_field_extraction_rule_rds" {
  value       = module.rds_app.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for rds app."
}

output "sumologic_content_rds" {
  value       = module.rds_app.sumologic_content
  description = "This output contains rds App."
}

output "sumologic_metric_rules_rds" {
  value       = module.rds_app.sumologic_metric_rules
  description = "This output contains metric rules required for rds app."
}

output "sumologic_field_lambda" {
  value       = module.lambda_app.sumologic_field
  description = "This output contains fields required for lambda app."
}

output "sumologic_field_extraction_rule_lambda" {
  value       = module.lambda_app.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for lambda app."
}

output "sumologic_content_lambda" {
  value       = module.lambda_app.sumologic_content
  description = "This output contains lambda App."
}

output "sumologic_field_elasticache" {
  value       = module.elasticache_app.sumologic_field
  description = "This output contains fields required for elasticache app."
}

output "sumologic_field_extraction_rule_elasticache" {
  value       = module.elasticache_app.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for elasticache app."
}

output "sumologic_content_elasticache" {
  value       = module.elasticache_app.sumologic_content
  description = "This output contains elasticache App."
}

output "sumologic_field_ecs" {
  value       = module.ecs_app.sumologic_field
  description = "This output contains fields required for ecs app."
}

output "sumologic_field_extraction_rule_ecs" {
  value       = module.ecs_app.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for ecs app."
}

output "sumologic_content_ecs" {
  value       = module.ecs_app.sumologic_content
  description = "This output contains ecs App."
}

output "sumologic_field_nlb" {
  value       = module.nlb_app.sumologic_field
  description = "This output contains fields required for nlb app."
}

output "sumologic_content_nlb" {
  value       = module.nlb_app.sumologic_content
  description = "This output contains nlb App."
}

output "sumologic_metric_rules_nlb" {
  value       = module.nlb_app.sumologic_metric_rules
  description = "This output contains metric rules required for nlb app."
}

output "sumologic_content_rce" {
  value       = module.rce_app.sumologic_content
  description = "This output contains rce Apps."
}