output "sumologic_field_extraction_rule" {
  value       = module.sqs_module.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for amazon sqs app."
}

output "sumologic_content" {
  value       = module.sqs_module.sumologic_content
  description = "This output contains amazon sqs App."
}