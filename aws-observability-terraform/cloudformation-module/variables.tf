# AWS Observability cloudformation template variables with all default values and validations.

variable "CloudFormationStackName" {
  type    = string
  default = ""
  validation {
    condition     = length(var.CloudFormationStackName) > 0
    error_message = "The \"CloudFormationStackName\" can not be empty and include letters (A-Z and a-z), numbers (0-9), and dashes (-)."
  }
}

# Sumo Logic Access Configuration (Required)
variable "Section1aSumoLogicDeployment" {
  type        = string
  description = "Enter au, ca, de, eu, fed, in, jp, kr, us1 or us2. Visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"
  validation {
    condition = contains([
      "au",
      "ca",
      "de",
      "eu",
      "jp",
      "us2",
      "in",
      "fed",
    "us1"], var.Section1aSumoLogicDeployment)
    error_message = "Argument \"Section1aSumoLogicDeployment\" must be either \"au\", \"ca\", \"de\", \"eu\", \"jp\", \"us2\", \"in\", \"fed\" or \"us1\"."
  }
}
variable "Section1bSumoLogicAccessID" {
  type        = string
  description = "Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"
  validation {
    condition     = length(var.Section1bSumoLogicAccessID) > 0
    error_message = "The \"Section1bSumoLogicAccessID\" can not be empty."
  }
}
variable "Section1cSumoLogicAccessKey" {
  type        = string
  description = "Sumo Logic Access Key."
  validation {
    condition     = length(var.Section1cSumoLogicAccessKey) > 0
    error_message = "The \"Section1cSumoLogicAccessKey\" can not be empty."
  }
}
variable "Section1dSumoLogicOrganizationId" {
  type        = string
  description = "Appears on the Account Overview page that displays information about your Sumo Logic organization. Used for IAM Role in Sumo Logic AWS Sources. Visit https://help.sumologic.com/01Start-Here/05Customize-Your-Sumo-Logic-Experience/Preferences-Page"
  validation {
    condition     = length(var.Section1dSumoLogicOrganizationId) > 0
    error_message = "The \"Section1dSumoLogicOrganizationId\" can not be empty."
  }
}
variable "Section1eSumoLogicResourceRemoveOnDeleteStack" {
  type        = string
  default     = "true"
  description = "To delete collectors, sources and apps when the stack is deleted, set this parameter to True. Default is True. Deletes the resources created by the stack. Deletion of updated resources will be skipped."
  validation {
    condition = contains([
      "true",
    "false"], var.Section1eSumoLogicResourceRemoveOnDeleteStack)
    error_message = "Argument \"Section1eSumoLogicResourceRemoveOnDeleteStack\" must be either \"true\", or \"false\"."
  }
}
# AWS Account Alias
variable "Section2aAccountAlias" {
  type        = string
  description = "Provide an Alias for AWS account for identification in Sumo Logic Explorer View, metrics and logs. Please do not include special characters."
  validation {
    condition     = length(var.Section2aAccountAlias) > 0 && length(var.Section2aAccountAlias) <= 30
    error_message = "The \"Section2aAccountAlias\" must only contain lowercase letters, number and length less than or equal to 30 characters."
  }
}
# Sumo Logic AWS Observability Apps and Alerts
variable "Section3aInstallObservabilityApps" {
  type        = string
  default     = "Yes"
  description = "Yes - Installs Apps (EC2, Application Load Balancer, RDS, API Gateway, Lambda, Dynamo DB, ECS, ElastiCache and NLB) and Alerts for the Sumo Logic AWS Observability Solution. All the Apps are installed in the folder 'AWS Observability'. No - Skips the installation of Apps and Alerts."
  validation {
    condition = contains([
      "Yes",
    "No"], var.Section3aInstallObservabilityApps)
    error_message = "Argument \"Section3aInstallObservabilityApps\" must be either \"Yes\", or \"No\"."
  }
}
# Sumo Logic AWS CloudWatch Metrics Sources
variable "Section4aCreateMetricsSourceOptions" {
  type        = string
  default     = "Kinesis Firehose Metrics Source"
  description = "CloudWatch Metrics Source - Creates Sumo Logic AWS CloudWatch Metrics Sources. Kinesis Firehose Metrics Source -  Creates a Sumo Logic AWS Kinesis Firehose for Metrics Source."
  validation {
    condition = contains([
      "CloudWatch Metrics Source",
      "Kinesis Firehose Metrics Source",
    "None"], var.Section4aCreateMetricsSourceOptions)
    error_message = "Argument \"Section4aCreateMetricsSourceOptions\" must be either \"Kinesis Firehose Metrics Source\", \"CloudWatch Metrics Source\" or \"None\"."
  }
}
variable "Section4bMetricsNameSpaces" {
  type        = string
  default     = "AWS/ApplicationELB, AWS/ApiGateway, AWS/DynamoDB, AWS/Lambda, AWS/RDS, AWS/ECS, AWS/ElastiCache, AWS/ELB, AWS/NetworkELB, AWS/SQS, AWS/SNS, AWS/EC2"
  description = "Provide Comma delimited list of the namespaces which will be used for both AWS CloudWatch Metrics and Inventory Sources. Default will be AWS/ApplicationELB, AWS/ApiGateway, AWS/DynamoDB, AWS/Lambda, AWS/RDS, AWS/ECS, AWS/ElastiCache, AWS/ELB, AWS/NetworkELB, AWS/SQS, AWS/SNS, AWS/EC2. AWS/AutoScaling will be appended to Namespaces for Inventory Sources."
}
variable "Section4cCloudWatchExistingSourceAPIUrl" {
  type        = string
  default     = ""
  description = "Required when already collecting CloudWatch Metrics. Provide the existing Sumo Logic CloudWatch Metrics Source API URL. Account Field will be added to the Source. For Source API URL, visit https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration"
}
# Sumo Logic AWS ALB Log Source
variable "Section5aAutoEnableS3LogsALBResourcesOptions" {
  type        = string
  default     = "Both"
  description = "New - Automatically enables S3 logging for newly created ALB resources to collect logs for ALB resources. This does not affect ALB resources already collecting logs. Existing - Automatically enables S3 logging for existing ALB resources to collect logs for ALB resources. Both - Automatically enables S3 logging for new and existing ALB resources. None - Skips Automatic S3 Logging enable for ALB resources."
  validation {
    condition = contains([
      "New",
      "Existing",
      "Both",
    "None"], var.Section5aAutoEnableS3LogsALBResourcesOptions)
    error_message = "Argument \"Section5aAutoEnableS3LogsALBResourcesOptions\" must be either \"New\", \"Existing\", \"Both\" or \"None\"."
  }
}
variable "Section5bALBCreateLogSource" {
  type        = string
  default     = "Yes"
  description = "Yes - Creates a Sumo Logic ALB Log Source that collects ALB logs from an existing bucket or a new bucket. No - If you already have an ALB source collecting ALB logs into Sumo Logic."
  validation {
    condition = contains([
      "Yes",
    "No"], var.Section5bALBCreateLogSource)
    error_message = "Argument \"Section5bALBCreateLogSource\" must be either \"Yes\", or \"No\"."
  }
}
variable "Section5cALBLogsSourceUrl" {
  type        = string
  default     = ""
  description = "Required when already collecting ALB logs in Sumo Logic. Provide the existing Sumo Logic ALB Source API URL. Account, region and namespace Fields will be added to the Source. For Source API URL, visit https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration"
}
variable "Section5dALBS3LogsBucketName" {
  type        = string
  default     = ""
  description = "If you selected 'No' to creating a new source above, skip this step. Provide a name of existing S3 bucket name where you would like to store ALB logs. If this is empty, a new bucket will be created in the region."
}
variable "Section5eALBS3BucketPathExpression" {
  type        = string
  default     = "*AWSLogs/*/elasticloadbalancing/*"
  description = "This is required in case the above existing bucket is already configured to receive ALB access logs. If this is blank, Sumo Logic will store logs in the path expression: *AWSLogs/*/elasticloadbalancing/*"
}
# Sumo Logic AWS CloudTrail Source
variable "Section6aCreateCloudTrailLogSource" {
  type        = string
  default     = "Yes"
  description = "Yes - Creates a Sumo Logic CloudTrail Log Source that collects CloudTrail logs from an existing bucket or a new bucket. No - If you already have a CloudTrail Log source collecting CloudTrail logs into Sumo Logic."
  validation {
    condition = contains([
      "Yes",
    "No"], var.Section6aCreateCloudTrailLogSource)
    error_message = "Argument \"Section6aCreateCloudTrailLogSource\" must be either \"Yes\", or \"No\"."
  }
}
variable "Section6bCloudTrailLogsSourceUrl" {
  type        = string
  default     = ""
  description = "Required when already collecting CloudTrail logs in Sumo Logic. Provide the existing Sumo Logic CloudTrail Source API URL. Account Field will be added to the Source. For Source API URL, visit https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration"
}
variable "Section6cCloudTrailLogsBucketName" {
  type        = string
  default     = ""
  description = "If you selected 'No' to creating a new source above, skip this step. Provide a name of existing S3 bucket name where you would like to store CloudTrail logs. If this is empty, a new bucket will be created in the region."
}
variable "Section6dCloudTrailBucketPathExpression" {
  type        = string
  default     = "AWSLogs/*/CloudTrail/*"
  description = "This is required in case the above existing bucket is already configured to receive CloudTrail logs. If this is blank, Sumo Logic will store logs in the path expression: AWSLogs/*/CloudTrail/*"
}
# Sumo Logic AWS Lambda CloudWatch HTTP Source
variable "Section7aLambdaCreateCloudWatchLogsSourceOptions" {
  type        = string
  default     = "Kinesis Firehose Log Source"
  description = "Lambda Log Forwarder - Creates a Sumo Logic CloudWatch Log Source that collects CloudWatch logs via a Lambda function. Kinesis Firehose Log Source - Creates a Sumo Logic Kinesis Firehose Source to collect CloudWatch logs."
  validation {
    condition = contains([
      "Kinesis Firehose Log Source",
      "Lambda Log Forwarder",
      "Both (Switch from Lambda Log Forwarder to Kinesis Firehose Log Source)",
    "None"], var.Section7aLambdaCreateCloudWatchLogsSourceOptions)
    error_message = "Argument \"Section7aLambdaCreateCloudWatchLogsSourceOptions\" must be either \"Kinesis Firehose Log Source\", \"Lambda Log Forwarder\", \"Both (Switch from Lambda Log Forwarder to Kinesis Firehose Log Source)\" or \"None\"."
  }
}
variable "Section7bLambdaCloudWatchLogsSourceUrl" {
  type        = string
  default     = ""
  description = "Required when already collecting Lambda CloudWatch logs in Sumo Logic. Provide the existing Sumo Logic Lambda CloudWatch Source API URL. Account, region and namespace Fields will be added to the Source. For Source API URL, visit https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration"
}
variable "Section7cAutoSubscribeLogGroupsLambdaOptions" {
  type        = string
  default     = "Both"
  description = "New - Automatically subscribes new log groups to lambda to send logs to Sumo Logic. Existing - Automatically subscribes existing log groups to lambda to send logs to Sumo Logic. Both - Automatically subscribes new and existing log groups. None - Skips Automatic subscription."
  validation {
    condition = contains([
      "New",
      "Existing",
      "Both",
    "None"], var.Section7cAutoSubscribeLogGroupsLambdaOptions)
    error_message = "Argument \"Section7cAutoSubscribeLogGroupsLambdaOptions\" must be either \"New\", \"Existing\", \"Both\" or \"None\"."
  }
}
variable "Section7dAutoSubscribeLambdaLogGroupPattern" {
  type        = string
  default     = "lambda"
  description = "Enter regex for matching logGroups. Regex will check for the name. Visit https://help.sumologic.com/03Send-Data/Collect-from-Other-Data-Sources/Auto-Subscribe_AWS_Log_Groups_to_a_Lambda_Function#Configuring_parameters"
}
# Sumo Logic Root Cause Explorer Sources
variable "Section8aRootCauseExplorerOptions" {
  type        = string
  default     = "Both"
  description = "Inventory Source - Creates a Sumo Logic Inventory Source used by Root Cause Explorer. Xray Source - Creates a Sumo Logic AWS X-Ray Source that collects X-Ray Trace Metrics from your AWS account."
  validation {
    condition = contains([
      "Inventory Source",
      "Xray Source",
      "Both",
    "None"], var.Section8aRootCauseExplorerOptions)
    error_message = "Argument \"Section8aRootCauseExplorerOptions\" must be either \"Inventory Source\", \"Xray Source\", \"Both\" or \"None\"."
  }
}