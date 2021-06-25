output "sumologic_collector" {
  value       = local.create_collector ? sumologic_collector.collector : {}
  description = "Sumo Logic collector details."
}

output "aws_iam_role" {
  value = local.create_iam_role ? aws_iam_role.sumologic_iam_role : {}
}