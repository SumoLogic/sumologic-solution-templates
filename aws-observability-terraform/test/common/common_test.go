package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)
// TODO: Replace with command line arguements

	 var accountAlias = fmt.Sprintf("infra-test-%s", strings.ToLower(random.UniqueId()))
	 var sumologicAccessKey = ""
	 var sumologicEnvironment = "us2"
	 var sumologicAccessID = ""
	 var sumoLogicOrganizationId = ""

func CommonResources(){


  //Verify S3 Common Bucket Output
  bucketName := terraform.Output(t, terraformOptions, "common-bucket-name")
  assert.contains(t, "aws-observability-logs-",bucketName)

  //Verify S3 Bucket Existence
  aws.AssertS3BucketExists(t, awsRegion, bucketName)

  //Verify ALB SNS Topic Subscription
  albSNSTopicName := terraform.Output(t, terraformOptions, "alb-sns-topic-name")
  assert.Contains(t, [fmt.Sprintf("arn:aws:sns:%s:", strings.ToLower(awsRegion),fmt.Sprintf("sumo-sns-topic-%s", accountAlias)], albSNSTopicName)

  // Verify Cloudtrail SNS topic subscription 
  cloudTrailSNSSubscription :=	terraform.Output(t, terraformOptions, "cloudtrail-sns-subscription")
  assert.Contains(t, [fmt.Sprintf("arn:aws:sns:%s:", strings.ToLower(awsRegion),fmt.Sprintf("sumo-sns-topic-%s", accountAlias)], cloudTrailSNSSubscription)

  //TODO: Verify cloudtrail source 

  //TODO: Verify ALB Source

  //TODO: Account Check

  //TODO: HTTP Source 

  //Verify S3 Policy Exxistence 
  aws.AssertS3BucketPolicyExists(t,awsRegion,bucketPolicy)
  
  //Verify S3 Policy Output
  bucketPolicy := terraform.Output(t, terraformOptions, "common-bucket-policy")
  assert.contains(t, "SumoLogic-Aws-Observability-u-CommonBucketPolicy-", bucketPolicy)

  //Verify S3 SNS Topic
  commonBucketSNSTopic := terraform.Output(t, terraformOptions, "common-bucket-sns-topic-name") 
  assert.Contains(t, [fmt.Sprintf("arn:aws:sns:%s:", strings.ToLower(awsRegion),fmt.Sprintf("sumo-sns-topic-%s", accountAlias)], commonBucketSNSTopic)

  //Verify Cloudtrail bucket 
  commonCloudTrail := terraform.Output(t, terraformOptions, "cloudtrail-bucket-name")
  assert.contains(t, fmt.Sprintf("aws-observability-%s", accountAlias), commonCloudTrail)	

  //TODO: CreateSumoLogicAWSExplorerView	

  //Verify Lambda Helper
  lambdaHelper := terraform.Output(t, terraformOptions, "lambda-helper-name")
  assert.contains(t, fmt.Sprintf("SumoLogic-Aws-Observability-%s-LambdaHelper-",awsRegion), lambdaHelper)

  //Verify Lambda Role
  lambdaRole := terraform.Output(t, terraformOptions, "lambda-role-name")
  assert.contains(t, fmt.Sprintf("SumoLogic-Aws-Observability-%s-LambdaRole-",awsRegion), lambdaRole)


  //Verify CW Lambda 
  cloudwatchMetricsLambda := terraform.Output(t, terraformOptions, "cloudwatch-metrics-lambda-name")
  assert.contains(t, fmt.Sprintf("SumoLogic-Aws-Observabili-LambdaToDecideCWMetricsS-",sumoLogicSourceRole)


  //Verify IAM Role
  sumoLogicSourceRole := terraform.Output(t, terraformOptions, "sumologic-source-role")
  assert.contains(t, fmt.Sprintf("SumoLogic-Aws-Observability-us-SumoLogicSourceRole-",sumoLogicSourceRole)

  //TODO: SumoLogicHostedCollector	

 
}

func CWEventFunctions(){

 //Verify CW Deadletter Queue
 sumoCWDeadLetterQueue := terraform.Output(t, terraformOptions, "cw-deadletter-queue")
 assert.contains("https://sqs.us-east-1.amazonaws.com", sumoCWDeadLetterQueue)


 //Verify CW Email SNS Topic
 sumoCWEmailSNSTopic := terraform.Output(t, terraformOptions, "cw-deadletter-queue")
 arn:aws:sns:us-east-1:126661387613:SumoLogic-Aws-Observability-us-east-1-CreateCommonResources-IG-CloudWatchEventFunction-
 //Verify CW Events Lambda Permission
 sumoCWEventsInvokeLambdaPermission := terraform.Output(t, terraformOptions, "cw-events-invoke-lambda-permission-id")
 assert.contains(t, fmt.Sprintf(" SumoLogic-Aws-Observability-%s-CreateCommonResources-IG-SumoCWLambdaPermission-
 ",awsRegion), sumoCWEventsInvokeLambdaPermission)

 
 //
 sumoCWLambdaExecutionRole	:= terraform.Output(t, terraformOptions, "cw-lambda-execution-role-name")
 assert.contains(" SumoLogic-Aws-Observabili-SumoCWLambdaExecutionRol-", sumoCWLambdaExecutionRole)

 //
 sumoCWLogGroup := terraform.Output(t, terraformOptions, "cw-log-group-name")
 assert.contains("SumoCWLogGroup-", sumoCWLogGroup)

 //
 sumoCWLogSubsriptionFilter := terraform.Output(t, terraformOptions, "cw-log-subscription-filter-name")
 assert.contains(t, fmt.Sprintf(" SumoLogic-Aws-Observability-%s-CreateCommonResources-IG-CloudWatchEventFunction-
 ",awsRegion), sumoCWLogSubsriptionFilter)

 //
 sumoCWLogsLambda := terraform.Output(t, terraformOptions, "cw-logs-lambda-name")
 assert.contains("SumoCWLogsLambda-", sumoCWLogsLambda)

 //
 sumoCWProcessDLQLambda := terraform.Output(t, terraformOptions, "cw-process-dlq-lambda-name")
 assert.contains(" SumoLogic-Aws-Observabili-SumoCWProcessDLQSchedule-", sumoCWProcessDLQLambda)
 //
 sumoCWProcessDLQScheduleRule := terraform.Output(t, terraformOptions, "cw-dlq-schedule-rule-name")
 assert.contains(" SumoLogic-Aws-Observabili-SumoCWProcessDLQSchedule-", sumoCWProcessDLQScheduleRule)

 assert.contains(" SumoLogic-Aws-Observabili-SumoCWProcessDLQSchedule-", sumoCWProcessDLQScheduleRule)
} 

func CloudwatchStacks(){

}


func TestCommonAll(t *testing.T) {
  t.Parallel()
  
	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationId,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "true",
			"manage_cloudwatch_metrics_source": "true",
			"manage_alb_logs_source":           "true",
			"manage_alb_s3_bucket":             "true",
			"manage_cloudtrail_bucket":         "true",
			"m"
			"manage_cloudwatch_logs_source":    "true",
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
  terraform.InitAndApply(t, terraformOptions)
  
  CommonResources()

}

func TestCreateMetadata(t *testing.T) {
  t.Parallel()
  
	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationId,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "true",
			"manage_cloudwatch_metrics_source": "false",
			"manage_alb_logs_source":           "false",
			"manage_alb_s3_bucket":             "false",
			"manage_cloudtrail_bucket":         "false",
			"manage_cloudwatch_logs_source":    "false",
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
  terraform.InitAndApply(t, terraformOptions)
  
  CommonResources()
  
}


func TestCreateCWMetrics(t *testing.T) {
  t.Parallel()
  
	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationId,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "false",
			"manage_cloudwatch_metrics_source": "true",
			"manage_alb_logs_source":           "false",
			"manage_alb_s3_bucket":             "false",
			"manage_cloudtrail_bucket":         "false"
			"manage_cloudwatch_logs_source":    "false",
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
  terraform.InitAndApply(t, terraformOptions)
  
  CommonResources()
  CWEventFunctions()
  CWFirstStack()
  CWSecondStack()
  RootCauseMetrics()
  
}

func TestCreateCloudTrailWithBucket(t *testing.T) {
  t.Parallel()
  
	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationId,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "false",
			"manage_cloudwatch_metrics_source": "false",
			"manage_alb_logs_source":           "false",
			"manage_alb_s3_bucket":             "false",
			"manage_cloudtrail_bucket":         "true",
			"manage_cloudwatch_logs_source":    "false",
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
  terraform.InitAndApply(t, terraformOptions)
  
  CommonResources()
  
}

func TestCreateCWLogs(t *testing.T) {
  t.Parallel()
  
	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationId,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "false",
			"manage_cloudwatch_metrics_source": "false",
			"manage_alb_logs_source":           "false",
			"manage_alb_s3_bucket":             "false",
			"manage_cloudtrail_bucket":         "false",
			"manage_cloudwatch_logs_source":    "true",
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
  terraform.InitAndApply(t, terraformOptions)
  
  CommonResources()
  
}