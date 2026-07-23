# have to use version as hardcoded because during apply command latest always tries to update app resource and fails if the app with latest version is already installed
resource "sumologic_app" "azure_function_app" {
    uuid = "a0fb1bf0-2ab4-4f69-bf7e-5d97a176c7ea"
    version = "1.0.3"
    # Todo namespace to app mapping
    # separate app module
    count = contains(local.apps_to_install, "Azure Functions") ? 1 : 0
}

resource "sumologic_app" "azure_web_app" {
    uuid = "a4741497-31c6-4fb2-a236-0223e98b59e8"
    version = "1.0.1"
    count = contains(local.apps_to_install, "Azure Web Apps") ? 1 : 0
}
resource "sumologic_app" "azure_cosmos_db_app" {
    uuid = "d9ac4e28-13d6-4e69-8dcc-63fd6cb3bc80"
    version = "1.0.1"
    count = contains(local.apps_to_install, "Azure CosmosDB") ? 1 : 0
}