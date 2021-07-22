output "sumologic_field" {
  value       = module.overview_module.sumologic_field
  description = "This output contains fields required for overview app."
}

output "sumologic_content" {
  value       = module.overview_module.sumologic_content
  description = "This output contains overview App."
}