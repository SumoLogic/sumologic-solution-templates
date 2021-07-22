output "sumologic_field" {
  value       = module.dynamodb_module.sumologic_field
  description = "This output contains fields required for dynamodb app."
}

output "sumologic_field_extraction_rule" {
  value       = module.dynamodb_module.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for dynamodb app."
}

output "sumologic_content" {
  value       = module.dynamodb_module.sumologic_content
  description = "This output contains dynamodb App."
}