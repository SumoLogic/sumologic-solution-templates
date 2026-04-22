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
    condition     = var.sumologic_environment_base_url == null || can(regex("^https://[a-zA-Z0-9.-]+\\.sumologic\\.(com|net)/api/?$", var.sumologic_environment_base_url))
    error_message = "The base URL must be null or a valid Sumo Logic API endpoint URL (e.g., 'https://api.ch.sumologic.com/api/' or 'https://stag-api.sumologic.net/api/')."
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
