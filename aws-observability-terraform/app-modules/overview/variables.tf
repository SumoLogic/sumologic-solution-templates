variable "environment" {
  type        = string
  description = "Enter au, ca, de, eu, fed, in, jp, kr, us1 or us2. Visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"

  validation {
    condition = contains([
      "au",
      "ca",
      "de",
      "eu",
      "fed",
      "in",
      "jp",
      "kr",
      "us1",
      "us2"], var.environment)
    error_message = "The value must be one of au, ca, de, eu, fed, in, jp, kr, us1 or us2."
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
  description = "Sumo Logic Access Key."

  validation {
    condition     = can(regex("\\w+", var.access_key))
    error_message = "The SumoLogic access key must contain valid characters."
  }
}

variable "json_file_directory_path" {
  type        = string
  description = "Directory path where all the JSONs are present."
}

variable "app_folder_id" {
  type        = string
  description = "Please provide a folder ID where you would like the app to be installed."
  default     = ""
}
