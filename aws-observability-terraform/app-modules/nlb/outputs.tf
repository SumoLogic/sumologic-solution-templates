output "sumologic_field" {
  value       = module.nlb_module.sumologic_field
  description = "This output contains fields required for nlb app."
}

output "sumologic_content" {
  value       = module.nlb_module.sumologic_content
  description = "This output contains nlb App."
}

output "sumologic_metric_rules" {
  value       = module.nlb_module.sumologic_metric_rules
  description = "This output contains metric rules required for nlb app."
}