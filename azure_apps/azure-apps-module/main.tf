resource "sumologic_app" "this" {
  for_each = var.sumo_logic_azure_apps

  uuid    = each.value.app_uuid
  version =  each.value.app_version
  # count   = contains(local.apps_to_install, each.value.app_name) ? 1 : 0
}