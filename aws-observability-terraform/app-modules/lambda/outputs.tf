output "sumologic_field" {
  value       = module.lambda_module.sumologic_field
  description = "This output contains fields required for lambda app."
}

output "sumologic_field_extraction_rule" {
  value       = module.lambda_module.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for lambda app."
}

output "sumologic_content" {
  value       = module.lambda_module.sumologic_content
  description = "This output contains lambda App."
}