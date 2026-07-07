# Test Cases

## Categories

| Category | Description | Test Cases |
|---|---|---|
| **`common/`** | No CW log source dependency — LB auto-enable, existing sources, apps-only, nothing-to-install | `nothing_to_install`, `only_apps_install`, `existing_cloudtrail_bucket`, `existing_cloudtrail_alb_source`, `existing_cloudtrail_elb_source`, `permission_checker`, `s3_bucket_retention`, `alb_auto_enable_existing`, `elb_auto_enable_existing`, `existing_source_with_alb_bucket`, `existing_source_with_elb_bucket`, `alb_new_elb_existing`, `elb_new_alb_existing` |
| **`kf/`** | Kinesis Firehose log source — **recommended path** | `default_param_no_alias_and_csv`, `default_param_no_cloudtrail_invalid_mapping_csv`, `default_param_no_cloudtrail_valid_mapping_csv`, `kinesis_firehose_all_sources`, `kinesis_firehose_all_sources_no_apps`, `only_cloudtrail_with_loggroup_tags`, `remove_on_delete_false`, `create_source_existing_bucket_existing_sources`, `no_metrics_source`, `kf_logs_subscribe_new_only` |
| **`cw/`** | CloudWatch Lambda Forwarder log source — legacy | `cw_metrics_lambda_log_forwarder`, `no_cloudtrail`, `tag_filters_for_cw_metric_source_with_custom_namespaces` |

---

## Test Case Comparison (vs `default_param_no_alias_and_csv`)

**Baseline (`default_param_no_alias_and_csv`):** Alias=infrat1, ALB=Both, ELB=Both, CW LogGroups=Both(pattern), CloudTrail=Yes(KF), Metrics=KF, CW Logs=KF, Apps=Yes, AutoSubscribe=Kinesis, Tags=none, CSV=none

### `no_cloudtrail`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | infrat4 |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | None |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | ALB + ELB + CW LogGroups |
| **ALB Auto-Enable** | Both (2 LBs) | New (1 LB) |
| **ELB Auto-Enable** | Both (2 LBs) | New (1 LB) |
| **CW LogGroups** | Existing + New | New only |
| **CloudTrail** | Yes (KF source) | No (disabled) |
| **Metrics Source** | KinesisFirehoseMetricsSource | CloudWatchMetricsSource (polling) |
| **CW Logs Source** | KinesisFirehoseLogsSource | CloudWatchLogsSource (Lambda Forwarder) |
| **Apps** | Yes | No |
| **Auto-Subscribe Dest** | Kinesis | Lambda |
| **Log Group Tags** | Not set | env=prod,creator=himan,team=app |

### `kinesis_firehose_all_sources`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | kfall |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | ALB + ELB + CW LogGroups |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | ALB + ELB + CW LogGroups |
| **ALB Auto-Enable** | Both (2 LBs) | Both (2 LBs) |
| **ELB Auto-Enable** | Both (2 LBs) | Both (2 LBs) |
| **CW LogGroups** | Existing + New | Existing + New |
| **CloudTrail** | Yes (KF source) | Yes (new source) |
| **Metrics Source** | KinesisFirehoseMetricsSource | KinesisFirehoseMetricsSource |
| **CW Logs Source** | KinesisFirehoseLogsSource | KinesisFirehoseLogsSource |
| **Apps** | Yes | Yes |
| **Auto-Subscribe Dest** | Kinesis | Kinesis |
| **Difference** | — | Nearly identical to baseline. Same assertion structure. |

### `cw_metrics_lambda_log_forwarder`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | cwllf |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | ALB + ELB + CW LogGroups |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | ALB + ELB + CW LogGroups |
| **ALB Auto-Enable** | Both (2 LBs) | Both (2 LBs) |
| **ELB Auto-Enable** | Both (2 LBs) | Both (2 LBs) |
| **CW LogGroups** | Existing + New | Existing + New |
| **CloudTrail** | Yes (KF source) | Yes (new source) |
| **Metrics Source** | KinesisFirehoseMetricsSource | CloudWatchMetricsSource (polling) |
| **CW Logs Source** | KinesisFirehoseLogsSource | CloudWatchLogsSource (Lambda Forwarder) |
| **Apps** | Yes | Yes |
| **Auto-Subscribe Dest** | Kinesis | Lambda |
| **Difference** | — | CW Metrics + Lambda Forwarder instead of Kinesis Firehose |

### `only_cloudtrail_with_loggroup_tags`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | infrat6 |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | None (auto-enable is "New") |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | ALB + ELB (no CW LogGroups — subscribe Existing only) |
| **ALB Auto-Enable** | Both (2 LBs) | New (1 LB) |
| **ELB Auto-Enable** | Both (2 LBs) | New (1 LB) |
| **CW LogGroups** | Existing + New | Existing only (PreRequisitesInfra creates, no PostRequisites) |
| **CloudTrail** | Yes (KF source) | Yes (new source) |
| **Metrics Source** | KinesisFirehoseMetricsSource | KinesisFirehoseMetricsSource |
| **CW Logs Source** | KinesisFirehoseLogsSource | KinesisFirehoseLogsSource |
| **Apps** | Yes | No |
| **Auto-Subscribe Dest** | Kinesis | Kinesis |
| **Auto-Subscribe Option** | Both | Existing |
| **Log Group Tags** | Not set | env=prod,creator=himan,team=app |
| **ALB/ELB sources** | Created new | Not created (No) |
| **Custom namespaces** | Standard | Includes `cwgent` |
| **Difference** | — | Tags-based subscription, Existing-only CW LogGroups, no ALB/ELB source creation |

### `existing_cloudtrail_alb_source`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | infrat8 |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | S3 bucket + Sumo collector/sources (pre-creates ALB+CloudTrail+Metrics sources) |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | ALB only (triggers auto-enable on new ALB) |
| **ALB Auto-Enable** | Both (2 LBs) | Both (existing + new) |
| **ELB Auto-Enable** | Both (2 LBs) | None |
| **CW LogGroups** | Existing + New | None |
| **CloudTrail** | Yes (KF source) | No (uses existing pre-created source) |
| **Metrics Source** | KinesisFirehoseMetricsSource | KinesisFirehoseMetricsSource (with new S3 bucket) |
| **CW Logs Source** | KinesisFirehoseLogsSource | None |
| **Apps** | Yes | Yes |
| **ALB Source** | Created new | Uses existing (`Section5cALBLogsSourceUrl`) |
| **Difference** | — | Tests existing source reuse. No ELB, no CW logs, no CloudTrail source queries |

### `existing_cloudtrail_elb_source`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | infrat10 |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | S3 bucket + Sumo collector/sources (pre-creates ELB+CloudTrail+Metrics sources) |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | ELB only (triggers auto-enable on new ELB) |
| **ALB Auto-Enable** | Both (2 LBs) | None |
| **ELB Auto-Enable** | Both (2 LBs) | Both (existing + new) |
| **CW LogGroups** | Existing + New | None |
| **CloudTrail** | Yes (KF source) | No (uses existing pre-created source) |
| **Metrics Source** | KinesisFirehoseMetricsSource | KinesisFirehoseMetricsSource (with new S3 bucket) |
| **CW Logs Source** | KinesisFirehoseLogsSource | None |
| **Apps** | Yes | Yes |
| **ELB Source** | Created new | Uses existing (`Section8cELBLogsSourceUrl`) |
| **Difference** | — | Mirror of existing_cloudtrail_alb_source but for ELB |

### `existing_cloudtrail_bucket`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | infrat9 |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | S3 bucket (for CloudTrail) |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | None |
| **ALB Auto-Enable** | Both (2 LBs) | None |
| **ELB Auto-Enable** | Both (2 LBs) | None |
| **CW LogGroups** | Existing + New | None |
| **CloudTrail** | Yes (KF source) | Yes (existing bucket, custom path `*abc*`) |
| **Metrics Source** | KinesisFirehoseMetricsSource | CloudWatchMetricsSource (polling) |
| **CW Logs Source** | KinesisFirehoseLogsSource | None |
| **Apps** | Yes | No |
| **Difference** | — | Tests CloudTrail with existing S3 bucket. No auto-enable, no CW logs, no apps |

### `nothing_to_install`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | infrat5 |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | None |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | None |
| **ALB Auto-Enable** | Both | None |
| **ELB Auto-Enable** | Both | None |
| **CW LogGroups** | Existing + New | None |
| **CloudTrail** | Yes | No |
| **Metrics Source** | KinesisFirehoseMetricsSource | None |
| **CW Logs Source** | KinesisFirehoseLogsSource | None |
| **Apps** | Yes | No |
| **E2E Assertions** | Full | None (HEALTH only — minimal resource check) |
| **Difference** | — | Everything disabled. Only validates base Lambda infrastructure deploys |

### `only_apps_install`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | appsonly |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | None |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | None |
| **ALB Auto-Enable** | Both | None |
| **ELB Auto-Enable** | Both | None |
| **CW LogGroups** | Existing + New | None |
| **CloudTrail** | Yes | No |
| **Metrics Source** | KinesisFirehoseMetricsSource | None |
| **CW Logs Source** | KinesisFirehoseLogsSource | None |
| **Apps** | Yes | Yes (only feature enabled) |
| **E2E Assertions** | Full | SumoAppInstallationValidation only |
| **Difference** | — | Only installs apps. No sources, no auto-enable. Validates apps deploy independently |

### `remove_on_delete_false`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | nodelete |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | None |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | None |
| **ALB Auto-Enable** | Both | None |
| **ELB Auto-Enable** | Both | None |
| **CW LogGroups** | Existing + New | Both (auto-subscribe) |
| **CloudTrail** | Yes (KF) | Yes (new source) |
| **Metrics Source** | KinesisFirehoseMetricsSource | KinesisFirehoseMetricsSource |
| **CW Logs Source** | KinesisFirehoseLogsSource | KinesisFirehoseLogsSource |
| **Apps** | Yes | Yes |
| **RemoveOnDeleteStack** | true | **false** |
| **E2E Assertions** | Full | SumoSourceExistence + SumoApp + **SumoSourcePreservedAfterDelete** |
| **Difference** | — | Tests that Sumo Logic resources (collector, sources, apps) are NOT deleted when stack is cleaned up with RemoveOnDeleteStack=false |

### `kinesis_firehose_all_sources_no_apps`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | kfnoapp |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | ALB + ELB + CW LogGroups |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | ALB + ELB + CW LogGroups |
| **ALB Auto-Enable** | Both (2 LBs) | Both (2 LBs) |
| **ELB Auto-Enable** | Both (2 LBs) | Both (2 LBs) |
| **CW LogGroups** | Existing + New | Existing + New |
| **CloudTrail** | Yes (KF source) | Yes (new source) |
| **Metrics Source** | KinesisFirehoseMetricsSource | KinesisFirehoseMetricsSource |
| **CW Logs Source** | KinesisFirehoseLogsSource | KinesisFirehoseLogsSource |
| **Apps** | Yes | No |
| **Auto-Subscribe Dest** | Kinesis | Kinesis |
| **Difference** | — | Identical to baseline but apps disabled. Tests all sources deploy independently of apps |

### `default_param_no_cloudtrail_invalid_mapping_csv`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | infrat2 |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | ALB + ELB + CW LogGroups |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | ALB + ELB + CW LogGroups |
| **ALB/ELB Auto-Enable** | Both | Both (defaults) |
| **CloudTrail** | Yes (KF) | Yes (defaults) |
| **Metrics Source** | KinesisFirehoseMetricsSource | KinesisFirehoseMetricsSource (defaults) |
| **CW Logs Source** | KinesisFirehoseLogsSource | KinesisFirehoseLogsSource (defaults) |
| **Apps** | Yes | Yes (defaults) |
| **Mapping CSV** | None | Invalid CSV URL |
| **AccountAlias** | infrat2 (from parameter) | Resolves to "" (CSV invalid, fallback fails) |
| **Difference** | — | Tests invalid CSV fallback. Same assertion structure, but AccountAlias check differs |

### `default_param_no_cloudtrail_valid_mapping_csv`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | infrat3 |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | ALB + ELB + CW LogGroups |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | ALB + ELB + CW LogGroups |
| **ALB/ELB Auto-Enable** | Both | Both (defaults) |
| **CloudTrail** | Yes (KF) | Yes (defaults) |
| **Metrics Source** | KinesisFirehoseMetricsSource | KinesisFirehoseMetricsSource (defaults) |
| **CW Logs Source** | KinesisFirehoseLogsSource | KinesisFirehoseLogsSource (defaults) |
| **Apps** | Yes | Yes (defaults) |
| **Mapping CSV** | None | Valid CSV URL |
| **AccountAlias** | infrat3 (from parameter) | Resolves from CSV mapping |
| **Difference** | — | Tests valid CSV mapping. Same assertion structure, AccountAlias from CSV |

### `tag_filters_for_cw_metric_source_with_custom_namespaces`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | infrat11 |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | S3 bucket (for CloudTrail) + CW LogGroups |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | CW LogGroups (auto-subscribe Both) |
| **ALB Auto-Enable** | Both | None |
| **ELB Auto-Enable** | Both | None |
| **CW LogGroups** | Existing + New (pattern) | Existing + New (tags: env=prod,creator=himan,team=app) |
| **CloudTrail** | Yes (KF) | Yes (existing bucket, path `*abc*`) |
| **Metrics Source** | KinesisFirehoseMetricsSource | CloudWatchMetricsSource (polling) |
| **CW Logs Source** | KinesisFirehoseLogsSource | CloudWatchLogsSource (Lambda Forwarder) |
| **Apps** | Yes | No |
| **Custom namespaces** | Standard | Includes `cwgent` |
| **Tag Filters** | None | JSON tag filter per namespace (`Section4dAWSMetricsTagFilters`) |
| **Difference** | — | CW Metrics with tag filters + custom namespace. No auto-enable for LBs |

### `no_metrics_source`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | nometrics |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | CW LogGroups (existing) |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | CW LogGroups (new, WaitSeconds:30) |
| **ALB Auto-Enable** | Both (2 LBs) | None |
| **ELB Auto-Enable** | Both (2 LBs) | None |
| **CW LogGroups** | Existing + New | Existing + New |
| **CloudTrail** | Yes (KF source) | Yes (new source) |
| **Metrics Source** | KinesisFirehoseMetricsSource | **None** (Section4a=None) |
| **CW Logs Source** | KinesisFirehoseLogsSource | KinesisFirehoseLogsSource |
| **Apps** | Yes | Yes |
| **Auto-Subscribe Option** | Both | Both |
| **Difference** | — | Tests the case where metrics collection is fully disabled. Only CloudTrail + KF Logs + Apps |

### `alb_new_elb_existing`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | albewelb |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | ELB only (existing LB for Existing mode) |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | ALB only (new LB for New mode) |
| **ALB Auto-Enable** | Both (2 LBs) | **New** (1 LB) |
| **ELB Auto-Enable** | Both (2 LBs) | **Existing** (1 LB) |
| **CW LogGroups** | Existing + New | None |
| **CloudTrail** | Yes (KF source) | No |
| **Metrics Source** | KinesisFirehoseMetricsSource | KinesisFirehoseMetricsSource |
| **CW Logs Source** | KinesisFirehoseLogsSource | None |
| **Apps** | Yes | No |
| **Difference** | — | Mixed auto-enable: ALB=New + ELB=Existing. Tests that New uses EventBridge rule while Existing uses Lambda invocation |

### `elb_new_alb_existing`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | elbwealb |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | ALB only (existing LB for Existing mode) |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | ELB only (new LB for New mode) |
| **ALB Auto-Enable** | Both (2 LBs) | **Existing** (1 LB) |
| **ELB Auto-Enable** | Both (2 LBs) | **New** (1 LB) |
| **CW LogGroups** | Existing + New | None |
| **CloudTrail** | Yes (KF source) | No |
| **Metrics Source** | KinesisFirehoseMetricsSource | KinesisFirehoseMetricsSource |
| **CW Logs Source** | KinesisFirehoseLogsSource | None |
| **Apps** | Yes | No |
| **Difference** | — | Mirror of `alb_new_elb_existing` with ALB and ELB roles swapped. ALB=Existing + ELB=New |

### `kf_logs_subscribe_new_only`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | kfnew |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | None |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | ALB + ELB + CW LogGroups (all WaitSeconds:30) |
| **ALB Auto-Enable** | Both (2 LBs) | New (1 LB) |
| **ELB Auto-Enable** | Both (2 LBs) | New (1 LB) |
| **CW LogGroups** | Existing + New | **New only** (Section7c=New) |
| **CloudTrail** | Yes (KF source) | No |
| **Metrics Source** | KinesisFirehoseMetricsSource | KinesisFirehoseMetricsSource |
| **CW Logs Source** | KinesisFirehoseLogsSource | KinesisFirehoseLogsSource |
| **Apps** | Yes | No |
| **Auto-Subscribe Option** | Both | **New** (UseExistingLogs=false) |
| **Auto-Subscribe Dest** | Kinesis | Kinesis |
| **Log Group Tags** | Not set | env=prod,creator=himan,team=app |
| **Difference** | — | KF mirror of `no_cloudtrail` (cw/). Section7c=New-only subscribe. No pre-existing log groups |

### `create_source_existing_bucket_existing_sources`

| Aspect | Baseline | This Test Case |
|---|---|---|
| **Alias** | infrat1 | infrat7 |
| **PreRequisitesInfra** | ALB + ELB + CW LogGroups | S3 bucket (shared for ALB/CloudTrail/ELB) |
| **PostRequisitesInfra** | ALB + ELB + CW LogGroups | CW LogGroups (auto-subscribe Both) |
| **ALB Auto-Enable** | Both | None |
| **ELB Auto-Enable** | Both | None |
| **CW LogGroups** | Existing + New | Existing + New |
| **CloudTrail** | Yes (KF) | Yes (existing source + existing bucket) |
| **Metrics Source** | KinesisFirehoseMetricsSource | CloudWatchMetricsSource (existing source URL) |
| **CW Logs Source** | KinesisFirehoseLogsSource | Both (Switch from Lambda to KF) |
| **Apps** | Yes | No |
| **ALB Source** | Created new | Uses existing (`Section5cALBLogsSourceUrl`) |
| **ELB Source** | Created new | Uses existing (`Section8cELBLogsSourceUrl`) |
| **CloudTrail Source** | Created new | Uses existing (`Section6bCloudTrailLogsSourceUrl`) |
| **CW Logs Source** | Created new | Uses existing (`Section7bCloudWatchLogsSourceUrl`) + creates KF |
| **ScanInterval** | 300000 (default) | 30000 (10x faster) |
| **Difference** | — | Most complex. All sources pre-existing. Tests migration path (Lambda→KF) |

## SourceQueryFilters by Test Case

| Test Case | CloudtrailSourceQueries | Metrics Queries | CW Logs Queries |
|---|---|---|---|
| `default_param_no_alias_and_csv` | lambda, ALBv2(2015-12-01), ELB(2012-06-01) | KF: namespace=ApplicationELB,ELB,Lambda,EC2 | KF: namespace=aws/lambda |
| `no_cloudtrail` | — (disabled) | CW: namespace=EC2,ApplicationELB,ELB | CWLogs: matches lambda |
| `kinesis_firehose_all_sources` | lambda, ALBv2(2015-12-01), ELB(2012-06-01) | KF: namespace=ApplicationELB,ELB,Lambda,EC2 | KF: namespace=aws/lambda |
| `cw_metrics_lambda_log_forwarder` | lambda, ALBv2(2015-12-01), ELB(2012-06-01) | CW: namespace=EC2,ApplicationELB,ELB | CWLogs: matches lambda |
| `only_cloudtrail_with_loggroup_tags` | lambda | KF: namespace=ApplicationELB,ELB,EC2 | KF: namespace=aws/lambda |
| `existing_cloudtrail_alb_source` | — (existing source) | KF: namespace=ApplicationELB,EC2 | — |
| `existing_cloudtrail_elb_source` | — (existing source) | KF: namespace=ELB,EC2 | — |
| `existing_cloudtrail_bucket` | lambda | CW: namespace=EC2 | — |
| `nothing_to_install` | — | — | — |
| `only_apps_install` | — | — | — |
| `kinesis_firehose_all_sources_no_apps` | lambda, ALBv2(2015-12-01), ELB(2012-06-01) | KF: namespace=ApplicationELB,ELB,Lambda,EC2 | KF: namespace=aws/lambda |
| `remove_on_delete_false` | — | — | — (validates sources PRESERVED after cleanup) |
| `default_param_no_cloudtrail_invalid_mapping_csv` | lambda, ALBv2, ELB | KF: namespace=ApplicationELB,ELB,Lambda,EC2 | KF: namespace=aws/lambda |
| `default_param_no_cloudtrail_valid_mapping_csv` | lambda, ALBv2, ELB | KF: namespace=ApplicationELB,ELB,Lambda,EC2 | KF: namespace=aws/lambda |
| `tag_filters_for_cw_metric_source_with_custom_namespaces` | lambda | CW: namespace=EC2,cwgent | CWLogs: matches lambda |
| `create_source_existing_bucket_existing_sources` | lambda | CW: namespace=EC2 | KF: namespace=aws/lambda + CWLogs: matches lambda |
| `no_metrics_source` | lambda | — (no metrics source) | KF: namespace=aws/lambda |
| `alb_new_elb_existing` | — | KF: namespace=ApplicationELB,ELB,EC2 | — |
| `elb_new_alb_existing` | — | KF: namespace=ApplicationELB,ELB,EC2 | — |
| `kf_logs_subscribe_new_only` | — | KF: namespace=EC2,ApplicationELB,ELB | KF: namespace=aws/lambda |

## Parameter → Assertion Mapping

### Auto-Enable Options

| `Section5a` (ALB) / `Section8a` (ELB) | PreRequisitesInfra | PostRequisitesInfra | LoadBalancers Count |
|---|---|---|---|
| `Both` | Create existing LB | Create new LB | 2 |
| `Existing` | Create existing LB | None | 1 |
| `New` | None | Create new LB | 1 |
| `None` | None | None | 0 (skip assertion) |

### CloudWatch LogGroups (`Section7c`)

| `Section7c` | ExistingLogGroups | NewLogGroups |
|---|---|---|
| `Both` | Yes (PreRequisitesInfra) | Yes (PostRequisitesInfra) |
| `Existing` | Yes (PreRequisitesInfra) | No |
| `New` | No | Yes (PostRequisitesInfra) |
| `None` | No | No (skip assertion) |

### Source Types

| `Section4a` (Metrics) | Source Created | ContentType | SourceQueryFilters Key |
|---|---|---|---|
| `CloudWatch Metrics Source` | `cloudwatch-metrics-<REGION>-<NS>` (Polling) | `AwsCloudWatch` | `CloudWatchMetricsSourceQueries` |
| `Kinesis Firehose Metrics Source` | `cloudwatch-metrics-<REGION>` (HTTP) | `KinesisMetric` | `KinesisFirehoseMetricsSourceQueries` |
| `None` | — | — | Skip |

| `Section7a` (CW Logs) | Source Created | ContentType | SourceQueryFilters Key |
|---|---|---|---|
| `Lambda Log Forwarder` | `cloudwatch-logs-<REGION>` (HTTP) | (empty) | `CloudWatchLogsSourceQueries` |
| `Kinesis Firehose Log Source` | `kinesis-firehose-cloudwatch-logs-<REGION>` (HTTP) | `KinesisLog` | `KinesisFirehoseLogsSourceQueries` |
| `Both` | Both created | Both | Both keys available |
| `None` | — | — | Skip |

### Auto-Subscribe Destination (`Section7c` + `Section7a`)

| `Section7a` | Destination Type | Expected Subscription ARN |
|---|---|---|
| `Kinesis Firehose Log Source` | Kinesis | `KinesisLogsDeliveryStreamARN` from stack output |
| `Lambda Log Forwarder` | Lambda | `CloudWatchLambdaARN` from stack output |

### CloudTrail (`Section6a`)

| `Section6a` | CloudtrailSourceQueries |
|---|---|
| `Yes` (new source) | lambda, ALBv2, ELB event sources |
| `No` | Skip — no source to query |
| Existing source (`Section6bCloudTrailLogsSourceUrl` set) | Skip — source is pre-created, not by AWSO |

### Apps (`Section3a`)

| `Section3a` | SumoAppInstallationValidation |
|---|---|
| `Yes` | Run |
| `No` | Skip |
