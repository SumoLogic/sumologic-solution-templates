
# ********************** Database component Fields ********************** #
resource "sumologic_field" "db_cluster" {
  count      = length(local.all_components_values) > 0 && local.has_any_nonkubernetes_deployments ? 1 : 0
  data_type  = "String"
  field_name = "db_cluster"
  state      = "Enabled"
}

resource "sumologic_field" "db_system" {
  count      = length(local.all_components_values) > 0 && local.has_any_nonkubernetes_deployments ? 1 : 0
  data_type  = "String"
  field_name = "db_system"
  state      = "Enabled"
}


resource "sumologic_field" "db_cluster_address" {
  count      = length(local.all_components_values) > 0 && local.has_any_nonkubernetes_deployments ? 1 : 0
  data_type  = "String"
  field_name = "db_cluster_address"
  state      = "Enabled"
}

resource "sumologic_field" "db_cluster_port" {
  count      = length(local.all_components_values) > 0 && local.has_any_nonkubernetes_deployments ? 1 : 0
  data_type  = "String"
  field_name = "db_cluster_port"
  state      = "Enabled"
}


resource "sumologic_field" "pod_labels_db_cluster" {
  count      = length(local.all_components_values) > 0 && local.has_any_kubernetes_deployments ? 1 : 0
  data_type  = "String"
  field_name = "pod_labels_db_cluster"
  state      = "Enabled"
}

resource "sumologic_field" "pod_labels_db_system" {
  count      = length(local.all_components_values) > 0 && local.has_any_kubernetes_deployments ? 1 : 0
  data_type  = "String"
  field_name = "pod_labels_db_system"
  state      = "Enabled"
}


resource "sumologic_field" "pod_labels_db_cluster_address" {
  count      = length(local.all_components_values) > 0 && local.has_any_kubernetes_deployments ? 1 : 0
  data_type  = "String"
  field_name = "pod_labels_db_cluster_address"
  state      = "Enabled"
}

resource "sumologic_field" "pod_labels_db_cluster_port" {
  count      = length(local.all_components_values) > 0 && local.has_any_kubernetes_deployments ? 1 : 0
  data_type  = "String"
  field_name = "pod_labels_db_cluster_port"
  state      = "Enabled"
}

# ********************** Database component FERs ********************** #

resource "sumologic_field_extraction_rule" "SumoLogicFieldExtractionRulesForDatabase" {
  depends_on       = [sumologic_field.db_cluster, sumologic_field.db_system, sumologic_field.db_cluster_address, sumologic_field.db_cluster_port, sumologic_field.pod_labels_db_cluster, sumologic_field.pod_labels_db_system, sumologic_field.pod_labels_db_cluster_address, sumologic_field.pod_labels_db_cluster_port,sumologic_field.component,sumologic_field.environment, sumologic_field.pod_labels_environment, sumologic_field.pod_labels_component]
  count            = length(local.all_components_values) > 0 && local.has_any_kubernetes_deployments ? 1 : 0
  enabled          = true
  name             = local.database_fer_name
  parse_expression = <<EOT
        if (!isEmpty(pod_labels_environment), pod_labels_environment, "") as environment
        | pod_labels_component as component
        | pod_labels_db_system as db_system
        | pod_labels_db_cluster as db_cluster
    EOT
  scope            = "pod_labels_environment=* pod_labels_component=database pod_labels_db_system=* pod_labels_db_cluster=*"
}
