# Add fields to source if Metric source already exists
resource "null_resource" "AddFieldsToMetricSource" {
   for_each   = toset(local.update_metrics_source ? ["add_fields_to_source"] : [])
   triggers = {
       access_id         = var.access_id
       access_key        = var.access_key
       env               = var.environment
       source_url        = var.cloudwatch_metrics_source_url
   }
   provisioner "local-exec" {
       when    = create
       command = "python ${path.module}/attach_fields_to_source.py"
       environment = {
           SumoAccessID = self.triggers.access_id
           SumoAccessKey = self.triggers.access_key
           SumoDeployment = self.triggers.env
           SourceApiUrl = self.triggers.source_url
           Fields = jsonencode(local.metrics_fields)
       }
   }
}

# Add fields to source if CloudTrail source already exists
resource "null_resource" "AddFieldsToCloudTrailSource" {
   for_each   = toset(local.update_cloudtrail_source ? ["add_fields_to_source"] : [])
   triggers = {
       access_id         = var.access_id
       access_key        = var.access_key
       env               = var.environment
       source_url        = var.cloudtrail_source_url
   }
   provisioner "local-exec" {
       when    = create
       command = "python ${path.module}/attach_fields_to_source.py"
       environment = {
           SumoAccessID = self.triggers.access_id
           SumoAccessKey = self.triggers.access_key
           SumoDeployment = self.triggers.env
           SourceApiUrl = self.triggers.source_url
           Fields = jsonencode(local.cloudtrail_fields)
       }
   }
}

# Add fields to source if Application LoadBalancer source already exists
resource "null_resource" "AddFieldsToELBSource" {
   for_each   = toset(local.update_elb_source ? ["add_fields_to_source"] : [])
   triggers = {
       access_id         = var.access_id
       access_key        = var.access_key
       env               = var.environment
       source_url        = var.elb_log_source_url
   }
   provisioner "local-exec" {
       when    = create
       command = "python ${path.module}/attach_fields_to_source.py"
       environment = {
           SumoAccessID = self.triggers.access_id
           SumoAccessKey = self.triggers.access_key
           SumoDeployment = self.triggers.env
           SourceApiUrl = self.triggers.source_url
           Fields = jsonencode(local.elb_fields)
       }
   }
}

# Add fields to source if Classic LoadBalancer source already exists
resource "null_resource" "AddFieldsToCLBSource" {
   for_each   = toset(local.update_classic_lb_source ? ["add_fields_to_source"] : [])
   triggers = {
       access_id         = var.access_id
       access_key        = var.access_key
       env               = var.environment
       source_url        = var.classic_lb_log_source_url
   }
   provisioner "local-exec" {
       when    = create
       command = "python ${path.module}/attach_fields_to_source.py"
       environment = {
           SumoAccessID = self.triggers.access_id
           SumoAccessKey = self.triggers.access_key
           SumoDeployment = self.triggers.env
           SourceApiUrl = self.triggers.source_url
           Fields = jsonencode(local.classic_lb_fields)
       }
   }
}

# Add fields to source if CloudWatch Logs source already exists
resource "null_resource" "AddFieldsToLogSource" {
   for_each   = toset(local.update_logs_source ? ["add_fields_to_source"] : [])
   triggers = {
       access_id         = var.access_id
       access_key        = var.access_key
       env               = var.environment
       source_url        = var.cloudwatch_logs_source_url
   }
   provisioner "local-exec" {
       when    = create
       command = "python ${path.module}/attach_fields_to_source.py"
       environment = {
           SumoAccessID = self.triggers.access_id
           SumoAccessKey = self.triggers.access_key
           SumoDeployment = self.triggers.env
           SourceApiUrl = self.triggers.source_url
           Fields = jsonencode(local.cloudwatch_logs_fields)
       }
   }
}