# Invalid Sumo Logic apps configuration - empty app fields
installation_apps_list = [
  {
    uuid    = ""
    name    = ""
    version = ""
    parameters = {
      "index_value" = "sumologic_default"
    }
  },
  {
    uuid    = "53376d23-2687-4500-b61e-4a2e2a119658"
    name    = "Azure Storage"
    version = "1.0.3"
    parameters = {
      "index_value" = "sumologic_default"
    }
  }
]