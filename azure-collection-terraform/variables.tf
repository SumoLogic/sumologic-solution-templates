

variable "azure_subscription_id" {
  description = "The subscription id where your azure resources are present"
  type        = string
}

variable "azure_client_id" {
  description = "The client id "
  type        = string
}

variable "azure_client_secret" {
  description = "The client secret"
  type        = string
}

variable target_resource_ids {
  type = list
  description = "List of target azure resources whose logs and metrics you want to collect in the provided region and subscription"
  default = ["/subscriptions/c088dc46-d692-42ad-a4b6-9a542d28ad2a/resourceGroups/azurefunctiontrace/providers/Microsoft.Web/sites/azurefunctiontrace/"]
}




variable "resource_group_name" {
  description = "The name of the Resource Group."
  default = "hpalazureobservability"
  type        = string
}

variable "eventhub_namespace_name" {
  description = "The name of the Event Hub Namespace."
  type        = string
  default = "sumologiclogseventhubnamespace"
}


variable "eventhub_name" {
  description = "The name of the Event Hub."
  type        = string
  default = "sumologiclogseventhub"
}

variable "eventhub_metrics_name" {
  description = "The name of the Event Hub."
  type        = string
  default = "sumologicmetricseventhub"
}

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



variable "apps_names_to_install" {
  type        = string
  description = <<EOT
            Provide comma separated list of applications for which sumologic resources (collection and apps) needs to be created. Allowed values are "Azure Web Apps,Azure Service Bus,Azure Storage,Azure Load Balancer,Azure CosmosDB".
        EOT
  validation {
    condition     = anytrue([for engine in split(",", var.apps_names_to_install) : contains(["",
      "Azure Web Apps",
      "Azure Service Bus",
      "Azure Storage",
      "Azure Functions",
      "Azure Load Balancer",
      "Azure CosmosDB"], engine)])
    error_message = "The value must be one of \"Azure Web Apps,Azure Service Bus,Azure Storage,Azure Load Balancer,Azure CosmosDB\""
  }
  default = "Azure Functions"
}