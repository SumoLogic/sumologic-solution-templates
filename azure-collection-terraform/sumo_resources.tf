# have to use version as hardcoded because during apply command latest always tries to update app resource and fails if the app with latest version is already installed
resource "sumologic_app" "azure_storage_app" {
    uuid = "53376d23-2687-4500-b61e-4a2e2a119658"
    version = "1.0.3"
    # Todo namespace to app mapping
    # separate app module
    count = contains(local.apps_to_install, "Azure Storage") ? 1 : 0
}

resource "sumologic_app" "azure_key_vault_app" {
    uuid = "449c796e-5da2-47ea-a304-e9299dd7435d"
    version = "1.0.2"
    count = contains(local.apps_to_install, "Azure Web Apps") ? 1 : 0
}

resource "sumologic_app" "azure_virtual_machine" {
    uuid = "dfa576fc-7d3b-4946-b414-149567e25d6a"
    version = "1.0.3"
    count = contains(local.apps_to_install, "Azure Virtual Machine") ? 1 : 0
}
