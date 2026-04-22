resource "sumologic_app" "apps" {
  for_each = {
    for app in var.installation_apps_list : app.name => app
  }

  uuid    = each.value.uuid
  version = each.value.version

  parameters = each.value.parameters
}