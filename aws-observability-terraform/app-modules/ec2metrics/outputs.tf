output "sumologic_field" {
  value       = module.ec2metrics_module.sumologic_field
  description = "This output contains fields required for EC2 Metrics app."
}

output "sumologic_content" {
  value       = module.ec2metrics_module.sumologic_content
  description = "This output contains EC2 Metrics App."
}