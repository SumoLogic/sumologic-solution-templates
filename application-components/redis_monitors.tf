resource "sumologic_monitor_folder" "redis_monitor_folder" {
  depends_on  = [sumologic_field.db_cluster, sumologic_field.db_system, sumologic_field.db_cluster_address, sumologic_field.db_cluster_port]
  count       = contains(local.all_components_values, "redis") ? 1 : 0
  name        = var.redis_monitor_folder
  description = "Folder for Redis Monitors"
  parent_id   = sumologic_monitor_folder.root_monitor_folder.id
  obj_permission {
    subject_type = "org"
    subject_id = var.sumologic_organization_id
    permissions = ["Create", "Read", "Update", "Delete", "Manage"]
  }
}

# Sumo Logic Redis Metric Monitors
module "Redis-HighCPUUsage" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "redis") ? 1 : 0
  #version                  = "{revision}"
  monitor_name         = "Redis - High CPU Usage"
  monitor_description  = "This alert is fired if user and system cpu usage for a host exceeds 80%."
  monitor_monitor_type = "Metrics"
  monitor_parent_id    = sumologic_monitor_folder.redis_monitor_folder[count.index].id
  monitor_is_disabled  = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.redis_data_source} db_system=redis db_cluster=* metric=redis_used_cpu_sys | quantize 1m | rate | sum by host, db_cluster"
    B = "${var.redis_data_source} db_system=redis db_cluster=* metric=redis_used_cpu_user | quantize 1m | rate | sum by host, db_cluster"
    C = "#A+#B"
  }

  # Triggers
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]

  # Notifications
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
}

module "Redis-OutOfMemory" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "redis") ? 1 : 0
  #version                  = "{revision}"
  monitor_name         = "Redis - Out Of Memory"
  monitor_description  = "This alert fires when we detect that a Redis node is running out of memory (Memory Usage > 90%)."
  monitor_monitor_type = "Metrics"
  monitor_parent_id    = sumologic_monitor_folder.redis_monitor_folder[count.index].id
  monitor_is_disabled  = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.redis_data_source} db_system=redis db_cluster=* metric=redis_used_memory"
    B = "${var.redis_data_source} db_system=redis db_cluster=* metric=redis_total_system_memory"
    C = "(#A/#B)*100"
  }

  # Triggers
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 90,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 90,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]

  # Notifications
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
}

module "Redis-Instancedown" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "redis") ? 1 : 0
  #version                  = "{revision}"
  monitor_name         = "Redis - Instance Down"
  monitor_description  = "This alert fires when we detect that the Redis instance is down for 5 minutes."
  monitor_monitor_type = "Metrics"
  monitor_parent_id    = sumologic_monitor_folder.redis_monitor_folder[count.index].id
  monitor_is_disabled  = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.redis_data_source} db_system=redis db_cluster=* metric=redis_uptime"
  }

  # Triggers
  triggers = [
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "MissingData"   # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "MissingData",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "MissingData"
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "ResolvedMissingData",
      detection_method = "StaticCondition"
    }
  ]

  # Notifications
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_missingdata
  email_notifications      = var.email_notifications_missingdata
}

module "Redis-Master-SlaveIO" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "redis") ? 1 : 0
  #version                  = "{revision}"
  monitor_name         = "Redis - Potential Master-Slave Communication Failure"
  monitor_description  = "This alert fires when we detect that communication between the Redis master and slave nodes has not occurred for the past 60 seconds or more."
  monitor_monitor_type = "Metrics"
  monitor_parent_id    = sumologic_monitor_folder.redis_monitor_folder[count.index].id
  monitor_is_disabled  = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.redis_data_source} db_system=redis db_cluster=* metric=redis_master_last_io_seconds_ago"
  }

  # Triggers
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 60,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 60,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    }
  ]

  # Notifications
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
}

module "Redis-MemFragmentationRatioHigherthan" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "redis") ? 1 : 0
  #version                  = "{revision}"
  monitor_name         = "Redis - High Memory Fragmentation Ratio"
  monitor_description  = "This alert fires when the ration of Redis memory usage to Linux virtual memory pages (mapped to physical memory chunks) is higher than 1.5. A high ratio will lead to swapping and can adversely affect performance."
  monitor_monitor_type = "Metrics"
  monitor_parent_id    = sumologic_monitor_folder.redis_monitor_folder[count.index].id
  monitor_is_disabled  = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.redis_data_source} db_system=redis db_cluster=* metric=redis_mem_fragmentation_ratio"
  }

  # Triggers
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 1.5,
      time_range       = "15m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 1.5,
      time_range       = "15m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    }
  ]

  # Notifications
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
}


module "Redis-MissingMaster" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "redis") ? 1 : 0
  #version                  = "{revision}"
  monitor_name         = "Redis - Missing Master"
  monitor_description  = "This alert fires when we detect that a Redis cluster has no node marked as master for 5 minutes."
  monitor_monitor_type = "Metrics"
  monitor_parent_id    = sumologic_monitor_folder.redis_monitor_folder[count.index].id
  monitor_is_disabled  = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.redis_data_source} db_system=redis db_cluster=* metric=redis_uptime (replication_role=master or role=master) | count by db_cluster"
  }

  # Triggers
  triggers = [
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "AtLeastOnce"   # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]

  # Notifications
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
}
module "Redis-RejectedConnections" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "redis") ? 1 : 0
  #version                  = "{revision}"
  monitor_name         = "Redis - Rejected Connections"
  monitor_description  = "This alert fires when we detect that some connections to a Redis cluster have been rejected."
  monitor_monitor_type = "Metrics"
  monitor_parent_id    = sumologic_monitor_folder.redis_monitor_folder[count.index].id
  monitor_is_disabled  = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.redis_data_source} db_system=redis db_cluster=*  metric=redis_rejected_connections | quantize 1m | delta"
  }

  # Triggers
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "AtLeastOnce"   # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]

  # Notifications
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
}

module "Redis-ReplicaLag" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "redis") ? 1 : 0
  #version                  = "{revision}"
  monitor_name         = "Redis - Replica Lag"
  monitor_description  = "This alert fires when we detect that the replica lag for a given Redis cluster is greater than 60 seconds. Please review how replication has been configured."
  monitor_monitor_type = "Metrics"
  monitor_parent_id    = sumologic_monitor_folder.redis_monitor_folder[count.index].id
  monitor_is_disabled  = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.redis_data_source} db_system=redis db_cluster=* metric=redis_replication_lag"
  }

  # Triggers
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 60,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 60,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    }
  ]

  # Notifications
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
}

module "Redis-ReplicationBroken" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "redis") ? 1 : 0
  #version                  = "{revision}"
  monitor_name         = "Redis - Replication Broken"
  monitor_description  = "This alert fires when we detect that a Redis instance has lost all slaves. This will affect the redundancy of data stored in Redis. Please review how replication has been configured."
  monitor_monitor_type = "Metrics"
  monitor_parent_id    = sumologic_monitor_folder.redis_monitor_folder[count.index].id
  monitor_is_disabled  = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.redis_data_source} db_system=redis db_cluster=* metric=redis_connected_slaves | quantize 1m | delta"
  }

  # Triggers
  triggers = [
    {
      threshold_type   = "LessThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]

  # Notifications
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
}

module "Redis-ReplicationOffset" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "redis") ? 1 : 0
  #version                  = "{revision}"
  monitor_name         = "Redis - Replication Offset"
  monitor_description  = "This alert fires when the replication offset in a given Redis cluster is greater than 1 MB for last five minutes. Please review how replication has been configured."
  monitor_monitor_type = "Metrics"
  monitor_parent_id    = sumologic_monitor_folder.redis_monitor_folder[count.index].id
  monitor_is_disabled  = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.redis_data_source} db_system=redis db_cluster=* metric=redis_replication_offset | eval _value/1000000"
  }

  # Triggers
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 1,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 1,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    }
  ]

  # Notifications
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
}

module "Redis-TooManyConnections" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "redis") ? 1 : 0
  #version                  = "{revision}"
  monitor_name         = "Redis - Too Many Connections"
  monitor_description  = "This alert fires when we detect a given Redis server has too many connections (over 100)."
  monitor_monitor_type = "Metrics"
  monitor_parent_id    = sumologic_monitor_folder.redis_monitor_folder[count.index].id
  monitor_is_disabled  = var.monitors_disabled

  # Queries - Multiple queries allowed for Metrics monitor
  queries = {
    A = "${var.redis_data_source} db_system=redis db_cluster=*  metric=redis_clients | sum by server,db_cluster"
  }

  # Triggers
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 100,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 100,
      time_range       = "5m",
      occurrence_type  = "Always"        # Options: Always, AtLeastOnce and MissingData for Metrics
      trigger_source   = "AnyTimeSeries" # Options: AllTimeSeries and AnyTimeSeries for Metrics. 'AnyTimeSeries' is the only valid triggerSource for 'Critical' trigger
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    }
  ]

  # Notifications
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
}
