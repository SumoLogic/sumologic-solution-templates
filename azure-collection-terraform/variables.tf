variable "azure_subscription_id" {
  description = "The subscription id where your azure resources are present. If not provided, will use the current Azure CLI context."
  type        = string
  default     = null

  validation {
    condition     = var.azure_subscription_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.azure_subscription_id))
    error_message = "The azure_subscription_id must be a valid UUID format or null for Azure CLI auto-detection."
  }
}

variable "azure_client_id" {
  description = "The client id for Azure authentication. If not provided, will use Azure CLI context."
  type        = string
  default     = null

  validation {
    condition     = var.azure_client_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.azure_client_id))
    error_message = "The azure_client_id must be a valid UUID format or null."
  }
}

variable "azure_client_secret" {
  description = "The client secret for Azure authentication. If not provided, will use Azure CLI context."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.azure_client_secret == null || try(length(var.azure_client_secret) > 0, false)
    error_message = "The azure_client_secret must be a non-empty string or null."
  }
}

variable "azure_tenant_id" {
  description = "The Tenant Id. If not provided, will use the current Azure CLI context."
  type        = string
  default     = null

  validation {
    condition     = var.azure_tenant_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.azure_tenant_id))
    error_message = "The azure_tenant_id must be a valid UUID format or null."
  }
}

variable "target_resource_types" {
  type = list(object({
    log_namespace          = optional(string)
    metric_namespace       = optional(string)
    log_categories         = optional(list(string), [])
    required_resource_tags = optional(map(string), {})
    name_filter            = optional(string, "")
    log_source_filters = optional(list(object({
      filter_type = string
      name        = string
      regexp      = string
      mask        = optional(string, null)
      regions     = optional(list(string), [])
    })), [])
    metrics_source_filters = optional(list(object({
      filter_type = string
      name        = string
      regexp      = string
      mask        = optional(string, null)
    })), [])
  }))
  description = "List of Azure resource types with their log and metric namespace configuration. Both namespace fields are optional, but at least one must be provided. The required_resource_tags field filters resources for this specific type using AND logic (all tags must match). The name_filter field is optional and filters resources by regex pattern (case-insensitive); if omitted or empty string, no name filtering is applied. The log_source_filters field is optional and specifies filters to apply to the Sumo Logic Azure Event Hub log source for this resource type. Each filter can optionally specify regions (list of region names); if omitted or empty, the filter applies to all regions. The metrics_source_filters field is optional and specifies filters to apply to the Sumo Logic Azure metrics source for this resource type."

  validation {
    condition = alltrue([
      for resource_config in var.target_resource_types :
      resource_config.log_namespace == null || resource_config.log_namespace == "" || can(regex("^Microsoft\\.[A-Za-z0-9]+/[A-Za-z0-9/]+$", resource_config.log_namespace))
    ])
    error_message = "All log_namespace values must be valid Azure resource types in the format 'Microsoft.Service/resourceType' (e.g., 'Microsoft.KeyVault/vaults', 'Microsoft.Storage/storageAccounts') or null/empty."
  }

  validation {
    condition = alltrue([
      for resource_config in var.target_resource_types :
      resource_config.metric_namespace == null || resource_config.metric_namespace == "" || can(regex("^Microsoft\\.[A-Za-z0-9]+/[A-Za-z0-9/]+$", resource_config.metric_namespace))
    ])
    error_message = "All metric_namespace values must be valid Azure resource types in the format 'Microsoft.Service/resourceType' (e.g., 'Microsoft.KeyVault/vaults', 'Microsoft.Storage/storageAccounts') or null/empty."
  }

  validation {
    condition = alltrue([
      for resource_config in var.target_resource_types :
      (resource_config.log_namespace == null || resource_config.log_namespace == "" ? 0 : length(resource_config.log_namespace)) <= 200 &&
      (resource_config.metric_namespace == null || resource_config.metric_namespace == "" ? 0 : length(resource_config.metric_namespace)) <= 200
    ])
    error_message = "Resource type namespaces must be 200 characters or less."
  }

  validation {
    condition     = length(var.target_resource_types) >= 0
    error_message = "Target resource types must be a valid list."
  }

  validation {
    condition = alltrue([
      for resource_config in var.target_resource_types :
      (resource_config.log_namespace != null && resource_config.log_namespace != "") ||
      (resource_config.metric_namespace != null && resource_config.metric_namespace != "")
    ])
    error_message = "Each resource type must have at least one namespace defined (log_namespace or metric_namespace cannot both be null/empty)."
  }

  validation {
    condition = length(distinct([
      for config in var.target_resource_types :
      config.log_namespace
      if config.log_namespace != null && config.log_namespace != ""
      ])) == length([
      for config in var.target_resource_types :
      config.log_namespace
      if config.log_namespace != null && config.log_namespace != ""
    ])
    error_message = "Duplicate log_namespace values are not allowed."
  }


}

variable "required_resource_tags" {
  description = "A map of tags to filter Azure resources by."
  type        = map(string)
}

variable "nested_namespace_configs" {
  description = "Map of parent resource types to their child resource types that should be monitored"
  type        = map(list(string))
}

variable "resource_group_name" {
  description = "The name of the Resource Group."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.resource_group_name))
    error_message = "Resource group name can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-). Spaces are not allowed."
  }

  validation {
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters long."
  }

  validation {
    condition     = !can(regex("^[._-]|[._-]$", var.resource_group_name))
    error_message = "Resource group name should not start or end with periods, underscores, or hyphens."
  }

  validation {
    condition     = !contains(["microsoft", "azure", "system"], lower(var.resource_group_name))
    error_message = "Resource group name cannot use reserved names like 'Microsoft', 'Azure', or 'System'."
  }
}

variable "eventhub_namespace_name" {
  description = "The name of the Event Hub Namespace."
  type        = string

  validation {
    condition     = length(var.eventhub_namespace_name) >= 6 && length(var.eventhub_namespace_name) <= 50
    error_message = "Event Hub namespace name must be between 6 and 50 characters long."
  }

  validation {
    condition     = can(regex("^[a-zA-Z]", var.eventhub_namespace_name))
    error_message = "Event Hub namespace name must begin with a letter (a-z or A-Z)."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.eventhub_namespace_name))
    error_message = "Event Hub namespace name can only contain letters (a-z, A-Z), numbers (0-9), and hyphens (-)."
  }

  validation {
    condition     = can(regex("[a-zA-Z0-9]$", var.eventhub_namespace_name))
    error_message = "Event Hub namespace name must end with a letter or a number."
  }

  default = "SUMO-267667-Hub"
}

variable "location" {
  description = "The location for the resources."
  type        = string

  validation {
    condition = contains([
      "East US", "East US 2", "West US", "West US 2", "West US 3", "Central US", "North Central US", "South Central US", "West Central US",
      "Canada Central", "Canada East",
      "Brazil South", "Brazil Southeast",
      "North Europe", "West Europe", "UK South", "UK West", "France Central", "France South", "Germany West Central", "Germany North",
      "Switzerland North", "Switzerland West", "Norway East", "Norway West",
      "East Asia", "Southeast Asia", "Japan East", "Japan West", "Australia East", "Australia Southeast", "Australia Central", "Australia Central 2",
      "Korea Central", "Korea South", "India Central", "India South", "India West",
      "UAE Central", "UAE North", "South Africa North", "South Africa West"
    ], var.location)
    error_message = "Location must be a valid Azure region. Common regions include: East US, West US 2, Central US, North Europe, West Europe, Southeast Asia, etc."
  }
}

# Throughput units (applies to Standard and Premium SKUs only)
variable "default_throughput_units" {
  description = "The number of throughput units to assign for Event Hub namespaces (global default). Only applicable for Standard and Premium SKUs. Valid values: 1, 2, 4, 8, or 16."
  type        = number
  default     = 4

  validation {
    condition     = contains([1, 2, 4, 8, 16], var.default_throughput_units)
    error_message = "Throughput units must be one of: 1, 2, 4, 8, or 16."
  }

  validation {
    condition     = floor(var.default_throughput_units) == var.default_throughput_units
    error_message = "Throughput units must be a whole number."
  }
}

variable "eventhub_namespace_sku" {
  description = <<-EOT
    The SKU (pricing tier) of the Event Hub Namespace (global default). Valid values: Basic, Standard, Premium, or Dedicated.
    
    IMPORTANT: Auto-Upgrade Behavior
    If a region has more than 10 Event Hub instances and the SKU is Basic or Standard, the system will automatically 
    upgrade to Premium SKU for that region. This is necessary because:
    - Basic/Standard SKUs support max 10 Event Hubs per namespace
    - Premium SKU supports up to 100 Event Hubs per namespace
    
    You can override this auto-upgrade behavior using region_specific_eventhub_skus.
  EOT
  type        = string

  validation {
    condition     = contains(["Basic", "Standard", "Premium", "Dedicated"], var.eventhub_namespace_sku)
    error_message = "Event Hub namespace SKU must be one of: Basic, Standard, Premium, or Dedicated."
  }
}

variable "region_specific_eventhub_skus" {
  description = <<-EOT
    Optional map to override Event Hub SKU and throughput units for specific regions.
    Keys are region names (case-insensitive, spaces ignored). Each value specifies:
    - sku: "Basic", "Standard", "Premium", or "Dedicated" (overrides global eventhub_namespace_sku)
    - throughput_units: 1, 2, 4, 8, or 16 (for Standard/Premium; ignored for Basic/Dedicated)
    
    Example:
    {
      "East US" = {
        sku              = "Premium"
        throughput_units = 8
      }
      "West Europe" = {
        sku              = "Standard"
        throughput_units = 2
      }
      "Central US" = {
        sku              = "Basic"
        throughput_units = 1
      }
    }
  EOT
  type = map(object({
    sku              = string
    throughput_units = number
  }))
  default = {}

  validation {
    condition = alltrue([
      for region, config in var.region_specific_eventhub_skus :
      contains(["Basic", "Standard", "Premium", "Dedicated"], config.sku)
    ])
    error_message = "All region-specific SKUs must be one of: Basic, Standard, Premium, or Dedicated."
  }

  validation {
    condition = alltrue([
      for region, config in var.region_specific_eventhub_skus :
      contains([1, 2, 4, 8, 16], config.throughput_units)
    ])
    error_message = "All region-specific throughput units must be one of: 1, 2, 4, 8, or 16."
  }

  validation {
    condition = alltrue([
      for region, config in var.region_specific_eventhub_skus :
      floor(config.throughput_units) == config.throughput_units
    ])
    error_message = "All region-specific throughput units must be whole numbers."
  }
}

variable "eventhub_namespace_unsupported_locations" {
  description = "List of locations (regions) where Event Hub Namespace creation is not supported or should be skipped. Values can be human-friendly region names; comparison is case-insensitive and ignores spaces. Example: [\"China East\", \"US Gov Virginia\"]"
  type        = list(string)
  default = [
    "South Africa West",
    "Australia Central 2",
    "USGov Arizona",
    "USGov Texas",
    "USGov Virginia",
    "Brazil Southeast",
    "China East",
    "China East 2",
    "China East 3",
    "China North",
    "China North 2",
    "China North 3",
    "France South",
    "Germany North",
    "Norway West",
    "Sweden South",
    "Switzerland West",
    "Taiwan North",
    "UAE Central",
  ]
}

variable "eventhub_namespace_limited_sku_locations" {
  description = "List of locations (regions) that only support Basic & Standard SKUs for Event Hub namespaces. Values are human-friendly names; comparison is case-insensitive and ignores spaces. Example: [\"West India\", \"Mexico Central\"]"
  type        = list(string)
  default = [
    "West India",
    "Mexico Central",
  ]
}

variable "policy_name" {
  description = "The name of the Shared Access Policy."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.policy_name))
    error_message = "Policy name can only contain alphanumeric characters and hyphens, following Azure naming conventions."
  }

  validation {
    condition     = length(var.policy_name) >= 1 && length(var.policy_name) <= 64
    error_message = "Policy name must be between 1 and 64 characters long."
  }
}

variable "activity_log_export_name" {
  type        = string
  description = "Activity Log Export Name"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_.-]*[a-zA-Z0-9]$", var.activity_log_export_name)) || can(regex("^[a-zA-Z0-9]$", var.activity_log_export_name))
    error_message = "Activity log export name must start and end with alphanumeric characters, and can contain letters, numbers, underscores, periods, and hyphens."
  }

  validation {
    condition     = length(var.activity_log_export_name) >= 1 && length(var.activity_log_export_name) <= 128
    error_message = "Activity log export name must be between 1 and 128 characters long."
  }

  validation {
    condition     = !can(regex("__", var.activity_log_export_name)) && !can(regex("\\.\\.", var.activity_log_export_name)) && !can(regex("--", var.activity_log_export_name))
    error_message = "Activity log export name cannot contain consecutive underscores, periods, or hyphens."
  }
}

variable "activity_log_export_category" {
  type        = string
  description = "Activity Log Export Category"
}

variable "enable_activity_logs" {
  description = "Set to true to enable subscription-level activity log export."
  type        = bool
}

variable "activity_log_filters" {
  type = list(object({
    filter_type = string
    name        = string
    regexp      = string
    mask        = optional(string, null)
  }))
  default     = []
  description = "Optional filters to apply to the Sumo Logic Activity Log source. Each filter can Include, Exclude, or Mask log messages based on regex patterns. The mask field is required only for Mask filter type."
}

variable "sumologic_environment" {
  type        = string
  description = "Enter au, ca, de, eu, jp, us2, kr, fed ch or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"

  validation {
    condition = contains([
      "stag",
      "long",
      "au",
      "ca",
      "de",
      "eu",
      "jp",
      "us1",
      "us2",
      "kr",
      "fed",
      "ch"
    ], var.sumologic_environment)
    error_message = "The value must be one of au, ca, de, eu, jp, us1, us2, kr, ch or fed."
  }
}

variable "sumologic_environment_base_url" {
  type        = string
  description = "Base URL for custom Sumo Logic environments (e.g., 'https://api.ch.sumologic.com/api/' for Switzerland). If provided, this takes precedence over the sumologic_environment parameter. Leave empty for standard deployments."
  default     = null

  validation {
    condition     = var.sumologic_environment_base_url == null || can(regex("^https://[a-zA-Z0-9.-]+\\.sumologic\\.com/api/?$", var.sumologic_environment_base_url))
    error_message = "The base URL must be null or a valid Sumo Logic API endpoint URL (e.g., 'https://api.ch.sumologic.com/api/')."
  }
}

variable "sumologic_access_id" {
  type        = string
  description = "Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"

  validation {
    condition     = can(regex("\\w+", var.sumologic_access_id))
    error_message = "The SumoLogic access ID must contain valid characters."
  }
}

variable "sumologic_access_key" {
  type        = string
  description = "Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"
  sensitive   = true

  validation {
    condition     = can(regex("\\w+", var.sumologic_access_key))
    error_message = "The SumoLogic access key must contain valid characters."
  }
}

variable "installation_apps_list" {
  description = "List of Sumo Logic apps to be installed. Each app can have custom parameters specific to that app."
  type = list(object({
    uuid       = string
    name       = string
    version    = string
    parameters = optional(map(string), {})
  }))
  default = []

  validation {
    condition = length(var.installation_apps_list) == 0 || alltrue([
      for app in var.installation_apps_list :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", app.uuid))
    ])
    error_message = "All UUIDs must be in valid UUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }

  validation {
    condition = length(var.installation_apps_list) == 0 || alltrue([
      for app in var.installation_apps_list :
      length(app.name) > 0 && length(app.name) <= 100
    ])
    error_message = "App names must not be empty and must be 100 characters or less."
  }

  validation {
    condition = length(var.installation_apps_list) == 0 || alltrue([
      for app in var.installation_apps_list :
      app.version == "latest" || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", app.version))
    ])
    error_message = "App versions must be either 'latest' or in semantic version format (x.y.z)."
  }

  validation {
    condition = length(var.installation_apps_list) == 0 || alltrue([
      for app in var.installation_apps_list :
      alltrue([
        for key, value in app.parameters :
        length(key) > 0 && length(key) <= 128 && length(value) <= 1024
      ])
    ])
    error_message = "Parameter keys must be between 1-128 characters and values must be 1024 characters or less."
  }
}

variable "sumo_collector_name" {
  type        = string
  description = "Name for the SumoLogic collector"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.sumo_collector_name)) && length(var.sumo_collector_name) > 0 && length(var.sumo_collector_name) <= 128
    error_message = "Collector name contains invalid characters. Please use alphanumeric characters, hyphens (-), and underscores (_) only."
  }
}

variable "prevent_deletion_if_contains_resources" {
  description = <<-EOT
    Controls the azurerm provider's resource_group.prevent_deletion_if_contains_resources feature.
    When true, the provider will prevent deletion of resource groups that still contain resources.
    Default is true (safer for production). Tests can override this variable and set it to false
    so that test cleanup can delete resource groups that still contain nested resources.
  EOT
  type        = bool
  default     = true
}

variable "scan_interval" {
  description = "Time interval in milliseconds of scans for new metrics data. The default is 300000 (5 minutes) and the minimum value is 1000 milliseconds (1 second)."
  type        = number
  default     = 300000

  validation {
    condition     = var.scan_interval >= 1000
    error_message = "The scan_interval must be at least 1000 milliseconds (1 second)."
  }
}