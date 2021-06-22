output "sumologic_field" {
  value       = module.apigateway_module.sumologic_field
  description = "This output contains fields required for apigateway app."
}

output "sumologic_field_extraction_rule" {
  value       = module.apigateway_module.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for apigateway app."
}

output "sumologic_content" {
  value       = module.apigateway_module.sumologic_content
  description = "This output contains apigateway App."
}