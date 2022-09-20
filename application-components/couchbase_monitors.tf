resource "sumologic_monitor_folder" "couchbase_monitor_folder" {
  depends_on  = [sumologic_field.db_cluster, sumologic_field.db_system, sumologic_field.db_cluster_address, sumologic_field.db_cluster_port]
  count       = contains(local.all_components_values, "couchbase") ? 1 : 0
  name        = var.couchbase_monitor_folder
  description = "Folder for Couchbase Monitors"
  parent_id   = sumologic_monitor_folder.root_monitor_folder.id
}

module "Couchbase-HighMemoryUsage" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "couchbase") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Couchbase - High Memory Usage"
  monitor_description      = "This alert fires when memory usage on a node in a Couchbase cluster is high."
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.couchbase_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.couchbase_data_source} metric=couchbase_node_memory_free db_cluster=* host=* | avg by db_cluster,host"
    B = "${var.couchbase_data_source} metric=couchbase_node_memory_total db_cluster=* host=* | avg by db_cluster,host"
    C = "(1-#A/#B)*100 along db_cluster,host"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "MetricsStaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "MetricsStaticCondition"
    }
  ]
}
module "Couchbase-TooManyLoginFailures" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "couchbase") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Couchbase - Too Many Login Failures"
  monitor_description      = "This alert fires when there are too many login failures to a node in a Couchbase cluster."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.couchbase_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.couchbase_data_source} db_cluster=* db_system=\"couchbase\"  \"login failure\" | json \"log\" as _rawlog nodrop | if(isEmpty(_rawlog),_raw,_rawlog) as _raw | json \"name\" as event_name | where event_name=\"login failure\" | json \"remote.ip\" as client_ip  | json \"local.ip\" as couchbase_server | count as count by db_cluster, couchbase_server"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 1000,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Critical",
      detection_method = "LogsStaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 1000,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedCritical",
      detection_method = "LogsStaticCondition"
    }
  ]
}
module "Couchbase-HighCPUUsage" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "couchbase") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Couchbase - High CPU Usage"
  monitor_description      = "This alert fires when CPU usage on a node in a Couchbase cluster is high."
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.couchbase_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.couchbase_data_source} metric=couchbase_bucket_cpu_utilization_rate db_cluster=* host=* | avg by db_cluster,host"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "MetricsStaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "MetricsStaticCondition"
    }
  ]
}
module "Couchbase-NodeDown" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "couchbase") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Couchbase - Node Down"
  monitor_description      = "This alert fires when a node in the Couchbase cluster is down."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.couchbase_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.couchbase_data_source} db_cluster=* db_system=\"couchbase\" \"error\" \"nodedown\" | json \"log\" as _rawlog nodrop | if(isEmpty(_rawlog),_raw,_rawlog) as _raw | if (isEmpty(pod),_sourceHost,pod) as host |replace (_raw,/\\s+/,\" \") as _raw |parse regex \"nodedown,\\s'\\S+@(?<node>\\S+)\\'\" | parse regex \"ns_server:error,(?<time>\\S+),\" |_raw as msg  | fields db_cluster,node"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Critical",
      detection_method = "LogsStaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedCritical",
      detection_method = "LogsStaticCondition"
    }
  ]
}
module "Couchbase-NodeNotRespond" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "couchbase") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Couchbase - Node Not Respond"
  monitor_description      = "This alert fires when a node in the Couchbase cluster does not respond too many times."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.couchbase_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.couchbase_data_source} db_cluster=* db_system=\"couchbase\" \"error\" \"Some nodes didn't respond\"  | json \"log\" as _rawlog nodrop | if(isEmpty(_rawlog),_raw,_rawlog) as _raw |replace (_raw,/\\s+/,\" \") as _raw | parse regex \"stats:error,(?<time>\\S+),\" | parse regex \"Some nodes didn't respond: \\[(?<temp_nodes>.+)\\]\" | parse regex field=temp_nodes \"\\'(?<node_temp>[^,]+)\\'\" multi | parse regex field=node_temp \"@(?<node>.+)\"| _raw as msg  | count as count by db_cluster,node"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 10,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Critical",
      detection_method = "LogsStaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 10,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedCritical",
      detection_method = "LogsStaticCondition"
    }
  ]
}
module "Couchbase-BucketNotReady" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "couchbase") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Couchbase - Bucket Not Ready"
  monitor_description      = "This alert fires when a bucket in the Couchbase cluster is not ready."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.couchbase_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.couchbase_data_source} db_cluster=* db_system=\"couchbase\" \"buckets became not ready on node\" \"error\" | json \"log\" as _rawlog nodrop | if(isEmpty(_rawlog),_raw,_rawlog) as _raw | if (isEmpty(pod),_sourceHost,pod) as host |replace (_raw,/\\s+/,\" \") as _raw | parse regex \"\\'\\S+@(?<node>\\S+)\\'\\:\\s+\\[(?<buckets>.+)\\],\" | parse regex field=buckets \"\\\"(?<bucket>[^,]+)\\\"\" multi | parse regex \"ns_server:error,(?<time>\\S+),\" | _raw as msg | fields db_cluster,bucket,node"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Critical",
      detection_method = "LogsStaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedCritical",
      detection_method = "LogsStaticCondition"
    }
  ]
}
module "Couchbase-TooManyErrorQueriesonBuckets" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "couchbase") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Couchbase - Too Many Error Queries on Buckets"
  monitor_description      = "This alert fires when there are too many error queries on a bucket in a Couchbase cluster."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.couchbase_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.couchbase_data_source} db_cluster=* db_system=\"couchbase\" (\"ERROR\" or \"Error\") | json \"log\" as _rawlog nodrop | if(isEmpty(_rawlog),_raw,_rawlog) as _raw | if (isEmpty(pod),_sourceHost,pod) as host | parse regex \"_time=(?<time>\\S+)\" | parse regex \"_msg=(?<msg>.+)\" | parse regex field=msg \"Keyspace\\s\\w+:(?<bucket>.+)\\.\" | parse regex field=msg \"Failed to perform (?<method>\\w+)\" |count by db_cluster,host,bucket | fields db_cluster,host,bucket "
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 1000,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Critical",
      detection_method = "LogsStaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 1000,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedCritical",
      detection_method = "LogsStaticCondition"
    }
  ]
}
