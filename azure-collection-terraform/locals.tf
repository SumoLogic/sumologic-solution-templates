locals {
  solution_version = "v1.0.0"

  log_namespaces = distinct([
    for config in var.target_resource_types : config.log_namespace
    if config.log_namespace != null && config.log_namespace != ""
  ])

  metric_namespaces = distinct([
    for config in var.target_resource_types : config.metric_namespace
    if config.metric_namespace != null && config.metric_namespace != ""
  ])

  # Combined list: prioritize log_namespace, but include metric_namespace if log_namespace is missing
  resource_types_for_discovery = distinct(concat(
    local.log_namespaces,
    [
      for config in var.target_resource_types : config.metric_namespace
      if config.metric_namespace != null && config.metric_namespace != "" &&
      (config.log_namespace == null || config.log_namespace == "")
    ]
  ))

  namespace_mapping = {
    for config in var.target_resource_types :
    config.log_namespace => config.metric_namespace
    if config.log_namespace != null && config.log_namespace != ""
  }

  # Normalized list of unsupported regions for Event Hub namespace creation.
  # We normalize by lower-casing and removing spaces so inputs like "East US" and "eastus" match.
  unsupported_eventhub_locations = [for loc in var.eventhub_namespace_unsupported_locations : lower(replace(loc, " ", ""))]

  # Normalized list of locations that only support Basic/Standard SKUs for Event Hub namespaces
  limited_eventhub_sku_locations = [for loc in var.eventhub_namespace_limited_sku_locations : lower(replace(loc, " ", ""))]

  metric_to_log_mapping = {
    for config in var.target_resource_types :
    config.metric_namespace => config.log_namespace
    if config.metric_namespace != null && config.metric_namespace != ""
  }

  parents_with_nested_configs = keys(var.nested_namespace_configs)

  # Flatten resources with OR logic for tags (no distinct needed, will dedupe by ID in map)
  all_resources_list = flatten([
    # Non-nested resources (with optional tag filtering and OR logic)
    [for type in local.resource_types_for_discovery : [
      for res in concat(
        length(var.required_resource_tags) == 0 ? data.azurerm_resources.all_target_resources_no_tags[type].resources : [],
        length(var.required_resource_tags) > 0 ? data.azurerm_resources.all_target_resources_tag1[type].resources : [],
        length(var.required_resource_tags) > 1 ? data.azurerm_resources.all_target_resources_tag2[type].resources : []
      ) : res
      if !contains(local.parents_with_nested_configs, type)
    ]],
    # Nested resources (with optional tag filtering and OR logic)
    [for parent_type, children_types in var.nested_namespace_configs : [
      for parent_res in(
        contains(local.resource_types_for_discovery, parent_type) ? concat(
          length(var.required_resource_tags) == 0 ? data.azurerm_resources.all_target_resources_no_tags[parent_type].resources : [],
          length(var.required_resource_tags) > 0 ? data.azurerm_resources.all_target_resources_tag1[parent_type].resources : [],
          length(var.required_resource_tags) > 1 ? data.azurerm_resources.all_target_resources_tag2[parent_type].resources : []
        ) : []
        ) : [
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
    if !contains(local.unsupported_eventhub_locations, lower(replace(res.location, " ", "")))
  }

  resources_by_type_and_location = {
    for res in values(local.all_monitored_resources) :
    "${lookup(res, "parent_type", res.type)}-${res.location}" => res...
    if !contains(local.unsupported_eventhub_locations, lower(replace(res.location, " ", "")))
  }

  eventhub_key_to_log_namespace_grouped = {
    for res in values(local.all_monitored_resources) :
    "${lookup(res, "parent_type", res.type)}-${res.location}" => lookup(res, "parent_type", res.type)...
  }

  eventhub_key_to_log_namespace = {
    for k, v in local.eventhub_key_to_log_namespace_grouped : k => v[0]
  }

  metrics_source_groups = {
    for config in var.target_resource_types :
    config.metric_namespace => {
      namespaces = config.log_namespace != null && config.log_namespace != "" ? (
        lookup(var.nested_namespace_configs, config.log_namespace, [config.metric_namespace])
      ) : [config.metric_namespace]

      enabled = config.metric_namespace != null && config.metric_namespace != ""

      regions = [distinct([
        for res in values(local.all_monitored_resources) :
        replace(res.location, " ", "")
        if config.log_namespace != null && config.log_namespace != "" ? (
          res.type == config.log_namespace || lookup(res, "parent_type", "") == config.log_namespace
          ) : (
          res.type == config.metric_namespace
        )
      ])]

      tag_filters = length(var.required_resource_tags) > 0 ? [{
        type      = "AzureTagFilters"
        namespace = config.metric_namespace
        region = distinct([
          for res in values(local.all_monitored_resources) :
          replace(res.location, " ", "")
          if config.log_namespace != null && config.log_namespace != "" ? (
            res.type == config.log_namespace || lookup(res, "parent_type", "") == config.log_namespace
            ) : (
            res.type == config.metric_namespace
          )
        ])
        tags = [
          for tag_key, tag_value in var.required_resource_tags : {
            name   = tag_key
            values = [tag_value]
          }
        ]
      }] : []
    }
    if config.metric_namespace != null && config.metric_namespace != ""
  }
}