resource "sumologic_monitor_folder" "elasticsearch_monitor_folder" {
  depends_on  = [sumologic_field.db_cluster, sumologic_field.db_system, sumologic_field.db_cluster_address, sumologic_field.db_cluster_port]
  count       = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  name        = var.elasticsearch_monitor_folder
  description = "Folder for Elasticsearch Monitors"
  parent_id   = sumologic_monitor_folder.root_monitor_folder.id
  obj_permission {
    subject_type = "org"
    subject_id = var.sumologic_organization_id
    permissions = ["Create", "Read", "Update", "Delete", "Manage"]
  }
}

module "Elasticsearch-QueryTimeTooSlow" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Query Time Too Slow"
  monitor_description      = "Alert Slow Query Too High (10 ms)"
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.elasticsearch_data_source} db_system=elasticsearch db_cluster=* took_millis | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw | json field=_raw \"timestamp\" as timestamp | json field=_raw \"level\" as level | json field=_raw \"component\" as component | json field=_raw \"message\" as message | where level = \"WARN\" and message matches \"*took_millis*\" | json field=_raw \"type\" as type | parse regex field=message \"took_millis\\[(?<took_millis>[\\d-]+)\\]\" | where number(took_millis) > 10 | fields took_millis"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]
}
module "Elasticsearch-QueryTimeSlow" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Query Time Slow"
  monitor_description      = "Slow query time greater than 5 ms"
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.elasticsearch_data_source} db_system=elasticsearch db_cluster=* took_millis | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw | json field=_raw \"timestamp\" as timestamp | json field=_raw \"level\" as level | json field=_raw \"component\" as component | json field=_raw \"message\" as message | where level = \"WARN\" and message matches \"*took_millis*\" | json field=_raw \"type\" as type | parse regex field=message \"took_millis\\[(?<took_millis>[\\d-]+)\\]\" | where number(took_millis) > 5 | fields took_millis"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    }
  ]
}
module "Elasticsearch-ClusterRed" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Cluster Red"
  monitor_description      = "Elasticsearch Cluster Red status"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.elasticsearch_data_source} metric=elasticsearch_cluster_health_indices_status_code  db_cluster=* | min by db_cluster"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 3,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 3,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]
}
module "Elasticsearch-InitializingShardsTooLong" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Initializing Shards Too Long"
  monitor_description      = "Elasticsearch has been initializing shards for 5 min"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.elasticsearch_data_source} metric=elasticsearch_cluster_health_initializing_shards db_cluster=* host=* | sum by db_cluster"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]
}
module "Elasticsearch-ClusterYellow" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Cluster Yellow"
  monitor_description      = "Elasticsearch Cluster Yellow status"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.elasticsearch_data_source} metric=elasticsearch_cluster_health_indices_status_code  db_cluster=* host=* | min by db_cluster, host"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 2,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 2,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    }
  ]
}
module "Elasticsearch-RelocatingShardsTooLong" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Relocating Shards Too Long"
  monitor_description      = "Elasticsearch has been relocating shards for 5min"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.elasticsearch_data_source} metric=elasticsearch_cluster_health_relocating_shards db_cluster=* host=* | sum by db_cluster"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    }
  ]
}
module "Elasticsearch-UnassignedShards" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Unassigned Shards"
  monitor_description      = "Elasticsearch has unassigned shards"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.elasticsearch_data_source} metric=elasticsearch_cluster_health_unassigned_shards db_cluster=* host=* | sum by db_cluster,host"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]
}
module "Elasticsearch-HeapUsageWarning" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Heap Usage Warning"
  monitor_description      = "The heap usage is over 80%"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.elasticsearch_data_source} metric=elasticsearch_clusterstats_nodes_jvm_mem_heap_used_in_bytes db_cluster=* host=* | sum by db_cluster, host"
    B = "${var.elasticsearch_data_source}  metric=elasticsearch_clusterstats_nodes_jvm_mem_heap_used_in_bytes db_cluster=* host=* | sum by db_cluster, host"
    C = "#A*100/#B along db_cluster, host"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]
}
module "Elasticsearch-ErrorLogTooMany" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Error Log Too Many"
  monitor_description      = "Error Log Too Many"
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.elasticsearch_data_source} db_system=elasticsearch db_cluster=* ERROR | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw | json field=_raw \"timestamp\" as timestamp | json field=_raw \"level\" as level | json field=_raw \"component\" as component | json field=_raw \"message\" as message | where level = \"ERROR\" | fields level,message"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 1000,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 1000,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]
}
module "Elasticsearch-PendingTasks" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Pending Tasks"
  monitor_description      = "Elasticsearch has pending tasks. Cluster works slowly."
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.elasticsearch_data_source} metric=elasticsearch_cluster_health_number_of_pending_tasks db_cluster=* | sum by db_cluster"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]
}
module "Elasticsearch-HeapUsageTooHigh" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Heap Usage Too High"
  monitor_description      = "The heap usage is over 90%"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.elasticsearch_data_source} metric=elasticsearch_clusterstats_nodes_jvm_mem_heap_used_in_bytes db_cluster=* host=* | sum by db_cluster, host"
    B = "${var.elasticsearch_data_source}  metric=elasticsearch_clusterstats_nodes_jvm_mem_heap_used_in_bytes db_cluster=* host=* | sum by db_cluster, host"
    C = "#A*100/#B along db_cluster, host"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 90,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 90,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]
}
module "Elasticsearch-TooManySlowQuery" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Too Many Slow Query"
  monitor_description      = "Alert Too Many Slow Query in 5 minutes"
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.elasticsearch_data_source} db_system=elasticsearch db_cluster=* took_millis | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw | json field=_raw \"timestamp\" as timestamp | json field=_raw \"level\" as level | json field=_raw \"component\" as component | json field=_raw \"message\" as message | where level = \"WARN\" and message matches \"*took_millis*\" | fields level,message"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 100,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 100,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]
}
module "Elasticsearch-HealthyDataNodes" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Healthy Data Nodes"
  monitor_description      = "Missing data node in Elasticsearch cluster"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.elasticsearch_data_source} metric=elasticsearch_cluster_health_number_of_data_nodes db_cluster=* host=*| min by db_cluster, host"
  }
  triggers = [
    {
      threshold_type   = "LessThan",
      threshold        = 3,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 3,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]
}
module "Elasticsearch-HealthyNodes" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Healthy Nodes"
  monitor_description      = "Missing node in Elasticsearch cluster"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.elasticsearch_data_source} metric=elasticsearch_cluster_health_number_of_nodes db_cluster=* host=* | min by db_cluster, host"
  }
  triggers = [
    {
      threshold_type   = "LessThan",
      threshold        = 3,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 3,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]
}
module "Elasticsearch-DiskSpaceLow" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Disk Space Low"
  monitor_description      = "The disk usage is over 80%"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.elasticsearch_data_source} metric=elasticsearch_fs_total_free_in_bytes db_cluster=* host=* | sum by db_cluster, host"
    B = "${var.elasticsearch_data_source} metric=elasticsearch_fs_total_total_in_bytes db_cluster=* host=* | sum by db_cluster, host"
    C = "(1-(#A/#B))*100 along db_cluster,host"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]
}
module "Elasticsearch-DiskOutofSpace" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "elasticsearch") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Elasticsearch - Disk Out of Space"
  monitor_description      = "The disk usage is over 90%"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.elasticsearch_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.elasticsearch_data_source} metric=elasticsearch_fs_total_free_in_bytes db_cluster=* host=* | sum by db_cluster, host"
    B = "${var.elasticsearch_data_source} metric=elasticsearch_fs_total_total_in_bytes db_cluster=* host=* | sum by db_cluster, host"
    C = "(1-(#A/#B))*100 along db_cluster,host"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 90,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 90,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]
}
