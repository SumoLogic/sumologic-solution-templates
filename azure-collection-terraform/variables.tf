variable "azure_subscription_id" {
  description = "The subscription id where your azure resources are present"
  type        = string
  
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.azure_subscription_id))
    error_message = "Azure subscription ID must be a valid UUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "azure_client_id" {
  description = "The client id "
  type        = string
  
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.azure_client_id))
    error_message = "Azure client ID must be a valid UUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "azure_client_secret" {
  description = "The client secret"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.azure_client_secret) > 0
    error_message = "Azure client secret cannot be empty."
  }
}

variable "azure_tenant_id" {
  description = "The Tenant Id"
  type        = string
  
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.azure_tenant_id))
    error_message = "Azure tenant ID must be a valid UUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "target_resource_types" {
  type        = list(string)
  description = "List of Azure resource types whose logs and metrics you want to collect."
  
  validation {
    condition = alltrue([
      for resource_type in var.target_resource_types :
      can(regex("^Microsoft\\.[A-Za-z0-9]+/[A-Za-z0-9/]+$", resource_type))
    ])
    error_message = "All resource types must be valid Azure resource types in the format 'Microsoft.Service/resourceType' (e.g., 'Microsoft.KeyVault/vaults', 'Microsoft.Storage/storageAccounts')."
  }

  validation {
    condition = alltrue([
      for resource_type in var.target_resource_types :
      length(resource_type) > 0 && length(resource_type) <= 200
    ])
    error_message = "Resource type names must not be empty and must be 200 characters or less."
  }

  validation {
    condition = length(var.target_resource_types) > 0
    error_message = "At least one target resource type must be specified."
  }

  validation {
    condition = length(distinct(var.target_resource_types)) == length(var.target_resource_types)
    error_message = "Duplicate resource types are not allowed."
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

variable "throughput_units" {
  description = "The number of throughput units for the Event Hub Namespace."
  type        = number
  
  validation {
    condition     = var.throughput_units >= 1 && var.throughput_units <= 20
    error_message = "Throughput units must be between 1 and 20 for Event Hub Standard tier."
  }
  
  validation {
    condition     = floor(var.throughput_units) == var.throughput_units
    error_message = "Throughput units must be a whole number."
  }
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

variable "sumologic_environment" {
  type        = string
  description = "Enter au, ca, de, eu, jp, us2, in, kr, fed or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"

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
      "in",
      "kr",
      "fed"
    ], var.sumologic_environment)
    error_message = "The value must be one of au, ca, de, eu, jp, us1, us2, in, kr or fed."
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
  description = "list of apps to be installed"
  type = list(object({
    uuid        = string
    name        = string
    version     = string
  }))

  validation {
    condition = alltrue([
      for app in var.installation_apps_list : 
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", app.uuid))
    ])
    error_message = "All UUIDs must be in valid UUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }

  validation {
    condition = alltrue([
      for app in var.installation_apps_list : 
      length(app.name) > 0 && length(app.name) <= 100
    ])
    error_message = "App names must not be empty and must be 100 characters or less."
  }

  validation {
    condition = alltrue([
      for app in var.installation_apps_list : 
      can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", app.version))
    ])
    error_message = "App versions must be in semantic version format (x.y.z)."
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


variable "index_value" {
  type        = string
  description = "The _index if the collection is configured with custom partition."
}