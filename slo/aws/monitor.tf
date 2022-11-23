module "aws_elb_server_errors_limit_breached_monitor" {
  depends_on = [
    sumologic_slo.aws_elb_server_errors_limit_breached
  ]
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "AWS - Server Errors Limit Breached."
  monitor_description         = "This alert is fired when the AWS Server Errors Limit Breached."
  monitor_monitor_type        = "Slo"
  monitor_slo_type            = "BurnRate"
  monitor_slo_id              = sumologic_slo.aws_elb_server_errors_limit_breached.id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
 #monitor_evaluation_delay  = var.evaluation_delay #TODO

  slo_burnrate_triggers = [
			  {
				threshold = 100,
        time_range = "5m",
				trigger_type = "Critical"
			  },
			  {
				threshold = 100,
				time_range = "5m",
				trigger_type = "Warning"
			  }
			]
}

module "aws_elb_latency_limit_breached_monitor" {
  depends_on = [
    sumologic_slo.aws_elb_latency_limit_breached
  ]
  source                    = "SumoLogic/sumo-logic-monitor/sumologic"
  #version                  = "{revision}"
  monitor_name                = "AWS - Error budget for latency has depleted by 2% in 1 hour."
  monitor_description         = "This alert is fired when Error budget for latency has depleted by 2% in 1 hour."
  monitor_monitor_type        = "Slo"
  monitor_slo_type            = "BurnRate"
  monitor_slo_id              = sumologic_slo.aws_elb_latency_limit_breached.id
  monitor_is_disabled         = var.monitors_disabled
  group_notifications       = var.group_notifications
  connection_notifications  = var.connection_notifications_warning
  email_notifications       = var.email_notifications_warning
  #monitor_evaluation_delay  = var.evaluation_delay #TODO

  slo_burnrate_triggers = [
			  {
				threshold = 2,
        time_range = "1h",
				trigger_type = "Critical",
			  }
			]
}