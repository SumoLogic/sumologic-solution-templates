resource "sumologic_monitor_folder" "cassandra_monitor_folder" {
  depends_on = [sumologic_field.db_cluster,sumologic_field.db_system, sumologic_field.db_cluster_address,sumologic_field.db_cluster_port]
  count      = contains(local.database_engines_values, "cassandra") ? 1 : 0
  name = var.cassandra_monitor_folder
  description = "Folder for Cassandra Monitors"
  parent_id = sumologic_monitor_folder.root_monitor_folder.id
}

module "Cassandra-CompactionTaskPending" {
  count      = contains(local.database_engines_values, "cassandra") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Cassandra - Compaction Task Pending"
  monitor_description         = "This alert fires when there are more than 15 Commitlog tasks which are pending."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.cassandra_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.cassandra_data_source} metric=cassandra_TableMetrics_* name=pendingcompactionss db_cluster=* db_system=cassandra | avg by db_cluster, host"
  }
  triggers = [
			  {
				threshold_type = "GreaterThan",
				threshold = 100,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Warning",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThanOrEqual",
				threshold = 100,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedWarning",
				detection_method = "StaticCondition"
			  }
			]
}
module "Cassandra-NodeDown" {
  count      = contains(local.database_engines_values, "cassandra") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Cassandra - Node Down"
  monitor_description         = "This alert fires when one or more Cassandra nodes are down"
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.cassandra_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.cassandra_data_source} metric=cassandra_Net_FailureDetector_DownEndpointCount db_cluster=* db_system=cassandra | sum by db_cluster, host"
  }
  triggers = [
			  {
				threshold_type = "GreaterThan",
				threshold = 0,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThanOrEqual",
				threshold = 0,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
module "Cassandra-CacheHitRatebelow85Percent" {
  count      = contains(local.database_engines_values, "cassandra") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Cassandra - Cache Hit Rate below 85 Percent"
  monitor_description         = "This alert fires when the cache key hit rate is below 85%."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.cassandra_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.cassandra_data_source} metric=cassandra_TableMetrics_KeyCacheHitRate_Value name=keycachehitrate db_cluster=* db_system=cassandra | sum by db_cluster,host,keyspace,scope | eval _value*100"
  }
  triggers = [
			  {
				threshold_type = "LessThan",
				threshold = 85,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "GreaterThanOrEqual",
				threshold = 85,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
module "Cassandra-RepairTasksPending" {
  count      = contains(local.database_engines_values, "cassandra") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Cassandra - Repair Tasks Pending"
  monitor_description         = "This alert fires when repair tasks are pending."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.cassandra_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.cassandra_data_source} metric=cassandra_ThreadPoolMetrics_internal_Value name=pendingtasks scope=antientropystage db_cluster=* db_system=cassandra | sum by db_cluster, host"
  }
  triggers = [
			  {
				threshold_type = "GreaterThan",
				threshold = 2,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Warning",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThanOrEqual",
				threshold = 2,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedWarning",
				detection_method = "StaticCondition"
			  }
			]
}
module "Cassandra-HighTombstoneScanning" {
  count      = contains(local.database_engines_values, "cassandra") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Cassandra - High Tombstone Scanning"
  monitor_description         = "This alert fires when tombstone scanning is very high (>1000 99th Percentile) in queries."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.cassandra_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_critical
  email_notifications       = var.email_notifications_critical
  queries = {
    A = "${var.cassandra_data_source} metric=cassandra_TableMetrics_TombstoneScannedHistogram_99thPercentile name=tombstonescannedhistogram db_cluster=* db_system=cassandra | sum by db_cluster, hosst"
  }
  triggers = [
			  {
				threshold_type = "GreaterThan",
				threshold = 1000,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Critical",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThanOrEqual",
				threshold = 1000,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedCritical",
				detection_method = "StaticCondition"
			  }
			]
}
module "Cassandra-IncreaseinAuthenticationFailures" {
  count      = contains(local.database_engines_values, "cassandra") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Cassandra - Increase in Authentication Failures"
  monitor_description         = "This alert fires when there is an increase of Cassandra authentication failures."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.cassandra_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.cassandra_data_source} metric=cassandra_ClientMetrics_AuthFailure_Count db_cluster=* db_system=cassandra | sum by db_cluster, host"
  }
  triggers = [
			  {
				threshold_type = "GreaterThan",
				threshold = 5,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Warning",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThanOrEqual",
				threshold = 5,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedWarning",
				detection_method = "StaticCondition"
			  }
			]
}
module "Cassandra-HighNumberofFlushWriterBlockedTasks" {
  count      = contains(local.database_engines_values, "cassandra") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Cassandra - High Number of Flush Writer Blocked Tasks"
  monitor_description         = "This alert fires when there are high number of flush writer tasks which are blocked."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.cassandra_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.cassandra_data_source} metric=cassandra_ThreadPoolMetrics_* scope=memtableflushwriter name=totalblockedtasks db_cluster=* db_system=cassandra | sum by db_cluster,host"
  }
  triggers = [
			  {
				threshold_type = "GreaterThan",
				threshold = 15,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Warning",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThanOrEqual",
				threshold = 15,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedWarning",
				detection_method = "StaticCondition"
			  }
			]
}
module "Cassandra-HighNumberofCompactionExecutorBlockedTasks" {
  count      = contains(local.database_engines_values, "cassandra") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Cassandra - High Number of Compaction Executor Blocked Tasks"
  monitor_description         = "This alert fires when there are more than 15 compaction executor tasks blocked for more than 5 minutes."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.cassandra_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.cassandra_data_source} metric=cassandra_ThreadPoolMetrics_* scope=compactionexecutor name=currentlyblockedtasks db_cluster=* db_system=cassandra | sum by db_cluster, host"
  }
  triggers = [
			  {
				threshold_type = "GreaterThan",
				threshold = 15,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Warning",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThanOrEqual",
				threshold = 15,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedWarning",
				detection_method = "StaticCondition"
			  }
			]
}
module "Cassandra-BlockedRepairTasks" {
  count      = contains(local.database_engines_values, "cassandra") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Cassandra - Blocked Repair Tasks"
  monitor_description         = "This alert fires when the repair tasks are blocked"
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.cassandra_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.cassandra_data_source} metric=cassandra_ThreadPoolMetrics_internal_Value name=pendingtasks scope=currentlyblockedtasks db_cluster=* db_system=cassandra | sum by db_cluster,host"
  }
  triggers = [
			  {
				threshold_type = "GreaterThan",
				threshold = 2,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Warning",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThanOrEqual",
				threshold = 2,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedWarning",
				detection_method = "StaticCondition"
			  }
			]
}
module "Cassandra-HighCommitlogPendingTasks" {
  count      = contains(local.database_engines_values, "cassandra") ? 1 : 0
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "Cassandra - High Commitlog Pending Tasks"
  monitor_description         = "This alert fires when there are more than 15 commitlog tasks which are pending."
  monitor_monitor_type        = "Metrics"
  monitor_parent_id           = sumologic_monitor_folder.cassandra_monitor_folder[count.index].id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  queries = {
    A = "${var.cassandra_data_source} metric=cassandra_CommitLogMetrics_PendingTasks_Value db_cluster=* db_system=cassandra | sum by db_cluster, host"
  }
  triggers = [
			  {
				threshold_type = "GreaterThan",
				threshold = 15,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "Warning",
				detection_method = "StaticCondition"
			  },
			  {
				threshold_type = "LessThanOrEqual",
				threshold = 15,
				time_range = "5m",
				occurrence_type = "Always"
				trigger_source = "AnyTimeSeries"
				trigger_type = "ResolvedWarning",
				detection_method = "StaticCondition"
			  }
			]
}
