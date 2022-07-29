
output "sumologic_field" {
  value       = module.sns_module.sumologic_field
  description = "This output contains fields required for amazon sns app."
}


output "sumologic_field_extraction_rule" {
  value       = module.sns_module.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for amazon sns app."
}

output "sumologic_content" {
  value       = module.sns_module.sumologic_content
  description = "This output contains amazon sns App."
}