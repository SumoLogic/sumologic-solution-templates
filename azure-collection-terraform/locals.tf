locals {
  solution_version = "v1.0.0"

  # Normalize region-specific SKU overrides (lowercase, no spaces) for lookup
  normalized_region_skus = {
    for region, config in var.region_specific_eventhub_skus :
    lower(replace(region, " ", "")) => config
  }

  # Get valid categories from Azure for each unique resource type
  # Use coalesce to match the data source logic: prefer log_namespace, fall back to metric_namespace
  unique_resource_types = distinct([
    for config in var.target_resource_types :
    coalesce(config.log_namespace, config.metric_namespace)
    if coalesce(config.log_namespace, config.metric_namespace) != null &&
    coalesce(config.log_namespace, config.metric_namespace) != ""
  ])

  # We need at least one resource of each type to get valid categories
  # Use the new per-type data source
  resource_type_examples = {
    for type in local.unique_resource_types :
    type => try(
      data.azurerm_resources.target_resources_by_type[type].resources[0].id,
      null
    )
  }

  # Get diagnostic categories for each resource type using the example resources
  valid_log_categories_by_type = {
    for type, resource_id in local.resource_type_examples :
    type => resource_id != null ? try(
      data.azurerm_monitor_diagnostic_categories.type_categories[type].log_category_types,
      []
    ) : []
  }

  # Resource types that need category validation (have non-empty log_categories)
  resources_needing_validation = toset([
    for config in var.target_resource_types :
    config.log_namespace
    if config.log_namespace != null &&
    config.log_categories != null &&
    length(config.log_categories) > 0
  ])

  # Get valid categories for each resource type that needs validation
  # Uses the efficient type_categories data source (one query per resource type)
  valid_categories_by_resource = {
    for type in local.resources_needing_validation :
    type => try(
      data.azurerm_monitor_diagnostic_categories.type_categories[type].log_category_types,
      []
    )
  }

  # Validate log categories and collect any errors
  # Skip validation if no resources found for the type (after tag filtering)
  log_category_validation_errors = flatten([
    for config in var.target_resource_types : [
      for category in coalesce(config.log_categories, []) :
      "Invalid category '${category}' for resource type '${config.log_namespace}'. Valid categories are: ${join(", ", try(local.valid_categories_by_resource[config.log_namespace], []))}"
      if config.log_namespace != null &&
      length(coalesce(config.log_categories, [])) > 0 &&
      try(local.resource_type_examples[config.log_namespace], null) != null && # Only validate if resources exist
      !contains(try(local.valid_categories_by_resource[config.log_namespace], []), category)
    ]
  ])

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

  # Map of resource type to name_filter (regex pattern) for filtering
  type_to_name_filter = {
    for config in var.target_resource_types :
    coalesce(config.log_namespace, config.metric_namespace) => lookup(config, "name_filter", "")
    if coalesce(config.log_namespace, config.metric_namespace) != null
  }

  # Flatten resources using per-type data source (no distinct needed, will dedupe by ID in map)
  all_resources_list = flatten([
    # Non-nested resources with name_filter (regex) filtering
    [for type in local.resource_types_for_discovery : [
      for res in data.azurerm_resources.target_resources_by_type[type].resources : res
      if !contains(local.parents_with_nested_configs, type) &&
      (local.type_to_name_filter[type] == "" || can(regex(local.type_to_name_filter[type], lower(res.name))))
    ]],
    # Nested resources
    [for parent_type, children_types in var.nested_namespace_configs : [
      for parent_res in(
        contains(local.resource_types_for_discovery, parent_type) ?
        data.azurerm_resources.target_resources_by_type[parent_type].resources : []
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

      tag_filters = length(config.required_resource_tags) > 0 ? [{
        type      = "AzureTagFilters"
        namespace = config.metric_namespace
        tags = [
          for tag_key, tag_value in config.required_resource_tags : {
            name   = tag_key
            values = [tag_value]
          }
        ]
      }] : []
    }
    if config.metric_namespace != null && config.metric_namespace != ""
  }

  # Count Event Hub instances per location (for auto-upgrade to Premium if >10)
  # Basic and Standard SKUs support max 10 Event Hubs per namespace
  # Premium SKU supports up to 100 Event Hubs per namespace
  eventhub_count_by_location = {
    for location in keys(local.resources_by_location_only) :
    location => length([
      for k, v in local.resources_by_type_and_location :
      k if v[0].location == location && length([
        for config in var.target_resource_types :
        config if config.log_namespace == local.eventhub_key_to_log_namespace[k] &&
        config.log_namespace != null &&
        config.log_namespace != ""
      ]) > 0
    ])
  }

  # Helper function to get SKU and throughput for a region
  # Priority: 
  # 1) region_specific override
  # 2) Auto-upgrade to Premium if >10 Event Hubs and SKU is Basic/Standard
  # 3) limited SKU regions → Standard
  # 4) global default
  eventhub_sku_by_region = {
    for location in distinct(concat(
      [for res in values(local.all_monitored_resources) : res.location if !contains(local.unsupported_eventhub_locations, lower(replace(res.location, " ", "")))],
      var.enable_activity_logs && !(contains(local.unsupported_eventhub_locations, lower(replace(var.location, " ", "")))) ? [var.location] : []
    )) :
    location => (
      # Check if there's a region-specific override
      contains(keys(local.normalized_region_skus), lower(replace(location, " ", ""))) ?
      # Region-specific override exists - use it
      local.normalized_region_skus[lower(replace(location, " ", ""))] :
      # No region-specific override - apply auto-upgrade logic
      {
        sku = (
          # First check: if limited SKU region and global is Premium/Dedicated, downgrade to Standard
          contains(local.limited_eventhub_sku_locations, lower(replace(location, " ", ""))) && contains(["Premium", "Dedicated"], var.eventhub_namespace_sku) ? "Standard" :
          # Second check: if >10 Event Hubs and SKU is Basic/Standard, auto-upgrade to Premium
          lookup(local.eventhub_count_by_location, location, 0) > 10 && contains(["Basic", "Standard"], var.eventhub_namespace_sku) ? "Premium" :
          # Default: use global SKU
          var.eventhub_namespace_sku
        )
        throughput_units = var.default_throughput_units
      }
    )
  }
}