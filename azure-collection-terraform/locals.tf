locals {
  sumologic_service_endpoint = var.sumologic_environment == "us1" ? "https://service.sumologic.com" : (contains(["stag", "long"], var.sumologic_environment) ? "https://${var.sumologic_environment}.sumologic.net" : "https://service.${var.sumologic_environment}.sumologic.com")
  sumologic_api_endpoint     = var.sumologic_environment == "us1" ? "https://api.sumologic.com/api" : (contains(["stag", "long"], var.sumologic_environment) ? "https://${var.sumologic_environment}-api.sumologic.net/api" : "https://api.${var.sumologic_environment}.sumologic.com/api")

  # is_adminMode = var.apps_folder_installation_location == "Admin Recommended Folder" ? true : false

  apps_to_install = compact([for s in split(",", var.apps_names_to_install) : trimspace(s)])

  solution_version = "v1.0.0"

  resources_by_location = {
    for res in flatten([
      for type, resources in data.azurerm_resources.all_target_resources : resources.resources
    ]) : res.id => res
  }

  resources_by_type_and_location = {
    for res in flatten([
      for type, resources in data.azurerm_resources.all_target_resources : resources.resources
    ]) : "${res.type}-${res.location}" => res...
  }

  resources_by_location_only = {
    for res in values(local.resources_by_location) :
    res.location => res...
  }

  unique_locations = distinct([for res in values(local.resources_by_location) : res.location])

  grouped_filters = {
    for filter in local.tag_filters :
    (length(split("/", filter.namespace)) > 2 ? join("/", slice(split("/", filter.namespace), 0, length(split("/", filter.namespace)) - 1)) : filter.namespace) => filter...
  }

  metrics_source_groups = {
    for parent_namespace, filters in local.grouped_filters : parent_namespace => {
      namespaces = [for filter in filters : filter.namespace]
      regions    = [for filter in filters : filter.region]
      tag_filters = filters
    }
  }

  tag_filters = [
    for type in var.target_resource_types : {
      type      = "AzureTagFilters"
      region    = distinct([
        for res in data.azurerm_resources.all_target_resources[type].resources :
        replace(res.location, " ", "")
      ])
      namespace = type
      tags = length(var.required_resource_tags) > 0 ? {
        name   = keys(var.required_resource_tags)[0]
        values = [values(var.required_resource_tags)[0]]
      } : {
        name   = ""
        values = []
      }
    }
  ]
  has_resources = length(data.azurerm_resources.all_target_resources) > 0
}