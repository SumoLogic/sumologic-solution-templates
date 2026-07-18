output "installed_apps" {
  value = { for k, v in sumologic_app.apps : k => {
    uuid = v.uuid
    name = k
    id   = v.id
  } }
  description = "Information about installed Sumo Logic apps"
}
