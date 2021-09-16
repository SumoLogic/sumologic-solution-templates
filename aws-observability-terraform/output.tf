output "Apps" {
  value       = module.sumo-module
  description = "All outputs related to apps."
  sensitive = true
}

output "Collection" {
  value       = module.collection-module
  description = "All outputs related to collection and sources."
  sensitive = true
}