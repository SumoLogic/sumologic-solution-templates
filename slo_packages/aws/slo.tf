resource "sumologic_slo" "aws_elb_server_errors_limit_breached" {
  name        = "Server Errors Limit Breached"
  description = "Server error rate every 5 minutes rolling over 24 hrs."
  parent_id   = sumologic_slo_folder.AWS.id
  signal_type = "Error"

  compliance {
      compliance_type = "Rolling"
      size            = "1d"
      target          = 99
      timezone        = var.time_zone
  }
  indicator {
    window_based_evaluation {
      op         = "GreaterThanOrEqual"
      query_type = "Metrics"
      size       = "5m"
      threshold  = 99.0
      queries {
        query_group_type = "Unsuccessful"
        query_group {
          row_id        = "A"
          query         = "${var.aws_elb_data_filter} metric=HTTPCode_Backend_5XX"
          use_row_count = false
        }
      }
      queries {
        query_group_type = "Total"
        query_group {
          row_id = "A"
          query  = "${var.aws_elb_data_filter} metric=RequestCount"
          use_row_count = false
        }
      }
    }
  }
}

resource "sumologic_slo" "aws_elb_latency_limit_breached" {
  name        = "Latency Limit Breached"
  description = "Round-trip request-processing time between load balancer and backend every 5 minutes rolling over 24 hrs."
  parent_id   = sumologic_slo_folder.AWS.id
  signal_type = "Latency"

  compliance {
      compliance_type = "Rolling"
      size            = "1d"
      target          = 99
      timezone        = var.time_zone
  }
  indicator {
    window_based_evaluation {
      op         = "LessThanOrEqual"
      query_type = "Metrics"
      size       = "5m"
      threshold  = 3
      aggregation   = "Avg"
      queries {
        query_group_type = "Threshold"
        query_group {
          row_id        = "A"
          query         = "${var.aws_elb_data_filter} metric=Latency"
          use_row_count = false
          }
      }
    }
  }
}