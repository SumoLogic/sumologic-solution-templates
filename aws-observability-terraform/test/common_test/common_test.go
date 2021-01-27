package test

import (
	"fmt"
	"testing"
	"time"
	"os"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)
	 var accountAlias = os.Getenv("ACCOUNT_ALIAS")
	 var sumologicAccessKey = os.Getenv("SUMOLOGIC_ACCESSKEY")
	 var sumologicEnvironment = os.Getenv("SUMOLOGIC_ENVIRONMENT")
	 var sumologicAccessID = os.Getenv("SUMOLOGIC_ACCESSID")

	 var sumoLogicOrganizationID = os.Getenv("SUMOLOGIC_ORGANIZATIONID")
	 var awsRegion = os.Getenv("AWS_REGION")

func TestCommonAll(t *testing.T) {


 // ========== Test Setup ==========

  t.Parallel()
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../terraform-aws-observability-common/",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationID,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "true",
			"manage_cloudwatch_metrics_source": "true",
			"manage_alb_logs_source":           "true",
			"manage_alb_s3_bucket":             "true",
			"manage_cloudtrail_bucket":         "true",
			"manage_cloudwatch_logs_source":    "true",
			"manage_aws_inventory_source":		"true",
			"manage_aws_xray_source":			"true",
		},

		EnvVars: map[string]string{
			"AWS_REGION": awsRegion,
			"SUMOLOGIC_ACCESSID": sumologicAccessID,
			"SUMOLOGIC_ACCESSKEY": sumologicAccessKey,
			"SUMOLOGIC_ENVIRONMENT": sumologicEnvironment,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	
	  _, err := terraform.InitAndApplyE(t,terraformOptions)
	// This added loop is required as of sumologic provider version 2.6.3 due to a bug
	 if err != nil {
		for err != nil {
		time.Sleep(1 * time.Minute)
		_, err = terraform.ApplyE(t,terraformOptions)
		}
	} 
   
  // ========== Mapping Terraform Outputs ==========

  s3BucketMap 				:= terraform.OutputMapOfObjects(t, terraformOptions,"common_bucket")
  cwMetricsNamespaces 		:= terraform.OutputList(t,terraformOptions,"cloudwatch_metrics_namespaces")
  albSNSTopicName 			:= terraform.Output(t, terraformOptions, "alb_sns_topic_name")
  cloudTrailSNSSubscription :=	terraform.Output(t, terraformOptions, "aws_sns_topic_policy_cloudtrail_name")
  cwLogs 					:= terraform.Output(t, terraformOptions, "aws_cloudwatch_logs_name")
  iamPolicyCWLambda 		:= terraform.Output(t, terraformOptions, "aws_iam_policy_cw_logs_source_lambda_lambda_name")
  iamPolicyCWSQS 			:= terraform.Output(t, terraformOptions, "aws_iam_policy_cw_logs_source_lambda_sqs_name")
  iamPolicySumoInventory 	:= terraform.Output(t, terraformOptions, "aws_iam_policy_sumologic_inventory_name")
  iamPolicySumoSource 		:= terraform.Output(t, terraformOptions, "aws_iam_policy_sumologic_source_name")
  iamRoleCWLambdaLogs 		:= terraform.Output(t, terraformOptions, "aws_iam_role_cw_logs_source_lambda_logs_name") 
  iamRoleCWExecutionLambda  := terraform.Output(t, terraformOptions, "aws_iam_role_cw_logs_source_lambda_name")
  iamRoleSumoSource 	    := terraform.Output(t, terraformOptions, "aws_iam_role_sumologic_source_name")
  lambdaCWLogs 				:= terraform.Output(t, terraformOptions, "aws_lambda_function_cloudwatch_logs_source")
  lambdaCWProcessDLQ 		:= terraform.Output(t, terraformOptions, "aws_lambda_function_cloudwatch_logs_source_process_deadletter")
  cwSNSTopicEmail       	:= terraform.Output(t, terraformOptions, "aws_sns_topic_cloudwatch_logs_source_email")
  cwSQSDeadletterSource 	:= terraform.Output(t, terraformOptions, "aws_sqs_queue_cloudwatch_logs_source_deadletter")
  cloudTrailCommon  		:= terraform.Output(t, terraformOptions, "cloudtrail_common_name")
  commonSNSTopic    		:= terraform.Output(t, terraformOptions, "common_sns_topic_name")
  inventorySource   		:= terraform.Output(t, terraformOptions, "sumologic_aws_inventory_source_name")
  metadataSource    		:= terraform.Output(t, terraformOptions, "sumologic_aws_metadata_source_name")
  xraySource         		:= terraform.Output(t, terraformOptions, "sumologic_aws_xray_source_name")
  collector         		:= terraform.Output(t, terraformOptions, "sumologic_collector_name")
  elbSource          		:= terraform.Output(t, terraformOptions, "sumologic_elb_source")


// ========== Running Tests ===========

  //Verify Common S3 Bucket 
  t.Run("Verify Common S3 Bucket Existence", func (t *testing.T){

	  assert.Contains(t, s3BucketMap["this"].(map[string]interface{})["bucket"],fmt.Sprintf("aws-observability-logs-%s-us-east-1",accountAlias))
  })

  t.Run("Verify Common S3 Bucket Region", func (t *testing.T){

	assert.Contains(t, s3BucketMap["this"].(map[string]interface{})["region"],awsRegion)
})

  //Verify ALB SNS Topic Subscription  
   t.Run("Verify ALB SNS Topic Subscription", func (t *testing.T){
	assert.Contains(t, albSNSTopicName,fmt.Sprintf("alb-sumo-sns-%s", accountAlias))
  })


  // Verify Cloudtrail SNS topic subscription 
 t.Run("Verify Cloudtrail SNS Topic Subscription", func (t *testing.T){
	assert.Contains(t, cloudTrailSNSSubscription, fmt.Sprintf("sumo-sns-topic-%s", accountAlias))
  })

  //Verify Cloudwatch logs
  t.Run("Verify Cloudwatch logs", func (t *testing.T){
	assert.Contains(t, cwLogs, fmt.Sprintf("%s-cloudwatch-logs", accountAlias))
  })

  //Verify Cloudwatch log source lambda IAM Policy
  t.Run("Verify Cloudwatch lambda IAM Policy", func (t *testing.T){
	assert.Contains(t, iamPolicyCWLambda, fmt.Sprintf("InvokeLambda-%s", awsRegion))
  })
  
  //Verify Cloudwatch lambda SQS IAM Policy
  t.Run("Verify Cloudwatch Lambda SQS", func (t *testing.T){
	assert.Contains(t, iamPolicyCWSQS, fmt.Sprintf("SQSCreateLogs-%s", awsRegion))
  })

  //Verify Sumologic Inventory IAM Policy
  t.Run("Verify Sumologic Inventory IAM Policy", func (t *testing.T){
	assert.Contains(t, iamPolicySumoInventory, fmt.Sprintf("SumoInventory-%s", awsRegion))
  })

  //Verify Sumologic Source IAM Policy
  t.Run("Verify Sumologic Source IAM Policy", func (t *testing.T){
	assert.Contains(t, iamPolicySumoSource, fmt.Sprintf("SumoLogicAwsSources-%s", awsRegion))
  })

  //Verify Cloudwatch lambda logs IAM Role
  t.Run("Verify Cloudwatch Lambda Logs IAM Role ", func (t *testing.T){
	assert.Contains(t, iamRoleCWLambdaLogs, fmt.Sprintf("CloudWatchCreateLogs-%s", awsRegion))
  })

    //Verify Cloudwatch lambda execution IAM Role
  t.Run("Verify Cloudwatch Lambda Execution IAM Role", func (t *testing.T){
	 assert.Contains(t, iamRoleCWExecutionLambda, fmt.Sprintf("SumoCWLambdaExecutionRole-%s", awsRegion))
  })

    //Verify Sumologic source IAM Role
  t.Run("Verify Sumologic Source IAM Role", func (t *testing.T){
	 assert.Contains(t, iamRoleSumoSource, fmt.Sprintf("SumoLogicSource-%s", awsRegion))
  })

  //Verify Cloudwatch logs Lambda
  t.Run("Verify Cloudwatch Logs Lambda", func (t *testing.T){
	assert.Contains(t, lambdaCWLogs, "SumoCWLogsLambda")
  })

  //Verify Cloudwatch Process DLQ Lambda
  t.Run("Verify Cloudwatch Process DLQ Lambda", func (t *testing.T){
	assert.Contains(t, lambdaCWProcessDLQ, "SumoCWProcessDLQLambda")
  })

  //Verify Cloudwatch Email SNS Topic
  t.Run("Verify Cloudwatch Email SNS Topic ", func (t *testing.T){
	assert.Contains(t, cwSNSTopicEmail, "SumoCWEmailSNSTopic")
  })

  //Verify Cloudwatch SQS Deadletter Source
  t.Run("Verify Cloudwatch SQS Deadletter Source", func (t *testing.T){
	assert.Contains(t, cwSQSDeadletterSource, "SumoCWDeadLetterQueue")
  })

  //Verify Cloudtrail common bucket
  t.Run("Verify Cloudtrail bucket ", func (t *testing.T){
	assert.Contains(t, cloudTrailCommon, fmt.Sprintf("Aws-Observability-%s", accountAlias))
  })

  //Verify S3 SNS Topic
  t.Run("Verify S3 SNS Topic ", func (t *testing.T){
	assert.Contains(t, commonSNSTopic, fmt.Sprintf("sumo-sns-topic-%s", accountAlias))
  })

  //Verify SumoLogic Inventory Source
  t.Run("Verify Sumologic Inventory Source", func (t *testing.T){
	assert.Contains(t, inventorySource, fmt.Sprintf("%s-inventory-aws", accountAlias))
  })

  //Verify Metadata Source
  t.Run("Verify Metadata Source", func (t *testing.T){
	assert.Contains(t, metadataSource, fmt.Sprintf("%s-metadata-", accountAlias))
  })

  //Verify XRay Source
  t.Run("Verify Xray Source ", func (t *testing.T){
	assert.Contains(t, xraySource, fmt.Sprintf("%s-xray-aws-us-", accountAlias))
  })

  //Verify Collector
  t.Run("Verify Collector ", func (t *testing.T){
	assert.Contains(t, collector, fmt.Sprintf("aws-observability-%s", accountAlias))
  })

  //Verify ELB Source
  t.Run("Verify ELB Source ", func (t *testing.T){
	assert.Contains(t, elbSource, fmt.Sprintf("%s-alb-logs-us", accountAlias))
  })

 //Verify 9 CW Metrics Namespaces
t.Run("Verify CW Metrics Namespaces", func (t *testing.T){

	 cwMetrics := [9]string{"AWS/ApplicationELB", "AWS/ApiGateway", "AWS/DynamoDB", "AWS/Lambda", "AWS/RDS","AWS/ECS","AWS/ElastiCache","AWS/ELB","AWS/NetworkELB"}
	 for i := 0; i < len(cwMetrics); i++{
	assert.Contains(t,cwMetricsNamespaces, cwMetrics[i])
	 }
 }) 

}




func TestCreateMetadata(t *testing.T) {
	t.Parallel()
  

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../terraform-aws-observability-common/",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationID,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "true",
			"manage_cloudwatch_metrics_source": "false",
			"manage_alb_logs_source":           "false",
			"manage_alb_s3_bucket":             "false",
			"manage_cloudtrail_bucket":         "false",
			"manage_cloudwatch_logs_source":    "false",
			"manage_aws_inventory_source":		"false",
			"manage_aws_xray_source":			"false",
		},

		EnvVars: map[string]string{
			"AWS_REGION": awsRegion,
			"SUMOLOGIC_ACCESSID": sumologicAccessID,
			"SUMOLOGIC_ACCESSKEY": sumologicAccessKey,
			"SUMOLOGIC_ENVIRONMENT": sumologicEnvironment,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	
	_, err := terraform.InitAndApplyE(t,terraformOptions)
	if err != nil {
		for err != nil {
		time.Sleep(1 * time.Minute)
		_, err = terraform.ApplyE(t,terraformOptions)
		}
	}
  // ========== Mapping Terraform Outputs ==========

  s3BucketMap 				:= terraform.OutputMapOfObjects(t, terraformOptions,"common_bucket")
  iamRoleSumoSource 	    := terraform.Output(t, terraformOptions, "aws_iam_role_sumologic_source_name")
  commonSNSTopic    		:= terraform.Output(t, terraformOptions, "common_sns_topic__name ")
  metadataSource    		:= terraform.Output(t, terraformOptions, "sumologic_aws_metadata_source_name")
  collector         		:= terraform.Output(t, terraformOptions, "sumologic_collector_name")


// ========== Running Tests ===========

  //Verify Common S3 Bucket 
  t.Run("Verify Common S3 Bucket Existence", func (t *testing.T){

	  assert.Contains(t, s3BucketMap["this"].(map[string]interface{})["bucket"],fmt.Sprintf("aws-observability-logs-%s-us-east-1",accountAlias))
  })

  t.Run("Verify Common S3 Bucket Region", func (t *testing.T){

	assert.Contains(t, s3BucketMap["this"].(map[string]interface{})["region"],awsRegion)
})

    //Verify Sumologic source IAM Role
  t.Run("Verify Sumologic Source IAM Role", func (t *testing.T){
	 assert.Contains(t, iamRoleSumoSource, fmt.Sprintf("SumoLogicSource-%s", accountAlias))
  })


  //Verify S3 SNS Topic
  t.Run("Verify S3 SNS Topic ", func (t *testing.T){
	assert.Contains(t, commonSNSTopic, fmt.Sprintf("sumo-sns-topic-%s", accountAlias))
  })

  //Verify Metadata Source
  t.Run("Verify Metadata Source", func (t *testing.T){
	assert.Contains(t, metadataSource, fmt.Sprintf("%s-metadata-", accountAlias))
  })

  //Verify Collector
  t.Run("Verify Collector ", func (t *testing.T){
	assert.Contains(t, collector, fmt.Sprintf("aws-observability-%s", accountAlias))
  })

}


func TestCreateCWMetrics(t *testing.T) {
	t.Parallel()
  

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../terraform-aws-observability-common/",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationID,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "false",
			"manage_cloudwatch_metrics_source": "true",
			"manage_alb_logs_source":           "false",
			"manage_alb_s3_bucket":             "false",
			"manage_cloudtrail_bucket":         "false",
			"manage_cloudwatch_logs_source":    "false",
			"manage_aws_inventory_source":		"false",
			"manage_aws_xray_source":			"false",
		},

		EnvVars: map[string]string{
			"AWS_REGION": awsRegion,
			"SUMOLOGIC_ACCESSID": sumologicAccessID,
			"SUMOLOGIC_ACCESSKEY": sumologicAccessKey,
			"SUMOLOGIC_ENVIRONMENT": sumologicEnvironment,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	
	_, err := terraform.InitAndApplyE(t,terraformOptions)
	if err != nil {
		for err != nil {
		time.Sleep(1 * time.Minute)
		_, err = terraform.ApplyE(t,terraformOptions)
		}
	}

	// ========== Mapping Terraform Outputs ==========

  s3BucketMap 				:= terraform.OutputMapOfObjects(t, terraformOptions,"common_bucket")
  cwMetricsNamespaces 		:= terraform.OutputList(t,terraformOptions,"cloudwatch_metrics_namespaces")
  commonSNSTopic    		:= terraform.Output(t, terraformOptions, "common_sns_topic__name ")
  collector         		:= terraform.Output(t, terraformOptions, "sumologic_collector_name")


// ========== Running Tests ===========

  //Verify Common S3 Bucket 
  t.Run("Verify Common S3 Bucket Existence", func (t *testing.T){

	  assert.Contains(t, s3BucketMap["this"].(map[string]interface{})["bucket"],fmt.Sprintf("aws-observability-logs-%s-us-east-1",accountAlias))
  })

  t.Run("Verify Common S3 Bucket Region", func (t *testing.T){

	assert.Contains(t, s3BucketMap["this"].(map[string]interface{})["region"],awsRegion)
})


  //Verify S3 SNS Topic
  t.Run("Verify S3 SNS Topic ", func (t *testing.T){
	assert.Contains(t, commonSNSTopic, fmt.Sprintf("sumo-sns-topic-%s", accountAlias))
  })

  //Verify Collector
  t.Run("Verify Collector ", func (t *testing.T){
	assert.Contains(t, collector, fmt.Sprintf("aws-observability-%s", accountAlias))
  })

 //Verify 9 CW Metrics Namespaces
t.Run("Verify CW Metrics Namespaces", func (t *testing.T){

	 cwMetrics := [9]string{"AWS/ApplicationELB", "AWS/ApiGateway", "AWS/DynamoDB", "AWS/Lambda", "AWS/RDS","AWS/ECS","AWS/ElastiCache","AWS/ELB","AWS/NetworkELB"}
	 for i := 0; i < len(cwMetrics); i++{
	assert.Contains(t,cwMetricsNamespaces, cwMetrics[i])
	 }
 })
}

func TestCreateCloudTrailWithBucket(t *testing.T) {
  
    t.Parallel()
  

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../terraform-aws-observability-common/",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationID,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "false",
			"manage_cloudwatch_metrics_source": "false",
			"manage_alb_logs_source":           "false",
			"manage_alb_s3_bucket":             "false",
			"manage_cloudtrail_bucket":         "true",
			"manage_cloudwatch_logs_source":    "false",
			"manage_aws_inventory_source":		"false",
			"manage_aws_xray_source":			"false",
		},

		EnvVars: map[string]string{
			"AWS_REGION": awsRegion,
			"SUMOLOGIC_ACCESSID": sumologicAccessID,
			"SUMOLOGIC_ACCESSKEY": sumologicAccessKey,
			"SUMOLOGIC_ENVIRONMENT": sumologicEnvironment,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	
	_, err := terraform.InitAndApplyE(t,terraformOptions)
	if err != nil {
		for err != nil {
		time.Sleep(1 * time.Minute)
		_, err = terraform.ApplyE(t,terraformOptions)
		}
	}

	 // ========== Mapping Terraform Outputs ==========

	 s3BucketMap 				:= terraform.OutputMapOfObjects(t, terraformOptions,"common_bucket")
	 cloudTrailSNSSubscription :=	terraform.Output(t, terraformOptions, "aws_sns_topic_policy_cloudtrail_name")
	 cloudTrailCommon  		:= terraform.Output(t, terraformOptions, "cloudtrail_common_name")
	 commonSNSTopic    		:= terraform.Output(t, terraformOptions, "common_sns_topic__name ")
	 collector         		:= terraform.Output(t, terraformOptions, "sumologic_collector_name")

   
   // ========== Running Tests ===========
   
	 //Verify Common S3 Bucket 
	 t.Run("Verify Common S3 Bucket Existence", func (t *testing.T){
   
		 assert.Contains(t, s3BucketMap["this"].(map[string]interface{})["bucket"],fmt.Sprintf("aws-observability-logs-%s-us-east-1",accountAlias))
	 })
   
	 t.Run("Verify Common S3 Bucket Region", func (t *testing.T){
   
	   assert.Contains(t, s3BucketMap["this"].(map[string]interface{})["region"],awsRegion)
   })
   
	 // Verify Cloudtrail SNS topic subscription 
	t.Run("Verify Cloudtrail SNS Topic Subscription", func (t *testing.T){
	   assert.Contains(t, cloudTrailSNSSubscription, fmt.Sprintf("sumo-sns-topic-%s", accountAlias))
	 })

	 //Verify Cloudtrail common bucket
	 t.Run("Verify Cloudtrail bucket ", func (t *testing.T){
	   assert.Contains(t, cloudTrailCommon, fmt.Sprintf("Aws-Observability-%s", accountAlias))
	 })
   
	 //Verify S3 SNS Topic
	 t.Run("Verify S3 SNS Topic ", func (t *testing.T){
	   assert.Contains(t, commonSNSTopic, fmt.Sprintf("sumo-sns-topic-%s", accountAlias))
	 })
   
	 //Verify Collector
	 t.Run("Verify Collector ", func (t *testing.T){
	   assert.Contains(t, collector, fmt.Sprintf("aws-observability-%s", accountAlias))
	 })
   
}


func TestCreateCWLogs(t *testing.T) {
    t.Parallel()
  

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../terraform-aws-observability-common/",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationID,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "false",
			"manage_cloudwatch_metrics_source": "false",
			"manage_alb_logs_source":           "false",
			"manage_alb_s3_bucket":             "false",
			"manage_cloudtrail_bucket":         "false",
			"manage_cloudwatch_logs_source":    "true",
			"manage_aws_inventory_source":		"false",
			"manage_aws_xray_source":			"false",
		},

		EnvVars: map[string]string{
			"AWS_REGION": awsRegion,
			"SUMOLOGIC_ACCESSID": sumologicAccessID,
			"SUMOLOGIC_ACCESSKEY": sumologicAccessKey,
			"SUMOLOGIC_ENVIRONMENT": sumologicEnvironment,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	
	_, err := terraform.InitAndApplyE(t,terraformOptions)
	if err != nil {
		for err != nil {
		time.Sleep(1 * time.Minute)
		_, err = terraform.ApplyE(t,terraformOptions)
		}
	}
  
	  // ========== Mapping Terraform Outputs ==========

	  s3BucketMap 				:= terraform.OutputMapOfObjects(t, terraformOptions,"common_bucket")
	  cwLogs 					:= terraform.Output(t, terraformOptions, "aws_cloudwatch_logs_name")
	  iamPolicyCWLambda 		:= terraform.Output(t, terraformOptions, "aws_iam_policy_cw_logs_source_lambda_lambda_name")
	  iamPolicyCWSQS 			:= terraform.Output(t, terraformOptions, "aws_iam_policy_cw_logs_source_lambda_sqs_name")
	  iamRoleCWLambdaLogs 		:= terraform.Output(t, terraformOptions, "aws_iam_role_cw_logs_source_lambda_logs_name") 
	  iamRoleCWExecutionLambda  := terraform.Output(t, terraformOptions, "aws_iam_role_cw_logs_source_lambda_name")
	  lambdaCWLogs 				:= terraform.Output(t, terraformOptions, "aws_lambda_function_cloudwatch_logs_source")
	  lambdaCWProcessDLQ 		:= terraform.Output(t, terraformOptions, "aws_lambda_function_cloudwatch_logs_source_process_deadletter")
	  cwSNSTopicEmail       	:= terraform.Output(t, terraformOptions, "aws_sns_topic_cloudwatch_logs_source_email")
	  cwSQSDeadletterSource 	:= terraform.Output(t, terraformOptions, "aws_sqs_queue_cloudwatch_logs_source_deadletter")
	  collector         		:= terraform.Output(t, terraformOptions, "sumologic_collector_name")
	
	
	// ========== Running Tests ===========
	
	  //Verify Common S3 Bucket 
	  t.Run("Verify Common S3 Bucket Existence", func (t *testing.T){
	
		  assert.Contains(t, s3BucketMap["this"].(map[string]interface{})["bucket"],fmt.Sprintf("aws-observability-logs-%s-us-east-1",accountAlias))
	  })
	
	  t.Run("Verify Common S3 Bucket Region", func (t *testing.T){
	
		assert.Contains(t, s3BucketMap["this"].(map[string]interface{})["region"],awsRegion)
	})
	
	  //Verify Cloudwatch logs
	  t.Run("Verify Cloudwatch logs", func (t *testing.T){
		assert.Contains(t, cwLogs, fmt.Sprintf("%s-cloudwatch-logs", accountAlias))
	  })
	
	  //Verify Cloudwatch log source lambda IAM Policy
	  t.Run("Verify Cloudwatch lambda IAM Policy", func (t *testing.T){
		assert.Contains(t, iamPolicyCWLambda, fmt.Sprintf("InvokeLambda-%s", awsRegion))
	  })
	  
	  //Verify Cloudwatch lambda SQS IAM Policy
	  t.Run("Verify Cloudwatch Lambda SQS", func (t *testing.T){
		assert.Contains(t, iamPolicyCWSQS, fmt.Sprintf("SQSCreateLogs-%s", awsRegion))
	  })
	
	  //Verify Cloudwatch lambda logs IAM Role
	  t.Run("Verify Cloudwatch Lambda Logs IAM Role ", func (t *testing.T){
		assert.Contains(t, iamRoleCWLambdaLogs, fmt.Sprintf("CloudWatchCreateLogs-%s", awsRegion))
	  })
	
		//Verify Cloudwatch lambda execution IAM Role
	  t.Run("Verify Cloudwatch Lambda Execution IAM Role", func (t *testing.T){
		 assert.Contains(t, iamRoleCWExecutionLambda, fmt.Sprintf("SumoCWLambdaExecutionRole-%s", accountAlias))
	  })

	  //Verify Cloudwatch logs Lambda
	  t.Run("Verify Cloudwatch Logs Lambda", func (t *testing.T){
		assert.Contains(t, lambdaCWLogs, "SumoCWLogsLambda")
	  })
	
	  //Verify Cloudwatch Process DLQ Lambda
	  t.Run("Verify Cloudwatch Process DLQ Lambda", func (t *testing.T){
		assert.Contains(t, lambdaCWProcessDLQ, "SumoCWProcessDLQLambda")
	  })
	
	  //Verify Cloudwatch Email SNS Topic
	  t.Run("Verify Cloudwatch Email SNS Topic ", func (t *testing.T){
		assert.Contains(t, cwSNSTopicEmail, "SumoCWEmailSNSTopic")
	  })
	
	  //Verify Cloudwatch SQS Deadletter Source
	  t.Run("Verify Cloudwatch SQS Deadletter Source", func (t *testing.T){
		assert.Contains(t, cwSQSDeadletterSource, "SumoCWDeadLetterQueue")
	  })
	
	  //Verify Collector
	  t.Run("Verify Collector ", func (t *testing.T){
		assert.Contains(t, collector, fmt.Sprintf("aws-observability-%s", accountAlias))
	  })

} 

func TestXraySource(t *testing.T){
	t.Parallel()
  

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../terraform-aws-observability-common/",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationID,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "false",
			"manage_cloudwatch_metrics_source": "false",
			"manage_alb_logs_source":           "false",
			"manage_alb_s3_bucket":             "false",
			"manage_cloudtrail_bucket":         "false",
			"manage_cloudwatch_logs_source":    "false",
			"manage_aws_inventory_source":		"false",
			"manage_aws_xray_source":			"true",
		},

		EnvVars: map[string]string{
			"AWS_REGION": awsRegion,
			"SUMOLOGIC_ACCESSID": sumologicAccessID,
			"SUMOLOGIC_ACCESSKEY": sumologicAccessKey,
			"SUMOLOGIC_ENVIRONMENT": sumologicEnvironment,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	
	_, err := terraform.InitAndApplyE(t,terraformOptions)
	if err != nil {
		for err != nil {
		time.Sleep(1 * time.Minute)
		_, err = terraform.ApplyE(t,terraformOptions)
		}
	}

}

func TestInventorySource(t *testing.T){
	t.Parallel()
  

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../terraform-aws-observability-common/",

		Vars: map[string]interface{}{

			"sumologic_environment":            sumologicEnvironment,
			"sumologic_access_id":              sumologicAccessID,
			"sumologic_access_key":             sumologicAccessKey,
			"sumologic_organization_id":        sumoLogicOrganizationID,
			"account_alias":                    accountAlias,
			"manage_metadata_source":           "false",
			"manage_cloudwatch_metrics_source": "false",
			"manage_alb_logs_source":           "false",
			"manage_alb_s3_bucket":             "false",
			"manage_cloudtrail_bucket":         "false",
			"manage_cloudwatch_logs_source":    "false",
			"manage_aws_inventory_source":		"true",
			"manage_aws_xray_source":			"false",
		},

		EnvVars: map[string]string{
			"AWS_REGION": awsRegion,
			"SUMOLOGIC_ACCESSID": sumologicAccessID,
			"SUMOLOGIC_ACCESSKEY": sumologicAccessKey,
			"SUMOLOGIC_ENVIRONMENT": sumologicEnvironment,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	
	_, err := terraform.InitAndApplyE(t,terraformOptions)
	if err != nil {
		for err != nil {
		time.Sleep(1 * time.Minute)
		_, err = terraform.ApplyE(t,terraformOptions)
		}
	}

	  // ========== Mapping Terraform Outputs ==========

	  s3BucketMap 				:= terraform.OutputMapOfObjects(t, terraformOptions,"common_bucket")
	  iamRoleSumoSource 	    := terraform.Output(t, terraformOptions, "aws_iam_role_sumologic_source_name")
	  inventorySource   		:= terraform.Output(t, terraformOptions, "sumologic_aws_inventory_source_name")
	  collector         		:= terraform.Output(t, terraformOptions, "sumologic_collector_name")

	
	// ========== Running Tests ===========
	
	  //Verify Common S3 Bucket 
	  t.Run("Verify Common S3 Bucket Existence", func (t *testing.T){
	
		  assert.Contains(t, s3BucketMap["this"].(map[string]interface{})["bucket"],fmt.Sprintf("aws-observability-logs-%s-us-east-1",accountAlias))
	  })
	
	  t.Run("Verify Common S3 Bucket Region", func (t *testing.T){
	
		assert.Contains(t, s3BucketMap["this"].(map[string]interface{})["region"],awsRegion)
	})
	
		//Verify Sumologic source IAM Role
	  t.Run("Verify Sumologic Source IAM Role", func (t *testing.T){
		 assert.Contains(t, iamRoleSumoSource, fmt.Sprintf("SumoLogicSource-%s", accountAlias))
	  })
	
	  //Verify SumoLogic Inventory Source
	  t.Run("Verify Sumologic Inventory Source", func (t *testing.T){
		assert.Contains(t, inventorySource, fmt.Sprintf("%s-inventory-aws", accountAlias))
	  })
	
	
	  //Verify Collector
	  t.Run("Verify Collector ", func (t *testing.T){
		assert.Contains(t, collector, fmt.Sprintf("aws-observability-%s", accountAlias))
	  })
	

}
