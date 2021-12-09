output "sumologic_field" {
  value       = module.classic_elb_module.sumologic_field
  description = "This output contains fields required for alb app."
}

output "sumologic_field_extraction_rule" {
  value       = module.classic_elb_module.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for alb app."
}

output "sumologic_content" {
  value       = module.classic_elb_module.sumologic_content
  description = "This output contains alb App."
}