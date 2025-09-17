variable "azure_subscription_id" {
  description = "The subscription id where your azure resources are present"
  type        = string
  default     = "c088dc46-d692-42ad-a4b6-9a542d28ad2a"
}

variable "azure_client_id" {
  description = "The client id "
  type        = string
  default     = "a1e5fb4a-8644-4867-be4d-a54d0aeaaeed"
}

variable "azure_client_secret" {
  description = "The client secret"
  type        = string
  default     = ""
}

variable "azure_tenant_id" {
  description = "The Tenant Id"
  type        = string
  default     = "a39bedba-be8f-4c0f-bfe2-b8c7913501ea"
}

variable "target_resource_types" {
  type        = list(string)
  description = "List of Azure resource types whose logs and metrics you want to collect."
  default     = ["Microsoft.KeyVault/vaults", "Microsoft.ServiceBus/Namespaces", "Microsoft.Storage/storageAccounts"]
}

variable "required_resource_tags" {
  description = "A map of tags to filter Azure resources by."
  type        = map(string)
  default     = {"logs-collection-destination":"sumologic"}
}

variable "nested_namespace_configs" {
  description = "Map of parent resource types to their child resource types that should be monitored"
  type        = map(list(string))
  default     = {
    "Microsoft.Storage/storageAccounts" = [
      "Microsoft.Storage/storageAccounts/blobServices",
      "Microsoft.Storage/storageAccounts/fileServices"
    ]
  }
}

variable "resource_group_name" {
  description = "The name of the Resource Group."
  default     = "RG-SUMO-267667"
  type        = string
}

variable "eventhub_namespace_name" {
  description = "The name of the Event Hub Namespace."
  type        = string
  default     = "SUMO-267667-Hub"
}

variable "eventhub_name" {
  description = "The name of the Event Hub."
  type        = string
  default     = "SUMO-267667-Hub-Logs-Collector"
}

variable "location" {
  description = "The location for the resources."
  type        = string
  default     = "East US"
}

variable "throughput_units" {
  description = "The number of throughput units for the Event Hub Namespace."
  type        = number
  default     = 5
}

variable "policy_name" {
  description = "The name of the Shared Access Policy."
  type        = string
  default     = "SumoCollectionPolicy"
}

variable "activity_log_export_name" {
  type        = string
  description = "Activity Log Export Name"
  default     = "activity_logs_export"
}

variable "activity_log_export_category" {
  type        = string
  description = "Activity Log Export Category"
  default     = "azure/activity-logs"
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
  default = "us1"
}

variable "sumologic_access_id" {
  type        = string
  description = "Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"

  validation {
    condition     = can(regex("\\w+", var.sumologic_access_id))
    error_message = "The SumoLogic access ID must contain valid characters."
  }
  default = ""
}

variable "sumologic_access_key" {
  type        = string
  description = "Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"
  sensitive   = true

  validation {
    condition     = can(regex("\\w+", var.sumologic_access_key))
    error_message = "The SumoLogic access key must contain valid characters."
  }
  default = ""
}
variable "installation_apps_list" {
  description = "list of apps to be installed"
  type = list(object({
    uuid        = string
    name        = string
    version     = string
  }))
  default     = [{
      uuid    = "53376d23-2687-4500-b61e-4a2e2a119658"
      name    = "Azure Storage"
      version = "1.0.3"
    },{
      uuid    = "449c796e-5da2-47ea-a304-e9299dd7435d"
      name    = "Azure Key Vault"
      version = "1.0.2"
    }]
}

variable "sumo_collector_name" {
  type        = string
  description = "Sumologic collector name"
  default     = "SUMO-267667-Collector"
}

variable "index_value" {
  type        = string
  description = "The _index if the collection is configured with custom partition."
  default     = "sumologic_default"
}
