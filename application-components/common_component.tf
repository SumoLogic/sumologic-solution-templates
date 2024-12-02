# ********************** Fields ********************** #
resource "sumologic_field" "component" {
  data_type  = "String"
  field_name = "component"
  state      = "Enabled"
}

resource "sumologic_field" "environment" {
  data_type  = "String"
  field_name = "environment"
  state      = "Enabled"
}


resource "sumologic_field" "pod_labels_environment" {
  count      = length(local.all_components_values) > 0 && local.has_any_kubernetes_deployments ? 1 : 0
  data_type  = "String"
  field_name = "pod_labels_environment"
  state      = "Enabled"
}


resource "sumologic_field" "pod_labels_component" {
  count      = length(local.all_components_values) > 0 && local.has_any_kubernetes_deployments ? 1 : 0
  data_type  = "String"
  field_name = "pod_labels_component"
  state      = "Enabled"
}

# ********************** Application Components App ********************** #
locals {
  application_component_app_id          = "22aa033e-5a36-4a20-b07d-810096e18050"
  application_component_app_name        = "Application Components"
  application_component_app_description = "This folder is created by Terraform.DO NOT DELETE."
}
resource "null_resource" "install_app_component_app" {
  triggers = {
    api_endpoint     = local.sumologic_api_endpoint
    organization     = var.sumologic_organization_id
    solution_version = local.solution_version
    root_folder_id   = local.parent_folder_id
  }
  depends_on = [
    sumologic_folder.admin_root_apps_folder,
    sumologic_folder.personal_root_apps_folder
  ]
  provisioner "local-exec" {
    command = <<EOT
      curl -s --request POST '${local.sumologic_api_endpoint}/v1/apps/${local.application_component_app_id}/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            --header 'isAdminMode: ${local.is_adminMode}' \
            -u ${var.sumologic_access_id}:${var.sumologic_access_key} \
          --data-raw '{ "name": "${local.application_component_app_name}", "description": "${local.application_component_app_description}", "destinationFolderId": "${local.parent_folder_id}"}}'
    EOT
  }
}

# ********************** Explore Hierarchy ********************** #
resource "sumologic_hierarchy" "application_component_view" {
  name = local.hierarchy_name
  filter {
    key   = "component"
    value = "database"
  }
  level {
    entity_type = "environment"
    next_level {
      entity_type = "component"
      next_levels_with_conditions {
        condition = "database"
        level {
          entity_type = "db_system"
          next_levels_with_conditions {
            condition = "mysql"
            level {
              entity_type = "db_cluster"
              next_level {
                entity_type = "schema"
                next_level {
                  entity_type = "table"
                }
              }
            }
          }
          next_levels_with_conditions {
            condition = "postgresql"
            level {
              entity_type = "db_cluster"
              next_level {
                entity_type = "db"
                next_level {
                  entity_type = "schemaname"
                  next_level {
                    entity_type = "relname"
                  }
                }
              }
            }
          }
          next_levels_with_conditions {
            condition = "cassandra"
            level {
              entity_type = "db_cluster"
              next_level {
                entity_type = "keyspace"
              }
            }
          }
          next_levels_with_conditions {
            condition = "mariadb"
            level {
              entity_type = "db_cluster"
              next_level {
                entity_type = "schema"
                next_level {
                  entity_type = "table"

                }
              }
            }
          }
          next_levels_with_conditions {
            condition = "couchbase"
            level {
              entity_type = "db_cluster"
              next_level {
                entity_type = "bucket"
              }
            }
          }
          next_levels_with_conditions {
            condition = "oracle"
            level {
              entity_type = "db_cluster"
              next_level {
                entity_type = "instance"
              }
            }
          }
          next_levels_with_conditions {
            condition = "sqlserver"
            level {
              entity_type = "db_cluster"
              next_level {
                entity_type = "database_name"
              }
            }
          }
          next_level {
            entity_type = "db_cluster"
          }
        }
      }
    }
  }
}

