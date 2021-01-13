provider "aws" {
  region = "us-east-1"
}

locals {
  section = "ALB"
  # Below values will come from Variables
  account_alias = "dev"
  access_id = ""
  access_key = ""
  deployment = "us1"
  install_app = "Yes"
  metric_source_api_url = "https://api.sumologic.com/api/v1/collectors/170503459/sources/779400289"
  alb_log_source_api_url = "https://api.sumologic.com/api/v1/collectors/177457427/sources/839230890"
  alb_log_source_name = ""
  bucket_name = "sumologic-appdev-aws-sam-apps"
  apps_version = "v2.1.0"

  # Condition
  source_created = length(local.alb_log_source_name) > 0 ? true : false
  source_updated = length(local.alb_log_source_api_url) > 0 ? true : false
}

data "aws_region" "current" {}

# Field will not have destroy as we will never like to delete the Field
resource "null_resource" "create_field" {

  triggers = {
    field = "loadbalancer"
    SumoAccessID = local.access_id
    SumoAccessKey = local.access_key
    SumoDeployment = local.deployment
  }

  provisioner "local-exec" {
    command = "python3 ${path.module}/src/main.py"
    environment = {
      ResourceType = "SumoLogicFieldsSchema"
      Section = local.section
      KeyPrefix = "1"
      FieldName = self.triggers.field
      SumoAccessID = self.triggers.SumoAccessID
      SumoAccessKey = self.triggers.SumoAccessKey
      SumoDeployment = self.triggers.SumoDeployment
    }
  }
}

# Metric Rule will not have destroy as we will never like to delete the Metric Rule
resource "null_resource" "create_metric_rule" {

  triggers = {
    name = "AwsObservabilityALBMetricsEntityRule"
    expression = "Namespace=AWS/ApplicationALB LoadBalancer=*"
    variables = "{\"entity\": \"$LoadBalancer._1\"}"
    SumoAccessID = local.access_id
    SumoAccessKey = local.access_key
    SumoDeployment = local.deployment
  }

  provisioner "local-exec" {
    command = "python3 ${path.module}/src/main.py"
    environment = {
      ResourceType = "SumoLogicMetricRules"
      Section = local.section
      KeyPrefix = "1"
      MetricRuleName = self.triggers.name
      MatchExpression = self.triggers.expression
      ExtractVariables = self.triggers.variables
      SumoAccessID = self.triggers.SumoAccessID
      SumoAccessKey = self.triggers.SumoAccessKey
      SumoDeployment = self.triggers.SumoDeployment
    }
  }
}

# Apps installation
resource "null_resource" "install_apps" {
  count = local.install_app == "Yes" ? 1 : 0
  triggers = {
    FolderName = "Sumo Logic AWS Observability Apps "
    AppName = "AWS Observability ALB App"
    RetainOldAppOnUpdate = "True"
    AppJsonS3Url = "https://${local.bucket_name}.s3.amazonaws.com/aws-observability-versions/${local.apps_version}/appjson/Alb-App.json"
    SumoAccessID = local.access_id
    SumoAccessKey = local.access_key
    SumoDeployment = local.deployment
    Section = local.section
  }

  provisioner "local-exec" {
    command = "python3 ${path.module}/src/main.py"
    environment = {
      ResourceType = "App"
      Section = self.triggers.Section
      KeyPrefix = "1"
      AppName = self.triggers.AppName
      FolderName = self.triggers.FolderName
      RetainOldAppOnUpdate = self.triggers.RetainOldAppOnUpdate
      AppJsonS3Url = self.triggers.AppJsonS3Url
      SumoAccessID = self.triggers.SumoAccessID
      SumoAccessKey = self.triggers.SumoAccessKey
      SumoDeployment = self.triggers.SumoDeployment
    }
  }
}

# Adding Field will have destroy as we will never like to remove field from the sources
resource "null_resource" "add_fields_to_log_source" {
  count = length(local.alb_log_source_api_url) > 0 ? 1 : 0

  triggers = {
    sourceApiUrl = local.alb_log_source_api_url
    fields = "{\"account\": \"${local.account_alias}\", \"namespace\": \"AWS/ApplicationELB\", \"region\": \"${data.aws_region.current.name}\"}"
    SumoAccessID = local.access_id
    SumoAccessKey = local.access_key
    SumoDeployment = local.deployment
    Section = local.section
  }

  provisioner "local-exec" {
    command = "python3 ${path.module}/src/main.py"
    environment = {
      ResourceType = "SumoLogicUpdateFields"
      Section = self.triggers.Section
      KeyPrefix = "1"
      SourceApiUrl = self.triggers.sourceApiUrl
      Fields = self.triggers.fields
      SumoAccessID = self.triggers.SumoAccessID
      SumoAccessKey = self.triggers.SumoAccessKey
      SumoDeployment = self.triggers.SumoDeployment
    }
  }
  provisioner "local-exec" {
    when = destroy
    command = "python3 ${path.module}/src/main.py"
    environment = {
      ResourceType = "SumoLogicUpdateFields"
      Delete = "True"
      Section = self.triggers.Section
      KeyPrefix = "1"
      SourceApiUrl = self.triggers.sourceApiUrl
      Fields = self.triggers.fields
      SumoAccessID = self.triggers.SumoAccessID
      SumoAccessKey = self.triggers.SumoAccessKey
      SumoDeployment = self.triggers.SumoDeployment
    }
  }
}

data "external" "existing_source_name" {
  depends_on = [null_resource.add_fields_to_log_source]
  program = ["python", "${path.module}/src/fetchid.py"]
  query = {
    Section = local.section
    KeyPrefix = "1"
    Key = "SumoLogicUpdateFields"
    FetchKey = "source_name"
  }
}

# Another Source updated to add fields. Key_Prefix is made as 2.
resource "null_resource" "add_fields_to_metric_source" {
  count = length(local.metric_source_api_url) > 0 ? 1 : 0

  triggers = {
    sourceApiUrl = local.metric_source_api_url
    fields = "{\"account\": \"${local.account_alias}\"}"
    SumoAccessID = local.access_id
    SumoAccessKey = local.access_key
    SumoDeployment = local.deployment
    Section = local.section
  }

  provisioner "local-exec" {
    command = "python3 ${path.module}/src/main.py"
    environment = {
      ResourceType = "SumoLogicUpdateFields"
      Section = self.triggers.Section
      KeyPrefix = "2"
      SourceApiUrl = self.triggers.sourceApiUrl
      Fields = self.triggers.fields
      SumoAccessID = self.triggers.SumoAccessID
      SumoAccessKey = self.triggers.SumoAccessKey
      SumoDeployment = self.triggers.SumoDeployment
    }
  }
  provisioner "local-exec" {
    when = destroy
    command = "python3 ${path.module}/src/main.py"
    environment = {
      ResourceType = "SumoLogicUpdateFields"
      Delete = "True"
      Section = self.triggers.Section
      KeyPrefix = "2"
      SourceApiUrl = self.triggers.sourceApiUrl
      Fields = self.triggers.fields
      SumoAccessID = self.triggers.SumoAccessID
      SumoAccessKey = self.triggers.SumoAccessKey
      SumoDeployment = self.triggers.SumoDeployment
    }
  }
}

# Field Extraction Rule
resource "null_resource" "field_extraction_rule" {
  count = local.source_created || local.source_updated ? 1 : 0
  triggers = {
    FieldExtractionRuleName = "AwsObservabilityAlbAccessLogsFER"
    FieldExtractionRuleScope = local.source_created ? "(_source=${local.alb_log_source_name})" : "(_source=\"${data.external.existing_source_name.result.id}\")"
    FieldExtractionRuleParseExpression = "| parse \"* * * * * * * * * * * * \\\"*\\\" \\\"*\\\" * * * \\\"*\\\"\" as Type, DateTime, loadbalancer, Client, Target, RequestProcessingTime, TargetProcessingTime, ResponseProcessingTime, ElbStatusCode, TargetStatusCode, ReceivedBytes, SentBytes, Request, UserAgent, SslCipher, SslProtocol, TargetGroupArn, TraceId | tolowercase(loadbalancer) as loadbalancer | fields loadbalancer"
    FieldExtractionRuleParseEnabled = "True"
    SumoAccessID = local.access_id
    SumoAccessKey = local.access_key
    SumoDeployment = local.deployment
    Section = local.section
  }

  provisioner "local-exec" {
    command = "python3 ${path.module}/src/main.py"
    environment = {
      ResourceType = "SumoLogicFieldExtractionRule"
      Section = self.triggers.Section
      KeyPrefix = "1"
      FieldExtractionRuleName = self.triggers.FieldExtractionRuleName
      FieldExtractionRuleScope =self.triggers.FieldExtractionRuleScope
      FieldExtractionRuleParseExpression = self.triggers.FieldExtractionRuleParseExpression
      FieldExtractionRuleParseEnabled = self.triggers.FieldExtractionRuleParseEnabled
      SumoAccessID = self.triggers.SumoAccessID
      SumoAccessKey = self.triggers.SumoAccessKey
      SumoDeployment = self.triggers.SumoDeployment
    }
  }
}

