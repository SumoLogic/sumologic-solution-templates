# AWSO Stack Execution Flow

## Scenarios

| # | Scenario | Key Parameters |
|---|----------|----------------|
| 1 | **Default** | `CreateALBLogSource=Yes`, `CreateALBS3Bucket=Yes` (new sources + new buckets) |
| 2 | **Existing Buckets** | `CreateALBLogSource=Yes`, `CreateALBS3Bucket=No`, `ALBS3LogsBucketName=<name>` |
| 3 | **Existing URLs** | `CreateALBLogSource=No`, `ALBLogsSourceApiUrl=<url>` |

---

## Stack Execution Order

| Order | Template | Stack Name | Default | Existing Bucket | Existing URL |
|-------|----------|------------|:-------:|:---------------:|:------------:|
| 1 | `sumologic_observability.master.template.yaml` | _(root stack)_ | ✅ | ✅ | ✅ |
| 2 | `resources.template.yaml` | `CreateCommonResources` | ✅ | ✅ | ✅ |
| 3 | `cloudwatchmetrics.template.yaml` | `CloudWatchMetricsFirstStack` | conditional | conditional | conditional |
| 4 | `cloudwatchmetrics.template.yaml` | `CloudWatchMetricsSecondStack` | conditional | conditional | conditional |
| 5 | `cloudwatchmetrics.template.yaml` | `CloudWatchMetricsThirdStack` | conditional | conditional | conditional |
| 6 | `kinesis_firehose_cw_metrics.template.yaml` | `KinesisFirehoseMetricsStack` | conditional | conditional | conditional |
| 7 | `dlq_lambda_cloudformation.template.yaml` | `CloudWatchEventFunction` | conditional | conditional | conditional |
| 8 | `kinesis_firehose_cw_logs.template.yaml` | `KinesisFirehoseLogsStack` | conditional | conditional | conditional |
| 9 | `auto_enable.template.yaml` | `AutoEnableOptions` | conditional | conditional | conditional |
| 10 | `s3_logging_auto_enable.template.yaml` | `AutoEnableS3LogsAlbStack` | conditional | conditional | conditional |
| 11 | `s3_logging_auto_enable.template.yaml` | `AutoEnableS3LogsElbStack` | conditional | conditional | conditional |
| 12 | `loggroup_connector.template.yaml` | `AutoSubscribeLambdaLogGroupsAWSResources` | conditional | conditional | conditional |
| 13 | `apps.template.yaml` | `sumoAppStacks` | conditional | conditional | conditional |

> Stacks 3–8 are children of `CreateCommonResources`.
> Stacks 10–12 are children of `AutoEnableOptions`.
> Stacks 3–13 are all conditional and independent of the ALB/ELB/CT source scenario — they depend on CW metrics, Kinesis, auto-enable, and app parameters.

---

## Key Resources in Root Stack

| Resource | Type | Condition | Default | Existing Bucket | Existing URL |
|----------|------|-----------|:-------:|:---------------:|:------------:|
| `LambdaRole` | `AWS::IAM::Role` | `send_telemetry_to_sumo` | ✅ | ✅ | ✅ |
| `TelemetryLambda` | `AWS::Lambda::Function` | `send_telemetry_to_sumo` | ✅ | ✅ | ✅ |
| `LambdaPermission` | `AWS::Lambda::Permission` | `send_telemetry_to_sumo` | ✅ | ✅ | ✅ |
| `PrimerInvoke` | `Custom::AWSPrimerInvoke` | `send_telemetry_to_sumo` | ✅ | ✅ | ✅ |
| `CreateCommonResources` | `AWS::CloudFormation::Stack` | always | ✅ | ✅ | ✅ |
| `AutoEnableOptions` | `AWS::CloudFormation::Stack` | `call_auto_enable` | conditional | conditional | conditional |
| `sumoAppStacks` | `AWS::CloudFormation::Stack` | `install_observability_apps` | conditional | conditional | conditional |

> `LambdaRole`, `TelemetryLambda`, `LambdaPermission`, and `PrimerInvoke` are present when `Section1fSumoLogicSendTelemetry=true` (the default). They are scenario-independent — telemetry fires regardless of the bucket/source strategy.

---

## Key Resources Inside CreateCommonResources (differ by scenario)

| Order | Resource | Condition | Default | Existing Bucket | Existing URL |
|-------|----------|-----------|:-------:|:---------------:|:------------:|
| 1 | `LambdaHelper` | always | ✅ | ✅ | ✅ |
| 2 | `AccountCheck` | always | ✅ | ✅ | ✅ |
| 3 | `AccountAliasValue` | always | ✅ | ✅ | ✅ |
| 4 | `SumoLogicSourceRole` | `install_sumo_logic_role` | ✅ | ✅ | ❌ |
| 5 | `SumoLogicALBS3Policy` | `install_alb_logs_source` | ✅ | ✅ | ❌ |
| 6 | `SumoLogicELBS3Policy` | `install_elb_logs_source` | ✅ | ✅ | ❌ |
| 7 | `SumoLogicCloudTrailS3Policy` | `install_cloudtrail_logs_source` | ✅ | ✅ | ❌ |
| 8 | `SumoLogicHostedCollector` | `install_collector` | ✅ | ✅ | ❌ |
| 9 | `CommonBucketSNSTopic` | `create_target_s3_bucket` | ✅ | ❌ | ❌ |
| 10 | `CommonSNSpolicy` | `create_target_s3_bucket` | ✅ | ❌ | ❌ |
| 11 | `CommonS3Bucket` | `create_target_s3_bucket` | ✅ | ❌ | ❌ |
| 12 | `ALBBucketPolicy` | `needs_alb_bucket_policy` | ✅ | ✅ | ❌ |
| 13 | `ELBBucketPolicy` | `needs_elb_bucket_policy` | ✅ | ✅ | ❌ |
| 14 | `CloudTrailBucketPolicy` | `needs_cloudtrail_bucket_policy` | ✅ | ✅ | ❌ |
| 15 | `ALBSource` | `install_alb_logs_source` | ✅ | ✅ | ❌ |
| 16 | `ELBSource` | `install_elb_logs_source` | ✅ | ✅ | ❌ |
| 17 | `CloudTrailSource` | `install_cloudtrail_logs_source` | ✅ | ✅ | ❌ |
| 18 | `ALBSNSSubscription` | `create_alb_bucket` | ✅ | ❌ | ❌ |
| 19 | `ELBSNSSubscription` | `create_elb_bucket` | ✅ | ❌ | ❌ |
| 20 | `CloudTrailSNSSubscription` | `create_cloudtrail_bucket` | ✅ | ❌ | ❌ |
| 21 | `BucketNotifications` | `any_existing_bucket_source` | ❌ | ✅ | ❌ |
| 22 | `CommonCloudTrail` | `create_cloudtrail_trail` | ✅ | ✅ | ❌ |
| 23 | `SumoALBLogsUpdateSource` | `update_alb_source` | ❌ | ❌ | ✅ |
| 24 | `SumoELBLogsUpdateSource` | `update_elb_source` | ❌ | ❌ | ✅ |
| 25 | `SumoCloudTrailLogsUpdateSource` | `update_cloudtrail_source` | ❌ | ❌ | ✅ |

> `BucketNotifications` (`Custom::ConfigureBucketNotifications`) replaces the 9 per-source SNS resources (`ALBSNSTopic`, `ALBSNSpolicy`, `ELBSNSTopic`, `ELBSNSpolicy`, `CloudTrailSNSTopic`, `CloudTrailSNSpolicy`, `ALBBucketNotification`, `ELBBucketNotification`, `CloudTrailBucketNotification`). It groups sources by bucket internally — sources sharing a bucket reuse a single SNS topic, satisfying S3's one-notification-per-event-type limit.
> `ALBSNSSubscription`, `ELBSNSSubscription`, `CloudTrailSNSSubscription` now only fire for the new-bucket case (`CommonBucketSNSTopic`). Existing-bucket subscriptions are managed by the `BucketNotifications` Lambda.

---

## Key Resources Inside AutoEnableOptions

### Direct resources (`auto_enable.template.yaml`)

| Resource | Condition | Default (New mode) | Existing Bucket (Existing mode) | Existing URL |
|----------|-----------|:------------------:|:-------------------------------:|:------------:|
| `AutoEnableS3LogsAlbStack` | `auto_enable_s3_logs` | ✅ | ✅ | ❌ |
| `AutoEnableS3LogsElbStack` | `auto_enable_s3_logs_elb` | ✅ | ✅ | ❌ |
| `AutoSubscribeLambdaLogGroupsAWSResources` | `auto_subscribe_new_log_groups` | conditional | conditional | conditional |

### Resources inside `AutoEnableS3LogsAlbStack` / `AutoEnableS3LogsElbStack` (`s3_logging_auto_enable.template.yaml`)

| Resource | Condition | New Mode | Existing Mode |
|----------|-----------|:--------:|:-------------:|
| `SumoLambdaRole` | always | ✅ | ✅ |
| `EnableNewAWSResourcesLambda` | `auto_enable_new` | ✅ | ❌ |
| `AutoEnableAlbLogEventsInvokePermission` | `enable_alb_log_events` (ALB stack only) | ✅ | ❌ |
| `AutoEnableAlbLogEventsRuleTrigger` | `enable_alb_log_events` (ALB stack only) | ✅ | ❌ |
| `AutoEnableElbLogEventsInvokePermission` | `enable_elb_log_events` (ELB stack only) | ✅ | ❌ |
| `AutoEnableElbLogEventsRuleTrigger` | `enable_elb_log_events` (ELB stack only) | ✅ | ❌ |
| `EnableExisitngAWSResourcesLambda` | `auto_enable_existing` | ❌ | ✅ |
| `ExistingAWSResources` | `auto_enable_existing` | ❌ | ✅ |

> **New mode** (`AutoEnableResourceOptions=New`): EventBridge rules watch for newly created ALBs/ELBs and trigger the Lambda to enable access logs automatically.
> **Existing mode** (`AutoEnableResourceOptions=Existing`): Lambda runs once at deploy time to enable access logs on all pre-existing ALBs/ELBs in the account.
