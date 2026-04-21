resource "sumologic_monitor_folder" "oracle_monitor_folder" {
  depends_on  = [sumologic_field.db_cluster, sumologic_field.db_system, sumologic_field.db_cluster_address, sumologic_field.db_cluster_port]
  count       = contains(local.all_components_values, "oracle") ? 1 : 0
  name        = var.oracle_monitor_folder
  description = "Folder for Oracle Monitors"
  parent_id   = sumologic_monitor_folder.root_monitor_folder.id
  obj_permission {
    subject_type = "org"
    subject_id = var.sumologic_organization_id
    permissions = ["Create", "Read", "Update", "Delete", "Manage"]
  }
}

module "Oracle-HighCPUUsage" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - High CPU Usage"
  monitor_description      = "This alert fires when CPU usage on a node in a Oracle cluster is high."
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_system=oracle metric_name=\"host_cpu_utilization_(%)\" db_cluster=* host=* | sum by db_cluster,host,instance"
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
module "Oracle-DatabaseCrash" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Database Crash"
  monitor_description      = "This alert fires when the database crashes."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_cluster=* db_system=oracle (\"ORA-00603\" or \"ORA-00449\" or \"ORA-00471\" or \"ORA-01092\") | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as oracle_log_message | parse regex field=oracle_log_message \"(?<oraerr>ORA-\\d{5}): (?<oramsg>.*)\" multi | where oraerr in (\"ORA-00603\", \"ORA-00449\", \"ORA-00471\", \"ORA-01092\") | if (isEmpty(pod),_sourceHost,pod) as host | fields db_cluster,host,oraerr,oramsg"
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
module "Oracle-Deadlock" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Deadlock"
  monitor_description      = "This alert fires when deadlocks are detected."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.oracle_data_source} db_cluster=* db_system=oracle \"ORA-00060\" | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as oracle_log_message | parse regex field=oracle_log_message \"(?<oraerr>ORA-\\d{5}): (?<oramsg>.*)\" multi | where oraerr = \"ORA-00060\" | if (isEmpty(pod),_sourceHost,pod) as host | fields db_cluster,host,oraerr,oramsg"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 5,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Warning",
      detection_method = "LogsStaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 5,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedWarning",
      detection_method = "LogsStaticCondition"
    }
  ]
}
module "Oracle-TablespacesSpaceLow" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Tablespaces Space Low"
  monitor_description      = "This alert fires when tablespace disk usage is over 80%"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.oracle_data_source} db_system=oracle metric=oracle_tablespaces_percent_used db_cluster=* host=* | sum by db_cluster,host,instance,tbs_name"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Warning",
      detection_method = "MetricsStaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedWarning",
      detection_method = "MetricsStaticCondition"
    }
  ]
}
module "Oracle-ProcessLimitCritical" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Process Limit Critical"
  monitor_description      = "This alert fires when process CPU utilization is over 90%"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_system=oracle metric_name=process_limit_% metric=oracle_sysmetric_metric_value db_cluster=* host=* | sum by db_cluster,host,instance"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 90,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "MetricsStaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 90,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "MetricsStaticCondition"
    }
  ]
}
module "Oracle-SessionCritical" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Session Critical"
  monitor_description      = "This alert fires when session usage is over 97%"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_system=oracle metric_name=session_limit_% metric=oracle_sysmetric_metric_value db_cluster=* host=* | sum by db_cluster,host,instance"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 97,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "MetricsStaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 97,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "MetricsStaticCondition"
    }
  ]
}
module "Oracle-InternalErrors" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Internal Errors"
  monitor_description      = "This alert fires when internal errors are detected."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.oracle_data_source} db_cluster=* db_system=oracle (\"ORA-00600\" or \"ORA-07445\") | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as oracle_log_message | parse regex field=oracle_log_message \"(?<oraerr>ORA-\\d{5}): (?<oramsg>.*)\" multi | where oraerr in (\"ORA-00600\", \"ORA-07445\") | if (isEmpty(pod),_sourceHost,pod) as host | fields db_cluster,host,oraerr,oramsg"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Warning",
      detection_method = "LogsStaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedWarning",
      detection_method = "LogsStaticCondition"
    }
  ]
}
module "Oracle-TNSError" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - TNS Error"
  monitor_description      = "This alert fires when we detect TNS operations errors."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_cluster=* db_system=oracle TNS-* | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as oracle_log_message | parse regex field=oracle_log_message \"(?<TNSerr>TNS-\\d{5}): (?<tnsmsg>.*)\" multi | if (isEmpty(pod),_sourceHost,pod) as host | fields db_cluster,host,TNSerr,tnsmsg"
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
module "Oracle-SessionWarning" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Session Warning"
  monitor_description      = "This alert fires when session usage is over 90%"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_warning
  email_notifications      = var.email_notifications_warning
  queries = {
    A = "${var.oracle_data_source} db_system=oracle metric_name=session_limit_% metric=oracle_sysmetric_metric_value db_cluster=* host=* | sum by db_cluster,host,instance"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 90,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Warning",
      detection_method = "MetricsStaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 90,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedWarning",
      detection_method = "MetricsStaticCondition"
    }
  ]
}
module "Oracle-UnauthorizedCommandExecution" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Unauthorized Command Execution"
  monitor_description      = "This alert fires when we detect that a user is not authorized to execute a requested listener command in a Oracle instance."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_cluster=* db_system=oracle \"TNS-01190\" or \"The user is not authorized to execute the requested listener command\" | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as oracle_log_message | parse regex field=oracle_log_message \"(?<TNSerr>TNS-\\d{5}): (?<tnsmsg>.*)\" nodrop | if (isEmpty(pod),_sourceHost,pod) as host | fields db_cluster,host,TNSerr, tnsmsg "
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Warning",
      detection_method = "LogsStaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedWarning",
      detection_method = "LogsStaticCondition"
    }
  ]
}
module "Oracle-PossibleInappropriateActivity" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Possible Inappropriate Activity"
  monitor_description      = "This alert fires when we detect possible inappropriate activity."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_cluster=* db_system=oracle (\"TNS-01169\" or \"TNS-01189\" or \"TNS-01190\" or \"TNS-12508\") or (\"ORA-12525\" or \"ORA-28040\" or \"ORA-12170\") | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as oracle_log_message | parse regex field=oracle_log_message \"(?<TNSerr>TNS-\\d{5}): (?<tnsmsg>.*)\" nodrop | parse regex field=oracle_log_message \"(?<oraerr>ORA-\\d{5}): (?<oramsg>.*)\" multi nodrop | where (TNSerr in (\"TNS-01169\", \"TNS-01189\", \"TNS-01190\", \"TNS-12508\")) or (oraerr in (\"ORA-12525\", \"ORA-28040\", \"ORA-12170\")) | if (isEmpty(pod),_sourceHost,pod) as host | count as eventCount by db_cluster,host "
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Warning",
      detection_method = "LogsStaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedWarning",
      detection_method = "LogsStaticCondition"
    }
  ]
}
module "Oracle-TablespacesOutofSpace" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Tablespaces Out of Space"
  monitor_description      = "This alert fires when tablespace disk usage is over 90%"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_system=oracle metric=oracle_tablespaces_percent_used db_cluster=* host=* | sum by db_cluster,host,instance,tbs_name"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 90,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "MetricsStaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 90,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "MetricsStaticCondition"
    }
  ]
}
module "Oracle-BlockCorruption" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Block Corruption"
  monitor_description      = "This alert fires when we detect corrupted data blocks."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_cluster=* db_system=oracle \"ORA-01578\" | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as oracle_log_message | parse regex field=oracle_log_message \"(?<oraerr>ORA-\\d{5}): (?<oramsg>.*)\" multi | where oraerr = \"ORA-01578\" | if (isEmpty(pod),_sourceHost,pod) as host | fields db_cluster,host,oraerr,oramsg"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Warning",
      detection_method = "LogsStaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedWarning",
      detection_method = "LogsStaticCondition"
    }
  ]
}
module "Oracle-UnableToExtendTablespace" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Unable To Extend Tablespace"
  monitor_description      = "This alert fires when we detect that we are unable to extend tablespaces."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_cluster=* db_system=oracle unable to extend by tablespace | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as oracle_log_message | parse regex field=oracle_log_message \"(?<oraerr>ORA-\\d{4,5}): (?<oramsg>.*)\" multi | parse regex field=oramsg \"unable to extend (?<object>[\\S\\s]+?)\\s+by \\d+ in tablespace\\s+(?<tablespace>\\S+)\" | if (isEmpty(pod),_sourceHost,pod) as host | fields db_cluster,host,oraerr, oramsg, object, tablespace "
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Warning",
      detection_method = "LogsStaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedWarning",
      detection_method = "LogsStaticCondition"
    }
  ]
}
module "Oracle-ProcessLimitWarning" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Process Limit Warning"
  monitor_description      = "This alert fires when processes CPU utilization is over 80%"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_system=oracle metric_name=process_limit_% metric=oracle_sysmetric_metric_value db_cluster=* host=* | sum by db_cluster,host,instance"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Warning",
      detection_method = "MetricsStaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedWarning",
      detection_method = "MetricsStaticCondition"
    }
  ]
}
module "Oracle-DatabaseDown" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Database Down"
  monitor_description      = "This alert fires when we detect that the Oracle database is down."
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_system=oracle metric=oracle_status_metric_value metric_name=database_status db_cluster=* | sum by db_cluster,host,instance"
  }
  triggers = [
    {
      threshold_type   = "LessThan",
      threshold        = 1,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "MetricsStaticCondition"
    },
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 1,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "MetricsStaticCondition"
    }
  ]
}
module "Oracle-AdminRestrictedCommandExecution" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Admin Restricted Command Execution"
  monitor_description      = "This alert fires when the Listener could not resolve a command."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_cluster=* db_system=oracle (\"TNS:listener could not resolve the COMMAND given\" or \"TNS-12508\") | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as oracle_log_message | parse regex field=oracle_log_message \"(?<TNSerr>TNS-\\d{5}): (?<tnsmsg>.*)\" nodrop | if (isEmpty(pod),_sourceHost,pod) as host | fields db_cluster,host,TNSerr, tnsmsg "
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Warning",
      detection_method = "LogsStaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedWarning",
      detection_method = "LogsStaticCondition"
    }
  ]
}
module "Oracle-ArchivalLogCreation" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Archival Log Creation"
  monitor_description      = "This alert fires when there is an archive log creation error."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_cluster=* db_system=oracle Thread cannot allocate new log sequence Checkpoint \"not\" complete | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as oracle_log_message | parse regex field=oracle_log_message \"(?<oraerr>ORA-\\d{5}): (?<oramsg>.*)\" multi | where oraerr = \"ORA-00270\" | if (isEmpty(pod),_sourceHost,pod) as host | fields db_cluster,host,oraerr,oramsg"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Warning",
      detection_method = "LogsStaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedWarning",
      detection_method = "LogsStaticCondition"
    }
  ]
}
module "Oracle-UserLimitCritical" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - User Limit Critical"
  monitor_description      = "This alert fires when concurrent user sessions usage is over 90%"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_system=oracle metric_name=user_limit_% metric=oracle_sysmetric_metric_value db_cluster=* host=* | sum by db_cluster,host,instance"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 90,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Critical",
      detection_method = "MetricsStaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 90,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedCritical",
      detection_method = "MetricsStaticCondition"
    }
  ]
}
module "Oracle-LoginFail" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Login Fail"
  monitor_description      = "This alert fires when we detect that a user cannot login."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_cluster=* db_system=oracle establish \"PROGRAM=\" (\"SID=\" or \"SERVICE_NAME=\") | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as oracle_log_message | parse regex  field=oracle_log_message \"\\* \\(CONNECT_DATA[\\s\\S]+?\\* establish \\* \\S+ \\* (?<status>\\d+)\" nodrop | parse regex  field=oracle_log_message \"CONNECT_DATA[\\s\\S]+?SERVICE_NAME=(?<serviceName>[^)]*)\\)[\\s\\S]+establish\" nodrop | parse regex  field=oracle_log_message \"CONNECT_DATA[\\s\\S]+?service_name=(?<serviceName>[^)]*)\\)[\\s\\S]+establish\" nodrop | parse regex  field=oracle_log_message \"CONNECT_DATA[\\s\\S]+?SID=(?<SID>[^)]*)\\)[\\s\\S]+establish\" nodrop | parse regex  field=oracle_log_message \"CONNECT_DATA[\\s\\S]+?sid=(?<SID>[^)]*)\\)[\\s\\S]+establish\" nodrop | parse regex  field=oracle_log_message \"CONNECT_DATA[\\s\\S]+?PROGRAM=(?<userProgramName>[^)]*)\\)[\\s\\S]+?HOST=(?<userHost>[^)]*)\\)[\\s\\S]+?USER=(?<databaseUser>[^)]*)\\)\" nodrop | parse  field=oracle_log_message \"(ADDRESS=(PROTOCOL=*)(HOST=*)(PORT=*))\" as clientProtocol, clientHost, clientPort nodrop | parse regex  field=oracle_log_message \"(?<TNSerr>TNS-\\d{5}): (?<tnsmsg>.*)\" nodrop | where status != \"0\" | if (isEmpty(pod),_sourceHost,pod) as host | fields db_cluster,host,clientHost"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Warning",
      detection_method = "LogsStaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedWarning",
      detection_method = "LogsStaticCondition"
    }
  ]
}
module "Oracle-FatalNIConnectError" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - Fatal NI Connect Error"
  monitor_description      = "This alert fires when we detect a \"Fatal NI connect error\"."
  monitor_monitor_type     = "Logs"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_cluster=* db_system=oracle \"Fatal NI connect error\" | json \"log\" as _rawlog nodrop  | if (isEmpty(_rawlog), _raw, _rawlog) as oracle_log_message | parse regex field=oracle_log_message \"Fatal NI connect error (?<oraerr>\\d+?)(?:,|\\.)\" | if (isEmpty(pod),_sourceHost,pod) as host | count as eventCount by db_cluster, host"
  }
  triggers = [
    {
      threshold_type   = "GreaterThan",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "Warning",
      detection_method = "LogsStaticCondition"
    },
    {
      threshold_type   = "LessThanOrEqual",
      threshold        = 0,
      time_range       = "5m",
      occurrence_type  = "ResultCount"
      trigger_source   = "AllResults"
      trigger_type     = "ResolvedWarning",
      detection_method = "LogsStaticCondition"
    }
  ]
}
module "Oracle-UserLimitWarning" {
  source = "SumoLogic/sumo-logic-monitor/sumologic"
  count  = contains(local.all_components_values, "oracle") ? 1 : 0
  #version                  = "{revision}"
  monitor_name             = "Oracle - User Limit Warning"
  monitor_description      = "This alert fires when concurrent user sessions usage is over 80%"
  monitor_monitor_type     = "Metrics"
  monitor_parent_id        = sumologic_monitor_folder.oracle_monitor_folder[count.index].id
  monitor_is_disabled      = var.monitors_disabled
  group_notifications      = var.group_notifications
  connection_notifications = var.connection_notifications_critical
  email_notifications      = var.email_notifications_critical
  queries = {
    A = "${var.oracle_data_source} db_system=oracle metric_name=user_limit_% metric=oracle_sysmetric_metric_value db_cluster=* host=* | sum by db_cluster,host,instance"
  }
  triggers = [
    {
      threshold_type   = "GreaterThanOrEqual",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "Warning",
      detection_method = "MetricsStaticCondition"
    },
    {
      threshold_type   = "LessThan",
      threshold        = 80,
      time_range       = "5m",
      occurrence_type  = "Always"
      trigger_source   = "AnyTimeSeries"
      trigger_type     = "ResolvedWarning",
      detection_method = "MetricsStaticCondition"
    }
  ]
}
