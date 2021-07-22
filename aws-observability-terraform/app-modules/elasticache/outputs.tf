output "sumologic_field" {
  value       = module.elasticache_module.sumologic_field
  description = "This output contains fields required for elasticache app."
}

output "sumologic_field_extraction_rule" {
  value       = module.elasticache_module.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for elasticache app."
}

output "sumologic_content" {
  value       = module.elasticache_module.sumologic_content
  description = "This output contains elasticache App."
}