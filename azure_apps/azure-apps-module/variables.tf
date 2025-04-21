variable "environment" {
  type        = string
  description = "Enter au, ca, de, eu, fed, jp, kr, us1 or us2. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"

  validation {
    condition = contains([
      "au",
      "ca",
      "de",
      "eu",
      "fed",
      "jp",
      "kr",
      "us1",
      "us2"], var.environment)
    error_message = "The value must be one of au, ca, de, eu, fed, jp, kr, us1 or us2."
  }
}

variable "access_id" {
  type        = string
  description = "Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"

  validation {
    condition     = can(regex("\\w+", var.access_id))
    error_message = "The SumoLogic access ID must contain valid characters."
  }
}

variable "access_key" {
  type        = string
  description = "Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"
  sensitive = true

  validation {
    condition     = can(regex("\\w+", var.access_key))
    error_message = "The SumoLogic access key must contain valid characters."
  }
}

variable "sumo_logic_azure_apps" {
  type = map(object({
    app_name = string
    app_uuid  = string
    app_version = string
  }))
  default = {
    azure_function = {
      app_name = "Azure Function"
      app_uuid  = "a0fb1bf0-2ab4-4f69-bf7e-5d97a176c7ea"
      app_version = "1.0.3"
    }
    
    azure_webapps = {
      app_name = "Azure Web Apps"
      app_uuid  = "a4741497-31c6-4fb2-a236-0223e98b59e8"
      app_version = "1.0.1"
    }

    azure_cosmosdb = {
      app_name = "Azure CosmosDB"
      app_uuid  = "d9ac4e28-13d6-4e69-8dcc-63fd6cb3bc80"
      app_version = "1.0.1"
    }
  }
}
