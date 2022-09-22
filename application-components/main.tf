data "sumologic_personal_folder" "personalFolder" {}
data "sumologic_admin_recommended_folder" "adminFolder" {}

# create the folder in admin recommended folder
resource "sumologic_folder" "admin_root_apps_folder" {
  count       = local.is_adminMode ? 1 : 0
  description = "This folder contains all the apps for Application Component Solution."
  name        = "${var.apps_folder_name} - ${local.solution_version}"
  parent_id   = data.sumologic_admin_recommended_folder.adminFolder.id
  provider    = sumologic.admin
}

# create the folder in personal folder
resource "sumologic_folder" "personal_root_apps_folder" {
  count       = local.is_adminMode ? 0 : 1
  description = "This folder contains all the apps for Application Component Solution."
  name        = "${var.apps_folder_name} - ${local.solution_version}"
  parent_id   = data.sumologic_personal_folder.personalFolder.id
}


#Provides a way to configure permissions on a content to share it with a user, a role, or the entire org
resource "sumologic_content_permission" "share_admin_root_apps_folder_with_org" {
  count                = (var.share_apps_folder_with_org && local.is_adminMode) ? 1 : 0
  content_id           = sumologic_folder.admin_root_apps_folder[count.index].id
  notify_recipient     = false
  notification_message = "You now have the permission to access this content"
  permission {
    permission_name = "View"
    source_type     = "org"
    source_id       = var.sumologic_organization_id
  }
  provider = sumologic.admin
}

#Provides a way to configure permissions on a content to share it with a user, a role, or the entire org
resource "sumologic_content_permission" "share_personal_root_apps_folder_with_org" {
  count                = (var.share_apps_folder_with_org && !local.is_adminMode) ? 1 : 0
  content_id           = sumologic_folder.personal_root_apps_folder[count.index].id
  notify_recipient     = false
  notification_message = "You now have the permission to access this content"
  permission {
    permission_name = "View"
    source_type     = "org"
    source_id       = var.sumologic_organization_id
  }
}


# Create a folder to install all monitors.
resource "sumologic_monitor_folder" "root_monitor_folder" {
  name        = "${var.monitors_folder_name} - ${local.solution_version}"
  description = "This folder contains all the monitors for Application Component Solution."
}
