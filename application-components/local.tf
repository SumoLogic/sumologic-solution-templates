locals {
  sumologic_service_endpoint = var.sumologic_environment == "us1" ? "https://service.sumologic.com" : (contains(["stag", "long"], var.sumologic_environment) ? "https://${var.sumologic_environment}.sumologic.net" : "https://service.${var.sumologic_environment}.sumologic.com")
  sumologic_api_endpoint     = var.sumologic_environment == "us1" ? "https://api.sumologic.com/api" : (contains(["stag", "long"], var.sumologic_environment) ? "https://${var.sumologic_environment}-api.sumologic.net/api" : "https://api.${var.sumologic_environment}.sumologic.com/api")

  hierarchy_name    = "Application Components View"
  database_fer_name = "ApplicationComponentDatabaseLogsFER"

  components_on_kubernetes_deployment_values     = compact([for s in split(",", var.components_on_kubernetes_deployment) : trimspace(s)])
  components_on_non_kubernetes_deployment_values = compact([for s in split(",", var.components_on_non_kubernetes_deployment) : trimspace(s)])
  all_components_values                          = concat(local.components_on_kubernetes_deployment_values, local.components_on_non_kubernetes_deployment_values)
  has_any_kubernetes_deployments                 = length(local.components_on_kubernetes_deployment_values) > 0 ? true : false
  has_any_nonkubernetes_deployments              = length(local.components_on_non_kubernetes_deployment_values) > 0 ? true : false

  solution_version = "v1.0.0"
}
