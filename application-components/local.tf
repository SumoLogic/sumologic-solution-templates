locals {
    sumologic_service_endpoint = var.sumologic_environment == "us1" ? "https://service.sumologic.com" : ( contains(["stag", "long"], var.sumologic_environment) ? "https://${var.sumologic_environment}.sumologic.net": "https://service.${var.sumologic_environment}.sumologic.com")
    sumologic_api_endpoint = var.sumologic_environment == "us1" ? "https://api.sumologic.com/api" : ( contains(["stag", "long"], var.sumologic_environment) ? "https://${var.sumologic_environment}-api.sumologic.net/api": "https://api.${var.sumologic_environment}.sumologic.com/api")
    database_engines_values = split(",", var.database_engines)
    hierarchy_name    = "Application Components View"
    database_fer_name = "ApplicationComponentDatabaseLogsFER"
    has_any_kubernetes_deployments = lower(var.database_deployment_type) == "kubernetes" || lower(var.database_deployment_type) == "both" ? true: false
    has_any_nonkubernetes_deployments = lower(var.database_deployment_type) == "non-kubernetes" || lower(var.database_deployment_type) == "both" ? true: false
    solution_version = "v1.0.0"
    folder_creation_date = formatdate("DD-MMM-YYYY hh:mm:ss", timestamp())
}
