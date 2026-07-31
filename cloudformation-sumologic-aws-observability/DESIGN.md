# AWS Observability Solution — CloudFormation Stack Design

Version: v3.0.0

## Stack Hierarchy

```
sumologic_observability.master.template.yaml  (root)
├── CreateCommonResources        resources.template.yaml          [always]
│   ├── CloudWatchMetricsFirstStack    cloudwatchmetrics.template.yaml        [install_cloud_watch_metric_source]
│   ├── CloudWatchMetricsSecondStack   cloudwatchmetrics.template.yaml        [install_cloud_watch_metric_source]
│   ├── CloudWatchMetricsThirdStack    cloudwatchmetrics.template.yaml        [install_cloud_watch_metric_source]
│   ├── KinesisFirehoseMetricsStack    kinesis_firehose_cw_metrics.template.yaml  [install_kf_metric_source]
│   ├── CloudWatchEventFunction        dlq_lambda_cloudformation.template.yaml    [install_cloudwatch_logs_source]
│   └── KinesisFirehoseLogsStack       kinesis_firehose_cw_logs.template.yaml     [install_kf_logs_source]
├── AutoEnableOptions            auto_enable.template.yaml        [call_auto_enable]
│   ├── AutoEnableS3LogsAlbStack                s3_logging_auto_enable.template.yaml  [auto_enable_s3_logs]
│   ├── AutoEnableS3LogsElbStack                s3_logging_auto_enable.template.yaml  [auto_enable_s3_logs_elb]
│   └── AutoSubscribeLambdaLogGroupsAWSResources loggroup_connector.template.yaml     [auto_subscribe_log_groups]
└── sumoAppStacks                apps.template.yaml               [install_observability_apps]
```

---

## Master Template — `sumologic_observability.master.template.yaml`

Top-level resources created when telemetry is enabled (`send_telemetry_to_sumo`).

| Logical ID | Type | Condition | Description |
|------------|------|-----------|-------------|
| `LambdaRole` | `AWS::IAM::Role` | `send_telemetry_to_sumo` | IAM role for the telemetry Lambda function |
| `TelemetryLambda` | `AWS::Lambda::Function` | `send_telemetry_to_sumo` | Sends solution deployment telemetry to Sumo Logic |
| `LambdaPermission` | `AWS::Lambda::Permission` | `send_telemetry_to_sumo` | Allows CloudFormation to invoke TelemetryLambda |
| `PrimerInvoke` | `AWS::CloudFormation::CustomResource` | `send_telemetry_to_sumo` | Triggers telemetry Lambda with stack configuration |

### Nested Stacks

| Logical ID | Template | Condition | Description |
|------------|----------|-----------|-------------|
| `CreateCommonResources` | `resources.template.yaml` | always | Core infrastructure: collector, all sources, buckets, IAM, SNS |
| `AutoEnableOptions` | `auto_enable.template.yaml` | `call_auto_enable` | Auto-enables S3 logging for ALB/ELB; auto-subscribes CloudWatch Log Groups |
| `sumoAppStacks` | `apps.template.yaml` | `install_observability_apps` | Installs all AWS Observability dashboards and apps in Sumo Logic |

---

## CreateCommonResources — `resources.template.yaml`

### Lambda Helpers

| Logical ID | Type | Condition | Description |
|------------|------|-----------|-------------|
| `LambdaRole` | `AWS::IAM::Role` | always | IAM role for the main helper Lambda (S3, ELB, Logs, IAM permissions) |
| `LambdaHelper` | `AWS::Lambda::Function` | always | Custom resource handler for all Sumo Logic AWS resources |
| `LambdaRoleAlias` | `AWS::IAM::Role` | always | IAM role for the account alias Lambda |
| `LambdaHelperAlias` | `AWS::Lambda::Function` | always | Resolves AWS account alias from parameter or S3 CSV mapping |

### Account Validation

| Logical ID | Type | Condition | Description |
|------------|------|-----------|-------------|
| `AccountCheck` | `Custom::EnterpriseOrTrialAccountCheck` | always | Validates the Sumo Logic account is Enterprise or Trial |
| `AccountAliasValue` | `Custom::AccountAlias` | always | Resolves and stores the AWS account alias used for source field tagging |

### Sumo Logic Collector

| Logical ID | Type | Condition | Description |
|------------|------|-----------|-------------|
| `SumoLogicHostedCollector` | `Custom::Collector` | `install_collector` | Creates a Sumo Logic hosted collector named `aws-observability-{alias}-{accountId}`. Created when any source is being installed. |
| `LambdaToDecideCWMetricsSources` | `AWS::Lambda::Function` | always | Splits the CloudWatch namespace list to determine per-namespace source creation |
| `Primerinvoke` | `AWS::CloudFormation::CustomResource` | always | Invokes LambdaToDecideCWMetricsSources to compute namespace split |

### Sumo Logic Sources

| Logical ID | Type | Condition | Description |
|------------|------|-----------|-------------|
| `SumoLogicMetaDataSource` | `Custom::AWSSource` | `install_metadata_source` | AWS Metadata source for EC2 instance inventory |
| `ALBSource` | `Custom::AWSSource` | `install_alb_logs_source` | S3-based Sumo Logic source for ALB access logs |
| `ELBSource` | `Custom::AWSSource` | `install_elb_logs_source` | S3-based Sumo Logic source for Classic ELB access logs |
| `CloudTrailSource` | `Custom::AWSSource` | `install_cloudtrail_logs_source` | S3-based Sumo Logic source for CloudTrail logs |
| `CloudWatchHTTPSource` | `Custom::HTTPSource` | `install_cloudwatch_logs_source` | HTTP source endpoint for CloudWatch Logs (Lambda forwarder target) |
| `KinesisFirehoseMetricsSource` | `Custom::HTTPSource` | `install_kf_metric_source` | HTTP source endpoint for Kinesis Firehose CloudWatch Metrics |
| `KinesisFirehoseLogsSource` | `Custom::HTTPSource` | `install_kf_logs_source` | HTTP source endpoint for Kinesis Firehose CloudWatch Logs |

### Existing Source Field Updates

Created when an existing source API URL is supplied — updates the source with account/region/accountid fields.

| Logical ID | Type | Condition | Description |
|------------|------|-----------|-------------|
| `SumoALBLogsUpdateSource` | `Custom::SumoLogicUpdateFields` | `update_alb_source` | Adds account, region, accountid fields to an existing ALB log source |
| `SumoELBLogsUpdateSource` | `Custom::SumoLogicUpdateFields` | `update_elb_source` | Adds account, region, accountid fields to an existing ELB log source |
| `SumoCloudTrailLogsUpdateSource` | `Custom::SumoLogicUpdateFields` | `update_cloudtrail_source` | Adds account field to an existing CloudTrail log source |
| `SumoHTTPUpdateSource` | `Custom::SumoLogicUpdateFields` | `update_cloudwatch_source` | Adds account, region, accountid fields to an existing CloudWatch Logs source |
| `SumoALBMetricsUpdateSource` | `Custom::SumoLogicUpdateFields` | `update_metrics_source` | Adds account field to an existing ALB metrics source |
| `SumoELBMetricsUpdateSource` | `Custom::SumoLogicUpdateFields` | `update_metrics_source` | Adds account field to an existing ELB metrics source |
| `SumoMetricsUpdateSource` | `Custom::SumoLogicUpdateFields` | `update_metrics_source` | Adds account field to an existing generic metrics source |

### S3 Buckets and Bucket Policies

| Logical ID | Type | Condition | Description |
|------------|------|-----------|-------------|
| `CommonS3Bucket` | `AWS::S3::Bucket` | `create_target_s3_bucket` | Shared S3 bucket for ALB/ELB/CloudTrail logs. Includes inline SNS event notification for `s3:ObjectCreated:Put`. |
| `ALBBucketPolicy` | `Custom::AddBucketPolicy` | `needs_alb_bucket_policy` | Adds ALB-required bucket policy to new or existing ALB bucket |
| `ELBBucketPolicy` | `Custom::AddBucketPolicy` | `needs_elb_bucket_policy` | Adds ELB-required bucket policy to new or existing ELB bucket |
| `CloudTrailBucketPolicy` | `Custom::AddBucketPolicy` | `needs_cloudtrail_bucket_policy` | Adds CloudTrail-required bucket policy to new or existing CloudTrail bucket |

### SNS Topics

#### New bucket (shared SNS topic)

| Logical ID | Type | Condition | Description |
|------------|------|-----------|-------------|
| `CommonBucketSNSTopic` | `AWS::SNS::Topic` | `create_target_s3_bucket` | Shared SNS topic that receives S3 event notifications from CommonS3Bucket |
| `CommonSNSpolicy` | `AWS::SNS::TopicPolicy` | `create_target_s3_bucket` | Allows S3 to publish to CommonBucketSNSTopic |

#### Existing ALB bucket

| Logical ID | Type | Condition | Description |
|------------|------|-----------|-------------|
| `ALBSNSTopic` | `AWS::SNS::Topic` | `create_alb_sns_topic` | Dedicated SNS topic for existing ALB bucket notifications |
| `ALBSNSpolicy` | `AWS::SNS::TopicPolicy` | `create_alb_sns_topic` | Allows the existing ALB S3 bucket to publish to ALBSNSTopic |
| `ALBSNSSubscription` | `AWS::SNS::Subscription` | `install_alb_logs_source` | Subscribes the ALB source HTTPS endpoint to the SNS topic |

#### Existing ELB bucket

| Logical ID | Type | Condition | Description |
|------------|------|-----------|-------------|
| `ELBSNSTopic` | `AWS::SNS::Topic` | `create_elb_sns_topic` | Dedicated SNS topic for existing ELB bucket notifications |
| `ELBSNSpolicy` | `AWS::SNS::TopicPolicy` | `create_elb_sns_topic` | Allows the existing ELB S3 bucket to publish to ELBSNSTopic |
| `ELBSNSSubscription` | `AWS::SNS::Subscription` | `install_elb_logs_source` | Subscribes the ELB source HTTPS endpoint to the SNS topic |

#### Existing CloudTrail bucket

| Logical ID | Type | Condition | Description |
|------------|------|-----------|-------------|
| `CloudTrailSNSTopic` | `AWS::SNS::Topic` | `create_cloudtrail_sns_topic` | Dedicated SNS topic for existing CloudTrail bucket notifications |
| `CloudTrailSNSpolicy` | `AWS::SNS::TopicPolicy` | `create_cloudtrail_sns_topic` | Allows the existing CloudTrail S3 bucket to publish to CloudTrailSNSTopic |
| `CloudTrailSNSSubscription` | `AWS::SNS::Subscription` | `install_cloudtrail_logs_source` | Subscribes the CloudTrail source HTTPS endpoint to the SNS topic |

#### S3 Bucket Notifications for Existing Buckets

| Logical ID | Type | Condition | Description |
|------------|------|-----------|-------------|
| `ALBBucketNotification` | `Custom::AddBucketNotification` | `is_alb_bucket_provided` | Wires `s3:ObjectCreated:*` notification on the existing ALB bucket to `ALBSNSTopic` |
| `ELBBucketNotification` | `Custom::AddBucketNotification` | `elb_needs_own_bucket_notification` | Wires `s3:ObjectCreated:*` notification on the existing ELB bucket to `ELBSNSTopic`. Skipped when ELB bucket equals ALB bucket. |
| `CloudTrailBucketNotification` | `Custom::AddBucketNotification` | `ct_needs_own_bucket_notification` | Wires `s3:ObjectCreated:*` notification on the existing CloudTrail bucket to `CloudTrailSNSTopic`. Skipped when CT bucket equals ALB or ELB bucket. |

> **Why:** S3 only allows one unfiltered `TopicConfiguration` per event type per bucket. When multiple sources share the same existing bucket, only one `BucketNotification` is created and the other sources' SNS subscriptions are routed to the primary topic (fan-out via SNS subscription).

#### Same-Bucket Routing Matrix

| Scenario | `ALBBucketNotification` | `ELBBucketNotification` | `CTBucketNotification` | ELB subscribes to | CT subscribes to |
|----------|:-----------------------:|:-----------------------:|:----------------------:|-------------------|-----------------|
| All different buckets | ✅ | ✅ | ✅ | `ELBSNSTopic` | `CloudTrailSNSTopic` |
| ALB = ELB = CT | ✅ | ❌ skipped | ❌ skipped | `ALBSNSTopic` | `ALBSNSTopic` |
| ALB = ELB, CT different | ✅ | ❌ skipped | ✅ | `ALBSNSTopic` | `CloudTrailSNSTopic` |
| ALB = CT, ELB different | ✅ | ✅ | ❌ skipped | `ELBSNSTopic` | `ALBSNSTopic` |
| ELB = CT, ALB different | ✅ | ✅ | ❌ skipped | `ELBSNSTopic` | `ELBSNSTopic` |

### IAM Roles (Sumo Logic Source Access)

| Logical ID | Type | Condition | Description |
|------------|------|-----------|-------------|
| `SumoLogicSourceRole` | `AWS::IAM::Role` | `install_sumo_logic_role` | IAM role for Sumo Logic to assume; grants CloudWatch Metrics read and resource tag access |
| `SumoLogicALBS3Policy` | `AWS::IAM::Policy` | `install_alb_logs_source` | S3 read permissions on the ALB logs bucket, attached to SumoLogicSourceRole |
| `SumoLogicELBS3Policy` | `AWS::IAM::Policy` | `install_elb_logs_source` | S3 read permissions on the ELB logs bucket, attached to SumoLogicSourceRole |
| `SumoLogicCloudTrailS3Policy` | `AWS::IAM::Policy` | `install_cloudtrail_logs_source` | S3 read permissions on the CloudTrail logs bucket, attached to SumoLogicSourceRole |

### CloudTrail

| Logical ID | Type | Condition | Description |
|------------|------|-----------|-------------|
| `CommonCloudTrail` | `AWS::CloudTrail::Trail` | `create_cloudtrail_trail` | CloudTrail trail writing to the S3 bucket (new or existing). Created when a CloudTrail bucket is provided. |

### Nested Stacks — CloudWatch Metrics

Three stacks split the namespace list to stay within CloudFormation resource limits.

| Logical ID | Template | Condition | Namespaces |
|------------|----------|-----------|------------|
| `CloudWatchMetricsFirstStack` | `cloudwatchmetrics.template.yaml` | `install_cloud_watch_metric_source` | ApplicationELB, ApiGateway, DynamoDB, Lambda, RDS, Custom |
| `CloudWatchMetricsSecondStack` | `cloudwatchmetrics.template.yaml` | `install_cloud_watch_metric_source` | ECS, ElastiCache, ELB, NetworkELB, EC2 |
| `CloudWatchMetricsThirdStack` | `cloudwatchmetrics.template.yaml` | `install_cloud_watch_metric_source` | SQS, SNS |

### Nested Stacks — Kinesis Firehose and Lambda Logs

| Logical ID | Template | Condition | Description |
|------------|----------|-----------|-------------|
| `KinesisFirehoseMetricsStack` | `kinesis_firehose_cw_metrics.template.yaml` | `install_kf_metric_source` | Kinesis Firehose delivery stream that forwards CloudWatch Metrics to Sumo Logic |
| `CloudWatchEventFunction` | `dlq_lambda_cloudformation.template.yaml` | `install_cloudwatch_logs_source` | Lambda log forwarder with DLQ; subscribes to CloudWatch Log Groups and forwards to Sumo Logic HTTP source |
| `KinesisFirehoseLogsStack` | `kinesis_firehose_cw_logs.template.yaml` | `install_kf_logs_source` | Kinesis Firehose delivery stream that forwards CloudWatch Logs to Sumo Logic |

---

## AutoEnableOptions — `auto_enable.template.yaml`

Orchestrates automatic enablement of S3 logging and CloudWatch Log Group subscriptions.

| Logical ID | Template | Condition | Description |
|------------|----------|-----------|-------------|
| `AutoEnableS3LogsAlbStack` | `s3_logging_auto_enable.template.yaml` | `auto_enable_s3_logs` | Deploys a Lambda that auto-enables S3 access logging on existing or new ALB resources |
| `AutoEnableS3LogsElbStack` | `s3_logging_auto_enable.template.yaml` | `auto_enable_s3_logs_elb` | Deploys a Lambda that auto-enables S3 access logging on existing or new Classic ELB resources |
| `AutoSubscribeLambdaLogGroupsAWSResources` | `loggroup_connector.template.yaml` | `auto_subscribe_log_groups` | Deploys a Lambda that auto-subscribes matching CloudWatch Log Groups to the Sumo Logic destination (Lambda or Kinesis Firehose) |

---

## sumoAppStacks — `apps.template.yaml`

Installs AWS Observability apps and the Explorer hierarchy view in Sumo Logic.

| Logical ID | Type | Condition | Description |
|------------|------|-----------|-------------|
| `CreateSumoLogicAWSExplorerView` | `Custom::SumoLogicAWSExplorer` | always | Creates the "AWS Observability" hierarchy view in Sumo Logic Explorer |
| `SumoAppAmazonOverview` | `Custom::AppV2` | `is_install_app` | Installs the "Amazon Overview" app (other apps depend on this completing first) |
| `SumoApp{Key}` (×14, via ForEach) | `Custom::AppV2` | `is_install_app` | Installs one app per iteration: AmazonElastiCache, AWSLambda, AmazonSNS, AmazonSQS, AWSApplicationLoadBalancer, AWSClassicLoadBalancer, AWSDynamoDB, AWSEC2, HostMetricsEC2, AmazonECS, AmazonECSWithCI, AWSNetworkLoadBalancer, AmazonRDS, AWSAPIGateway |

---

## Key Conditions Reference

| Condition | Evaluates True When |
|-----------|---------------------|
| `install_collector` | Any source is being created (OR of all `install_*` conditions) |
| `create_target_s3_bucket` | Any new S3 bucket is needed (ALB OR ELB OR CloudTrail) |
| `create_alb_bucket` | `CreateALBS3Bucket=Yes` AND `install_alb_logs_source` |
| `create_elb_bucket` | `CreateELBS3Bucket=Yes` AND `install_elb_logs_source` |
| `create_cloudtrail_bucket` | `CreateCloudTrailBucket=Yes` AND `install_cloudtrail_logs_source` |
| `create_alb_sns_topic` | NOT creating new ALB bucket AND installing ALB source |
| `create_elb_sns_topic` | NOT creating new ELB bucket AND installing ELB source |
| `create_cloudtrail_sns_topic` | NOT creating new CloudTrail bucket AND installing CloudTrail source |
| `install_sumo_logic_role` | Any S3-based source or metrics source is being installed |
| `create_cloudtrail_trail` | New CloudTrail bucket is created OR existing bucket name is provided |
| `needs_*_bucket_policy` | New bucket created OR existing bucket name is provided |
| `update_*_source` | An existing source API URL is provided (non-empty) |
| `call_auto_enable` | Any auto-enable option is enabled |
| `install_observability_apps` | `Section3aInstallObservabilityApps=Yes` |
| `send_telemetry_to_sumo` | `Section1fSumoLogicSendTelemetry=true` |
| `is_alb_bucket_provided` | `ALBS3LogsBucketName` is non-empty AND `create_alb_sns_topic` |
| `is_elb_bucket_provided` | `ELBS3LogsBucketName` is non-empty AND `create_elb_sns_topic` |
| `is_cloudtrail_bucket_provided` | `CloudTrailLogsBucketName` is non-empty AND `create_cloudtrail_sns_topic` |
| `alb_elb_same_bucket` | `is_alb_bucket_provided` AND `is_elb_bucket_provided` AND `ALBS3LogsBucketName == ELBS3LogsBucketName` |
| `alb_ct_same_bucket` | `is_alb_bucket_provided` AND `is_cloudtrail_bucket_provided` AND `ALBS3LogsBucketName == CloudTrailLogsBucketName` |
| `elb_ct_same_bucket` | NOT `alb_elb_same_bucket` AND `is_elb_bucket_provided` AND `is_cloudtrail_bucket_provided` AND `ELBS3LogsBucketName == CloudTrailLogsBucketName` |
| `elb_needs_own_bucket_notification` | `is_elb_bucket_provided` AND NOT `alb_elb_same_bucket` — skips `ELBBucketNotification` when ELB shares the ALB bucket |
| `ct_needs_own_bucket_notification` | `is_cloudtrail_bucket_provided` AND NOT `alb_ct_same_bucket` AND NOT `elb_ct_same_bucket` — skips `CloudTrailBucketNotification` when CT shares another source's bucket |
