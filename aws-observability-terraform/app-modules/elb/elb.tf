module "classic_elb_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** FERs ********************** #
  # managed_field_extraction_rules = {
  #   "AlbAccessLogsFieldExtractionRule" = {
  #     name             = "AwsObservabilityAlbAccessLogsFER"
  #     scope            = "account=* region=* namespace=aws/alb"
  #     parse_expression = <<EOT
  #             | parse "* * * * * * * * * * * * \"*\" \"*\" * * * \"*\"" as Type, DateTime, loadbalancer, Client, Target, RequestProcessingTime, TargetProcessingTime, ResponseProcessingTime, ElbStatusCode, TargetStatusCode, ReceivedBytes, SentBytes, Request, UserAgent, SslCipher, SslProtocol, TargetGroupArn, TraceId
  #             | tolowercase(loadbalancer) as loadbalancer
  #             | fields loadbalancer
  #     EOT
  #     enabled          = true
  #   }
  # }

  # ********************** Apps ********************** #
  managed_apps = {
    "ClassicLBApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/Classic-lb-App.json"])
      folder_id    = var.app_folder_id
    }
  }
}