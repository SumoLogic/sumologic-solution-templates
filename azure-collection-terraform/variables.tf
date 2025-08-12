

variable "azure_subscription_id" {
  description = "The subscription id where your azure resources are present"
  type        = string
  default     = ""
}

variable "azure_client_id" {
  description = "The client id "
  type        = string
  default     = ""
}

variable "azure_client_secret" {
  description = "The client secret"
  type        = string
  default     = ""
}

variable target_resource_ids {
  type = list
  description = "List of target azure resources whose logs and metrics you want to collect in the provided region and subscription"
  default = [
    "/subscriptions/c088dc46-d692-42ad-a4b6-9a542d28ad2a/resourceGroups/SUMO-267667-stable/providers/Microsoft.Storage/storageAccounts/sumo267667eastus/blobServices/default",
    "/subscriptions/c088dc46-d692-42ad-a4b6-9a542d28ad2a/resourceGroups/SUMO-267667-stable/providers/Microsoft.Storage/storageAccounts/sumo267667eastus/fileServices/default",
    "/subscriptions/c088dc46-d692-42ad-a4b6-9a542d28ad2a/resourceGroups/SUMO-267667-stable/providers/Microsoft.Storage/storageAccounts/sumo267667eastus/tableServices/default",
    "/subscriptions/c088dc46-d692-42ad-a4b6-9a542d28ad2a/resourceGroups/SUMO-267667-stable/providers/Microsoft.Storage/storageAccounts/sumo267667eastus/queueServices/default",
    "/subscriptions/c088dc46-d692-42ad-a4b6-9a542d28ad2a/resourceGroups/SUMO-267667-stable/providers/Microsoft.KeyVault/vaults/TFtest001",
    "/subscriptions/c088dc46-d692-42ad-a4b6-9a542d28ad2a/resourceGroups/SUMO-267667-stable/providers/Microsoft.Compute/virtualMachines/VM001",
    ]
}


variable "resource_group_name" {
  description = "The name of the Resource Group."
  default = "SUMO-267667"
  type        = string
}

variable "eventhub_namespace_name" {
  description = "The name of the Event Hub Namespace."
  type        = string
  default = "SUMO-267667-Hub"
}


variable "eventhub_name" {
  description = "The name of the Event Hub."
  type        = string
  default = "SUMO-267667-Hub-Logs-Collector"
}

# variable "eventhub_metrics_name" {
#   description = "The name of the Event Hub."
#   type        = string
#   default = "sumologicmetricseventhub"
# }

variable "location" {
  description = "The location for the resources."
  type        = string
  default = "East US"
}

variable "throughput_units" {
  description = "The number of throughput units for the Event Hub Namespace."
  type        = number
  default     = 5
}

variable "policy_name" {
  description = "The name of the Shared Access Policy."
  type        = string
  default = "SumoCollectionPolicy"
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
    "fed"], var.sumologic_environment)
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
  default = "suBxl4FJhYL8DO"
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



variable "apps_names_to_install" {
  type        = string
  description = <<EOT
            Provide comma separated list of applications for which sumologic resources (collection and apps) needs to be created. Allowed values are "Azure Web Apps,Azure Service Bus,Azure Storage,Azure Load Balancer,Azure CosmosDB".
        EOT
  validation {
    condition     = anytrue([for engine in split(",", var.apps_names_to_install) : contains(["",
      "Azure Storage",
      "Azure Key Vault", "Azure Virtual Machine"], engine)])
    error_message = "The value must be one of \"Azure Web Apps,Azure Service Bus,Azure Storage,Azure Load Balancer,Azure CosmosDB\""
  }
  default = "Azure Storage,Azure Key Vault,Azure Virtual Machine"
}


variable "sumo_collector_name" {
  type        = string
  description = "Sumologic collector name"
  default = "SUMO-267667-Collector"
}