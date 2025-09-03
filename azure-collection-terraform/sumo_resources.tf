# have to use version as hardcoded because during apply command latest always tries to update app resource and fails if the app with latest version is already installed
# resource "sumologic_app" "azure_storage_app" {
#     uuid = "53376d23-2687-4500-b61e-4a2e2a119658"
#     version = "1.0.3"
#     count = contains(local.apps_to_install, "Azure Storage") ? 1 : 0
#     parameters = {
#         "index_value": var.index_value
#     }
# }