resource "sumologic_monitor_folder" "mongodb_monitor_folder" {
  depends_on  = [sumologic_field.db_cluster, sumologic_field.db_system, sumologic_field.db_cluster_address, sumologic_field.db_cluster_port]
  count       = contains(local.all_components_values, "mongodb") ? 1 : 0
  name        = var.mongodb_monitor_folder
  description = "Folder for MongoDB Monitors"
  parent_id   = sumologic_monitor_folder.root_monitor_folder.id
}

module "MongoDB-TooManyCursorsTimeouts" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "mongodb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "MongoDB - Too Many Cursors Timeouts"
  monitor_description      = "This alert fires when we detect that there are too many cursors (100) timing out on a MongoDB server within a 5 minute time interval."
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.mongodb_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.mongodb_data_source} metric=mongodb_cursor_timed_out db_system=mongodb db_cluster=* | sum by db_cluster, host | rate increasing"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 100,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 100,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    }
  ]
}
module "MongoDB-TooManyCursorsOpen" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "mongodb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "MongoDB - Too Many Cursors Open"
  monitor_description      = "This alert fires when we detect that there are too many cursors (>10K) opened by MongoDB."
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.mongodb_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = concat(var.connection_notifications_warning, var.connection_notifications_missingdata)
  email_notifications      = concat(var.email_notifications_warning, var.email_notifications_missingdata)
  queries = {
    A = "${var.mongodb_data_source} metric=mongodb_cursor_total_count db_system=mongodb db_cluster=* | sum by host, db_cluster"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 10000,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 10000,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "MissingData"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "MissingData",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "MissingData"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedMissingData",
      detection_method = "StaticCondition"
    }
  ]
}
module "MongoDB-MissingPrimary" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "mongodb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "MongoDB - Missing Primary"
  monitor_description      = "This alert fires when we detect that a MongoDB cluster has no node marked as primary."
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.mongodb_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.mongodb_data_source} db_system=mongodb db_cluster=* metric=mongodb_repl_queries node_type=pri | count by db_cluster"
  }
  triggers = [
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "StaticCondition"
    }
  ]
}
module "MongoDB-InstanceDown" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "mongodb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "MongoDB - Instance Down"
  monitor_description      = "This alert fires when we detect that the MongoDB instance is down."
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.mongodb_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_missingdata
  email_notifications      = var.email_notifications_missingdata
  queries = {
    A = "${var.mongodb_data_source} db_system=mongodb db_cluster=* metric=mongodb_uptime_ns "
  }
  triggers = [
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "MissingData"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "MissingData",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "MissingData"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedMissingData",
      detection_method = "StaticCondition"
    }
  ]
}
module "MongoDB-ReplicationLag" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "mongodb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "MongoDB - Replication Lag"
  monitor_description      = "This alert fires when we detect that the replica lag for a given MongoDB cluster is greater than 60 seconds. Please review the replication configuration."
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.mongodb_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.mongodb_data_source}  db_system=mongodb db_cluster=* metric=mongodb_repl_lag "
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 60,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 60,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    }
  ]
}
module "MongoDB-ReplicationHeartbeatError" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "mongodb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "MongoDB - Replication Heartbeat Error"
  monitor_description      = "This alert fires when we detect that the MongoDB Replication Heartbeat request has errors, which indicates replication is not working as expected."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.mongodb_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.mongodb_data_source} db_cluster=* db_system=mongodb | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw  | json field=_raw \"t.$date\" as timestamp | json field=_raw \"s\" as severity | json field=_raw \"c\" as component | json field=_raw \"ctx\" as context | json field=_raw \"msg\" as msg | where component matches \"*REPL*\" | json field=_raw \"attr.heartbeatMessage\" as heartbeatMessage | where heartbeatMessage matches \"Error*\""
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
module "MongoDB-TooManyConnections" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "mongodb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "MongoDB - Too Many Connections"
  monitor_description      = "This alert fires when we detect a given MongoDB server has too many connections (over 80% of capacity)."
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.mongodb_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = concat(var.connection_notifications_warning, var.connection_notifications_missingdata)
  email_notifications      = concat(var.email_notifications_warning, var.email_notifications_missingdata)
  queries = {
    A = "${var.mongodb_data_source}  metric=mongodb_connections_current db_cluster=* db_system=mongodb | sum by db_cluster, host | avg"
    B = "${var.mongodb_data_source}  metric=mongodb_connections_available db_cluster=* db_system=mongodb | sum by db_cluster, host | avg"
    C = "#A*100/#B"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Warning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedWarning",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "MissingData"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "MissingData",
      detection_method = "StaticCondition"
    },
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "MissingData"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedMissingData",
      detection_method = "StaticCondition"
    }
  ]
}
module "MongoDB-SecondaryNodeReplicationFailure" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "mongodb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "MongoDB - Secondary Node Replication Failure"
  monitor_description      = "This alert fires when we detect that a MongoDB secondary node is out of sync for replication."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.mongodb_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.mongodb_data_source} db_cluster=* db_system=mongodb | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw  | json field=_raw \"t.$date\" as timestamp | json field=_raw \"s\" as severity | json field=_raw \"c\" as component | json field=_raw \"ctx\" as context | json field=_raw \"msg\" as msg | where component matches \"*REPL*\" and msg matches \"*too stale*\""
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
module "MongoDB-SlowQueries" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "mongodb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "MongoDB - Slow Queries"
  monitor_description      = "This alert fires when we detect that a MongoDB cluster is executing slow queries."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.mongodb_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.mongodb_data_source}  db_cluster=* db_system=mongodb | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw  | json field=_raw \"t.$date\" as timestamp | json field=_raw \"s\" as severity | json field=_raw \"c\" as component | json field=_raw \"ctx\" as context | json field=_raw \"msg\" as msg | where component matches \"*COMMAND*\" | json field=_raw \"attr.type\" as type | where type matches \"*command*\" | json field=_raw \"attr.command\" as command | replace (command,\"{\",\"\") as command | replace (command,\"}\",\"\") as command | parse regex field=command \"(?<db_cmd>[\\w\\-\\.]+):*\" | where db_cmd matches \"*find*\" or db_cmd matches \"*insert*\" or db_cmd matches \"*remove*\" or db_cmd matches \"*delete*\" or db_cmd matches \"*update*\" | json field=_raw \"attr.durationMillis\" as dur | number(dur) | where dur > 100"
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
module "MongoDB-ShardingWarning" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "mongodb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "MongoDB - Sharding Warning"
  monitor_description      = "This alert fires when we detect warnings in MongoDB sharding operations."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.mongodb_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.mongodb_data_source} db_cluster=* db_system=mongodb | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw  | json field=_raw \"t.$date\" as timestamp | json field=_raw \"s\" as severity | json field=_raw \"c\" as component | json field=_raw \"ctx\" as context | json field=_raw \"msg\" as msg | where component matches \"*SHARDING*\" and severity = \"W\" "
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
module "MongoDB-ShardingChunkSplitFailure" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "mongodb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "MongoDB - Sharding Chunk Split Failure"
  monitor_description      = "This alert fires when we detect that a MongoDB chunk not been split during sharding."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.mongodb_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.mongodb_data_source} db_cluster=* db_system=mongodb | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw  | json field=_raw \"t.$date\" as timestamp | json field=_raw \"s\" as severity | json field=_raw \"c\" as component | json field=_raw \"ctx\" as context | json field=_raw \"msg\" as msg | where component matches \"*SHARDING*\" and severity = \"W\" and msg matches \"*splitChunk failed*\""
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
module "MongoDB-ShardingError" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "mongodb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "MongoDB - Sharding Error"
  monitor_description      = "This alert fires when we detect errors in MongoDB sharding operations."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.mongodb_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.mongodb_data_source} db_cluster=* db_system=mongodb | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw  | json field=_raw \"t.$date\" as timestamp | json field=_raw \"s\" as severity | json field=_raw \"c\" as component | json field=_raw \"ctx\" as context | json field=_raw \"msg\" as msg | where component matches \"*SHARDING*\" and severity = \"E\" "
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
module "MongoDB-ReplicationError" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "mongodb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "MongoDB - Replication Error"
  monitor_description      = "This alert fires when we detect errors in MongoDB replication operations."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.mongodb_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.mongodb_data_source} db_cluster=* db_system=mongodb | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw  | json field=_raw \"t.$date\" as timestamp | json field=_raw \"s\" as severity | json field=_raw \"c\" as component | json field=_raw \"ctx\" as context | json field=_raw \"msg\" as msg | where severity = \"E\" and  component matches \"*REPL*\" "
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
module "MongoDB-ShardingBalancerFailure" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "mongodb") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "MongoDB - Sharding Balancer Failure"
  monitor_description      = "This alert fires when we detect that data balancing failed on a MongoDB Cluster with 1 mongos instance and 3 mongod instances."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.mongodb_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.mongodb_data_source} db_cluster=* db_system=mongodb | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as _raw  | json field=_raw \"t.$date\" as timestamp | json field=_raw \"s\" as severity | json field=_raw \"c\" as component | json field=_raw \"ctx\" as context | json field=_raw \"msg\" as msg | where severity not in  (\"W\", \"E\") and context matches \"*Balancer*\""
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
