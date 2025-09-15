locals {
  sumologic_service_endpoint = var.sumologic_environment == "us1" ? "https://service.sumologic.com" : (contains(["stag", "long"], var.sumologic_environment) ? "https://${var.sumologic_environment}.sumologic.net" : "https://service.${var.sumologic_environment}.sumologic.com")
  sumologic_api_endpoint     = var.sumologic_environment == "us1" ? "https://api.sumologic.com/api" : (contains(["stag", "long"], var.sumologic_environment) ? "https://${var.sumologic_environment}-api.sumologic.net/api" : "https://api.${var.sumologic_environment}.sumologic.com/api")

  apps_to_install  = compact([for s in split(",", var.apps_names_to_install) : trimspace(s)])
  solution_version = "v1.0.0"

  parents_with_nested_configs = keys(var.nested_namespace_configs)

  all_resources_list = flatten([    
    [for type, resources in data.azurerm_resources.all_target_resources : [
      for res in resources.resources : res
      if !contains(local.parents_with_nested_configs, type)
    ]],
    [for parent_type, children_types in var.nested_namespace_configs : [
      for parent_res in data.azurerm_resources.all_target_resources[parent_type].resources : [
        for child_type in children_types : {
          id                  = "${parent_res.id}/${element(split("/", child_type), length(split("/", child_type)) - 1)}/default"
          name                = "${parent_res.name}/${element(split("/", child_type), length(split("/", child_type)) - 1)}/default"
          type                = child_type
          location            = parent_res.location
          resource_group_name = parent_res.resource_group_name
          parent_resource_id  = parent_res.id
          parent_type         = parent_type
        }
      ]
    ]]
  ])

  all_monitored_resources = { for res in local.all_resources_list : res.id => res }

  resources_by_location_only = {
    for res in values(local.all_monitored_resources) :
    res.location => res...
  }

  resources_by_type_and_location = {
    for res in values(local.all_monitored_resources) : 
    "${lookup(res, "parent_type", res.type)}-${res.location}" => res...
  }

  unique_locations = distinct([for res in values(local.all_monitored_resources) : res.location])

  metrics_source_groups = {
    for parent_namespace in var.target_resource_types : parent_namespace => {
      namespaces = lookup(var.nested_namespace_configs, parent_namespace, [parent_namespace])

      regions = [distinct([
        for res in values(local.all_monitored_resources) :
        replace(res.location, " ", "")
        if res.type == parent_namespace || lookup(res, "parent_type", "") == parent_namespace
      ])]
      
      tag_filters = [{
        type      = "AzureTagFilters"
        namespace = parent_namespace
        region    = distinct([
          for res in values(local.all_monitored_resources) :
          replace(res.location, " ", "")
          if res.type == parent_namespace || lookup(res, "parent_type", "") == parent_namespace
        ])
        tags = length(var.required_resource_tags) > 0 ? {
          name   = keys(var.required_resource_tags)[0]
          values = [values(var.required_resource_tags)[0]]
        } : {
          name   = ""
          values = []
        }
      }]
    }
  }

  has_resources = length(data.azurerm_resources.all_target_resources) > 0
}