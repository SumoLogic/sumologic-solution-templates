# Query resources with per-resource-type tag filtering (supports AND logic)
data "azurerm_resources" "target_resources_by_type" {
  for_each = {
    for config in var.target_resource_types :
    coalesce(config.log_namespace, config.metric_namespace) => config.required_resource_tags
    if coalesce(config.log_namespace, config.metric_namespace) != null
  }

  type          = each.key
  required_tags = each.value
}

data "azurerm_client_config" "current" {}

data "azurerm_monitor_diagnostic_categories" "all_categories" {
  for_each    = local.all_monitored_resources
  resource_id = each.value.id
}

# Get diagnostic categories for each resource type
data "azurerm_monitor_diagnostic_categories" "type_categories" {
  for_each = {
    for type, resource_id in local.resource_type_examples :
    type => resource_id
    if resource_id != null
  }
  resource_id = each.value
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_eventhub_namespace" "namespaces_by_location" {
  #checkov:skip=CKV_AZURE_228:Zone redundancy is automatically enabled by Azure for Event Hub namespaces in regions with availability zones. There is no explicit configuration property in the Azure API or Terraform provider - it's implicit based on region support.
  for_each = local.resources_by_location_only

  name                = "${var.eventhub_namespace_name}-${replace(lower(each.key), " ", "")}"
  location            = each.key
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = local.eventhub_sku_by_region[each.key].sku
  capacity            = local.eventhub_sku_by_region[each.key].throughput_units

  tags = {
    version = local.solution_version
  }
}

resource "azurerm_eventhub" "eventhubs_by_type_and_location" {
  for_each = {
    for k, v in local.resources_by_type_and_location : k => v
    if length([
      for config in var.target_resource_types :
      config if config.log_namespace == local.eventhub_key_to_log_namespace[k] &&
      config.log_namespace != null &&
      config.log_namespace != ""
    ]) > 0
  }

  name            = lower("eventhub-${replace(each.key, "/", "-")}")
  namespace_id    = azurerm_eventhub_namespace.namespaces_by_location[each.value[0].location].id
  partition_count = 4
  # Basic SKU only supports 1 day retention; Standard/Premium/Dedicated support up to 7 days
  message_retention = local.eventhub_sku_by_region[each.value[0].location].sku == "Basic" ? 1 : 7
}

resource "null_resource" "verify_all_eventhubs_exist" {
  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      set -e
      RG_NAME="${var.resource_group_name}"
      MAX_RETRIES=30
      RETRY_INTERVAL=10
      
      EVENTHUBS='${jsonencode([for k, v in azurerm_eventhub.eventhubs_by_type_and_location : {
        namespace = split("/", v.namespace_id)[8]
        name      = v.name
      }])}'
      
      echo "========================================="
      echo "Verifying ALL Event Hubs exist in Azure backend before diagnostic settings..."
      echo "========================================="
      echo "$EVENTHUBS" | jq -r '.[] | "  - \(.namespace)/\(.name)"'
      echo ""
      
      echo "$EVENTHUBS" | jq -r '.[] | "\(.namespace) \(.name)"' | while read NAMESPACE_NAME EVENTHUB_NAME; do
        echo "Checking: $EVENTHUB_NAME in $NAMESPACE_NAME"
        
        for i in $(seq 1 $MAX_RETRIES); do
          if az eventhubs eventhub show \
            --resource-group "$RG_NAME" \
            --namespace-name "$NAMESPACE_NAME" \
            --name "$EVENTHUB_NAME" \
            --query "id" -o tsv 2>/dev/null | grep -q "eventhubs/$EVENTHUB_NAME"; then
            echo "  ✓ Visible (attempt $i/$MAX_RETRIES)"
            break
          fi
          
          if [ $i -eq $MAX_RETRIES ]; then
            echo "  ✗ ERROR: Not visible after $((MAX_RETRIES * RETRY_INTERVAL)) seconds"
            exit 1
          fi
          
          echo "  ⏳ Waiting... (attempt $i/$MAX_RETRIES)"
          sleep $RETRY_INTERVAL
        done
      done
      
      echo ""
      echo "✅ All Event Hubs verified and visible in Azure backend"
      echo "========================================="
    EOT
  }

  depends_on = [azurerm_eventhub.eventhubs_by_type_and_location]
  
  triggers = {
    eventhub_ids = jsonencode(keys(azurerm_eventhub.eventhubs_by_type_and_location))
  }
}

resource "azurerm_eventhub_namespace_authorization_rule" "sumo_collection_policy" {
  for_each = azurerm_eventhub_namespace.namespaces_by_location

  name                = var.policy_name
  namespace_name      = each.value.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = false
}

data "external" "existing_diagnostic_settings" {
  for_each = local.all_monitored_resources

  program = ["bash", "-c", <<-EOT
    RESOURCE_ID="${each.value.id}"
    EXISTING=$(az monitor diagnostic-settings list --resource "$RESOURCE_ID" --query "value[?name=='diag-${replace(replace(each.value.name, "/", "-"), ".", "-")}'].id" -o tsv 2>/dev/null || echo "")
    if [ -n "$EXISTING" ]; then
      echo '{"exists":"true","id":"'"$EXISTING"'"}'
    else
      echo '{"exists":"false","id":""}'
    fi
  EOT
  ]
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting_logs" {
  # Fail early if any log categories are invalid
  lifecycle {
    precondition {
      condition     = length(local.log_category_validation_errors) == 0
      error_message = "Invalid log categories detected:\n${join("\n", local.log_category_validation_errors)}"
    }
  }

  for_each = {
    for k, v in local.all_monitored_resources : k => v
    if !contains(local.unsupported_eventhub_locations, lower(replace(v.location, " ", ""))) && 
    length([
      for config in var.target_resource_types :
      config if config.log_namespace == lookup(v, "parent_type", v.type) &&
      config.log_namespace != null &&
      config.log_namespace != ""
    ]) > 0 &&
    lookup(data.external.existing_diagnostic_settings[k].result, "exists", "false") == "false"
  }

  name                           = "diag-${replace(replace(each.value.name, "/", "-"), ".", "-")}"
  target_resource_id             = each.value.id
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy[each.value.location].id

  eventhub_name = azurerm_eventhub.eventhubs_by_type_and_location[
    "${each.value.type}-${each.value.location}"
  ].name

  dynamic "enabled_log" {
    # Select categories to enable: use the union of configured `log_categories` for the resource's
    # log_namespace when provided; otherwise enable all available categories returned by Azure.
    for_each = (
      length([
        for config in var.target_resource_types :
        config if config.log_namespace == lookup(each.value, "parent_type", each.value.type)
      ]) > 0
      ? (
        length([
          for config in var.target_resource_types :
          config if config.log_namespace == lookup(each.value, "parent_type", each.value.type) && length(lookup(config, "log_categories", [])) > 0
        ]) > 0
        ? distinct(flatten([
          for config in var.target_resource_types :
          lookup(config, "log_categories", []) if config.log_namespace == lookup(each.value, "parent_type", each.value.type)
        ]))
        : data.azurerm_monitor_diagnostic_categories.all_categories[each.key].log_category_types
      )
      : []
    )
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_metric" {
    for_each = length(data.azurerm_monitor_diagnostic_categories.all_categories[each.key].log_category_types) == 0 ? data.azurerm_monitor_diagnostic_categories.all_categories[each.key].metrics : []
    content {
      category = enabled_metric.value
    }
  }

  depends_on = [
    azurerm_eventhub_namespace.namespaces_by_location,
    azurerm_eventhub.eventhubs_by_type_and_location,
    azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy,
    null_resource.verify_all_eventhubs_exist
  ]

  timeouts {
    create = "30m"
    update = "30m"
    delete = "60m"
  }
}

resource "azurerm_eventhub_namespace" "activity_logs_namespace" {
  #checkov:skip=CKV_AZURE_228:Zone redundancy is automatically enabled by Azure for Event Hub namespaces in regions with availability zones. There is no explicit configuration property in the Azure API or Terraform provider - it's implicit based on region support.
  count               = var.enable_activity_logs && !(contains(local.unsupported_eventhub_locations, lower(replace(var.location, " ", "")))) ? 1 : 0
  name                = "${var.eventhub_namespace_name}-activity-logs"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = local.eventhub_sku_by_region[var.location].sku
  capacity            = local.eventhub_sku_by_region[var.location].throughput_units
}

resource "azurerm_eventhub_namespace_authorization_rule" "activity_logs_policy" {
  count               = var.enable_activity_logs && !(contains(local.unsupported_eventhub_locations, lower(replace(var.location, " ", "")))) ? 1 : 0
  name                = var.policy_name
  namespace_name      = azurerm_eventhub_namespace.activity_logs_namespace[0].name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = false
}

resource "azurerm_eventhub" "eventhub_for_activity_logs" {
  count           = var.enable_activity_logs && !(contains(local.unsupported_eventhub_locations, lower(replace(var.location, " ", "")))) ? 1 : 0
  name            = var.activity_log_export_name
  namespace_id    = azurerm_eventhub_namespace.activity_logs_namespace[0].id
  partition_count = 4
  # Basic SKU only supports 1 day retention; Standard/Premium/Dedicated support up to 7 days
  message_retention = local.eventhub_sku_by_region[var.location].sku == "Basic" ? 1 : 7
}

resource "null_resource" "verify_activity_log_eventhub" {
  count = var.enable_activity_logs && !(contains(local.unsupported_eventhub_locations, lower(replace(var.location, " ", "")))) ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      set -e
      NAMESPACE_NAME="${azurerm_eventhub_namespace.activity_logs_namespace[0].name}"
      EVENTHUB_NAME="${azurerm_eventhub.eventhub_for_activity_logs[0].name}"
      RG_NAME="${var.resource_group_name}"
      MAX_RETRIES=30
      RETRY_INTERVAL=10
      
      echo "Verifying Activity Log Event Hub exists in Azure backend: $EVENTHUB_NAME"
      
      for i in $(seq 1 $MAX_RETRIES); do
        if az eventhubs eventhub show \
          --resource-group "$RG_NAME" \
          --namespace-name "$NAMESPACE_NAME" \
          --name "$EVENTHUB_NAME" \
          --query "id" -o tsv 2>/dev/null | grep -q "eventhubs/$EVENTHUB_NAME"; then
          echo "✓ Activity Log Event Hub is visible in Azure backend (attempt $i/$MAX_RETRIES)"
          exit 0
        fi
        echo "  Waiting for Activity Log Event Hub to propagate (attempt $i/$MAX_RETRIES)..."
        sleep $RETRY_INTERVAL
      done
      
      echo "ERROR: Activity Log Event Hub not visible after $((MAX_RETRIES * RETRY_INTERVAL)) seconds"
      exit 1
    EOT
  }

  depends_on = [azurerm_eventhub.eventhub_for_activity_logs]
  
  triggers = {
    eventhub_id = var.enable_activity_logs ? azurerm_eventhub.eventhub_for_activity_logs[0].id : ""
  }
}

resource "azurerm_monitor_diagnostic_setting" "activity_logs_to_event_hub" {
  count                          = var.enable_activity_logs && !(contains(local.unsupported_eventhub_locations, lower(replace(var.location, " ", "")))) ? 1 : 0
  name                           = var.activity_log_export_name
  target_resource_id             = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  eventhub_name                  = azurerm_eventhub.eventhub_for_activity_logs[0].name
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.activity_logs_policy[0].id

  enabled_log {
    category = "Administrative"
  }
  enabled_log {
    category = "Security"
  }
  enabled_log {
    category = "ServiceHealth"
  }
  enabled_log {
    category = "Alert"
  }
  enabled_log {
    category = "Recommendation"
  }
  enabled_log {
    category = "Policy"
  }
  enabled_log {
    category = "Autoscale"
  }
  enabled_log {
    category = "ResourceHealth"
  }

  depends_on = [
    azurerm_eventhub_namespace.activity_logs_namespace,
    azurerm_eventhub.eventhub_for_activity_logs,
    azurerm_eventhub_namespace_authorization_rule.activity_logs_policy,
    null_resource.verify_activity_log_eventhub,
    null_resource.verify_all_eventhubs_exist
  ]

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}