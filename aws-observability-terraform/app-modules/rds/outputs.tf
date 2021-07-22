output "sumologic_field" {
  value       = module.rds_module.sumologic_field
  description = "This output contains fields required for rds app."
}

output "sumologic_field_extraction_rule" {
  value       = module.rds_module.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for rds app."
}

output "sumologic_content" {
  value       = module.rds_module.sumologic_content
  description = "This output contains rds App."
}

output "sumologic_metric_rules" {
  value       = module.rds_module.sumologic_metric_rules
  description = "This output contains metric rules required for rds app."
}