output "sumologic_field" {
  value       = module.ecs_module.sumologic_field
  description = "This output contains fields required for ecs app."
}

output "sumologic_field_extraction_rule" {
  value       = module.ecs_module.sumologic_field_extraction_rule
  description = "This output contains Field Extraction rules required for ecs app."
}

output "sumologic_content" {
  value       = module.ecs_module.sumologic_content
  description = "This output contains ecs App."
}