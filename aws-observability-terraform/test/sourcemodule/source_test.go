package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"os"
	"path/filepath"
	"testing"
)

var resourceCount *terraform.ResourceCount

// Testing scenerio 1 - Install source module with all defaults
func TestSourceModule1(t *testing.T) {
	// t.Parallel()

	// The values to pass into the terraform CLI
	TerraformDir := "../../examples/sourcemodule/testSource"
	props = loadPropertiesFile("../../examples/sourcemodule/testSource/main.auto.tfvars")
	Vars := map[string]interface{}{
		"executeTest1": "true",
	}
	varsContent := []byte{}
	// Create a temporary vars.tfvars file
	varsFile := filepath.Join(TerraformDir, "vars.tfvars")
	err := os.WriteFile(varsFile, varsContent, 0644)
	if err != nil {
		t.Fatalf("Failed to create vars.tfvars file: %v", err)
	}

	// Get absolute path
	varsAbsPath, err := filepath.Abs(varsFile)
	if err != nil {
		fmt.Println("Error getting absolute path:", err)
		return
	}

	// Deploy the solution using Terraform
	test_structure.RunTestStage(t, "deploy", func() {
		resourceCount = deployTerraform(t, TerraformDir, Vars, varsAbsPath)
	})

	// Assert count of Expected resources.
	test_structure.RunTestStage(t, "AssertCount", func() {
		AssertResourceCounts(t, resourceCount, 93, 0, 0)
	})

	// Load the Terraform Options saved by the earlier deploy_terraform stage
	terraformOptions := test_structure.LoadTerraformOptions(t, TerraformDir)

	// Validate that the resources are created in Sumo Logic
	test_structure.RunTestStage(t, "validateSumoLogic", func() {
		// Collector
		collectorID := terraform.Output(t, terraformOptions, "sumologic_collector")
		validateSumoCollector(t, terraformOptions, collectorID)
		// Classic ELB Source
		clbSourceID := terraform.Output(t, terraformOptions, "sumologic_classic_lb_source")
		validateSumoSource(t, terraformOptions, collectorID, clbSourceID)
		// CloudTrail Source
		cloudtrailSourceID := terraform.Output(t, terraformOptions, "sumologic_cloudtrail_source")
		validateSumoSource(t, terraformOptions, collectorID, cloudtrailSourceID)
		// ELB Source
		elbSourceID := terraform.Output(t, terraformOptions, "sumologic_elb_source")
		validateSumoSource(t, terraformOptions, collectorID, elbSourceID)
		// Kf Logs Source
		kfLogsSourceID := terraform.Output(t, terraformOptions, "sumologic_kinesis_firehose_for_logs_source")
		validateSumoSource(t, terraformOptions, collectorID, kfLogsSourceID)
		// Kf Metrics Source
		kfMetricsSourceID := terraform.Output(t, terraformOptions, "sumologic_kinesis_firehose_for_metrics_source")
		validateSumoSource(t, terraformOptions, collectorID, kfMetricsSourceID)
		// S3 bucket
		s3bucket := terraform.Output(t, terraformOptions, "aws_s3")
		validateS3Bucket(t, terraformOptions, s3bucket)
		// SNS Topic
		snsTopic := terraform.Output(t, terraformOptions, "aws_sns_topic")
		validateSNSTopic(t, terraformOptions, snsTopic)
		// Classic ELB SNS Subscription
		clbSNSsub := terraform.Output(t, terraformOptions, "classic_lb_sns_sub")
		validateSNSsub(t, terraformOptions, clbSNSsub)
		// Cloudtrail SNS Subscription
		cloudtrailSNSsub := terraform.Output(t, terraformOptions, "cloudtrail_sns_sub")
		validateSNSsub(t, terraformOptions, cloudtrailSNSsub)
		// ALB SNS Subscription
		albSNSsub := terraform.Output(t, terraformOptions, "alb_sns_sub")
		validateSNSsub(t, terraformOptions, albSNSsub)
		// AWS IAM role
		iamRole := terraform.Output(t, terraformOptions, "aws_iam_role")
		validateIAMRole(t, terraformOptions, iamRole)
		// AWS CloudTrail
		cloudTrailName := terraform.Output(t, terraformOptions, "aws_cloudtrail_name")
		validateCloudTrail(t, terraformOptions, cloudTrailName)
		// Classic LB CloudFormation Stack
		clbStack := terraform.Output(t, terraformOptions, "clb_auto_enable_stack")
		validateCFStack(t, terraformOptions, clbStack)
		// ALB CloudFormation Stack
		albStack := terraform.Output(t, terraformOptions, "alb_auto_enable_stack")
		validateCFStack(t, terraformOptions, albStack)
		// KF logs CloudFormation Stack
		kfLogsStack := terraform.Output(t, terraformOptions, "kf_logs_auto_enable_stack")
		validateCFStack(t, terraformOptions, kfLogsStack)
		// Kinesis Firehose for Logs
		kfLogsStream := terraform.Output(t, terraformOptions, "kf_logs_stream")
		validateKFstream(t, terraformOptions, kfLogsStream)
		// Kinesis Firehose for Metrics
		kfMetricsStream := terraform.Output(t, terraformOptions, "kf_metrics_stream")
		validateKFstream(t, terraformOptions, kfMetricsStream)
		// Cloud Watch metric stream
		cwMetricsStream := terraform.Output(t, terraformOptions, "cw_metrics_stream")
		validateCWmetricstream(t, terraformOptions, cwMetricsStream)

	})

	// At the end of the test, un-deploy the solution using Terraform
	defer test_structure.RunTestStage(t, "cleanup", func() {
		destroyTerraform(t, TerraformDir)
		// Delete the temporary vars.tfvars file
		err := os.Remove(varsAbsPath)
		if err != nil {
			t.Fatalf("Failed to delete vars.tfvars file: %v", err)
		}
	})
}

// Testing scenerio 2 - Install with no collection of any source
func TestSourceModule2(t *testing.T) {
	// t.Parallel()

	// The values to pass into the terraform CLI
	TerraformDir := "../../examples/sourcemodule/testSource"
	props = loadPropertiesFile("../../examples/sourcemodule/testSource/main.auto.tfvars")

	Vars := map[string]interface{}{
		"executeTest2":              "true",
		"create_collector":          "false",
		"collect_elb":               "false",
		"collect_classic_lb":        "false",
		"collect_cloudtrail":        "false",
		"collect_logs_cloudwatch":   "None",
		"collect_metric_cloudwatch": "None",
	}
	varsContent := []byte{}
	// Create a temporary vars.tfvars file
	varsFile := filepath.Join(TerraformDir, "vars.tfvars")
	err := os.WriteFile(varsFile, varsContent, 0644)
	if err != nil {
		t.Fatalf("Failed to create vars.tfvars file: %v", err)
	}

	// Get absolute path
	varsAbsPath, err := filepath.Abs(varsFile)
	if err != nil {
		fmt.Println("Error getting absolute path:", err)
		return
	}

	// Deploy the solution using Terraform
	test_structure.RunTestStage(t, "deploy", func() {
		resourceCount = deployTerraform(t, TerraformDir, Vars, varsAbsPath)
	})

	// Assert count of Expected resources.
	test_structure.RunTestStage(t, "AssertCount", func() {
		AssertResourceCounts(t, resourceCount, 32, 0, 0)
	})

	// At the end of the test, un-deploy the solution using Terraform
	defer test_structure.RunTestStage(t, "cleanup", func() {
		destroyTerraform(t, TerraformDir)
		// Delete the temporary vars.tfvars file
		err := os.Remove(varsAbsPath)
		if err != nil {
			t.Fatalf("Failed to delete vars.tfvars file: %v", err)
		}
	})
}

// Testing scenerio 3 - Collect CW Logs via Lambda Log forwarder, CW Metrics via CW metric source & Inventory source
func TestSourceModule3(t *testing.T) {
	// t.Parallel()

	TerraformDir := "../../examples/sourcemodule/testSource"
	props = loadPropertiesFile("../../examples/sourcemodule/testSource/main.auto.tfvars")

	Vars := map[string]interface{}{
		"executeTest3":              "true",
		"collect_elb":               "false",
		"collect_classic_lb":        "false",
		"collect_cloudtrail":        "false",
		"collect_logs_cloudwatch":   "Lambda Log Forwarder",
		"collect_metric_cloudwatch": "CloudWatch Metrics Source",
	}
	varsContent := []byte{}
	// Create a temporary vars.tfvars file
	varsFile := filepath.Join(TerraformDir, "vars.tfvars")
	err := os.WriteFile(varsFile, varsContent, 0644)
	if err != nil {
		t.Fatalf("Failed to create vars.tfvars file: %v", err)
	}

	// Get absolute path
	varsAbsPath, err := filepath.Abs(varsFile)
	if err != nil {
		fmt.Println("Error getting absolute path:", err)
		return
	}

	// Deploy the solution using Terraform
	test_structure.RunTestStage(t, "deploy", func() {
		resourceCount = deployTerraform(t, TerraformDir, Vars, varsAbsPath)
	})

	// Assert count of Expected resources.
	test_structure.RunTestStage(t, "AssertCount", func() {
		AssertResourceCounts(t, resourceCount, 94, 0, 0)
	})
	// Load the Terraform Options saved by the earlier deploy_terraform stage
	terraformOptions := test_structure.LoadTerraformOptions(t, TerraformDir)

	// Validate that the resources are created in Sumo Logic
	test_structure.RunTestStage(t, "validateSumoLogic", func() {
		// Collector
		collectorID := terraform.Output(t, terraformOptions, "sumologic_collector")
		validateSumoCollector(t, terraformOptions, collectorID)
		// AWS IAM role
		iamRole := terraform.Output(t, terraformOptions, "aws_iam_role")
		validateIAMRole(t, terraformOptions, iamRole)
		// LLF Logs Source
		cwLogsSourceID := terraform.Output(t, terraformOptions, "sumologic_cloudwatch_logs_source")
		validateSumoSource(t, terraformOptions, collectorID, cwLogsSourceID)
		// CloudWatch logs lambda forwarder
		lambdaName := terraform.Output(t, terraformOptions, "log_forwarder_lambda_name")
		validateLambda(t, terraformOptions, lambdaName)
		// LLF logs CloudFormation Stack
		llfLogsStack := terraform.Output(t, terraformOptions, "cw_logs_auto_enable_stack")
		validateCFStack(t, terraformOptions, llfLogsStack)
	})

	// At the end of the test, un-deploy the solution using Terraform
	defer test_structure.RunTestStage(t, "cleanup", func() {
		destroyTerraform(t, TerraformDir)
		// Delete the temporary vars.tfvars file
		err := os.Remove(varsAbsPath)
		if err != nil {
			t.Fatalf("Failed to delete vars.tfvars file: %v", err)
		}
	})
}

// Testing scenerio 4 - Override bucket details of sources ALB, CLB, CloudTrail, CloudWatch logs and metrics with existing collector. X-Ray source
// Takes 14 mins to execute
func TestSourceModule4(t *testing.T) {
	// t.Parallel()

	// The values to pass into the terraform CLI
	TerraformDir := "../../examples/sourcemodule/overrideSources"
	props = loadPropertiesFile("../../examples/sourcemodule/overrideSources/main.auto.tfvars")

	Vars := map[string]interface{}{
		"collector_id":              "",
		"s3_name":                   "",
		"executeTest4":              "true",
		"create_collector":          "false",
		"collect_elb":               "true",
		"collect_classic_lb":        "true",
		"collect_cloudtrail":        "true",
		"collect_logs_cloudwatch":   "Kinesis Firehose Log Source",
		"collect_metric_cloudwatch": "CloudWatch Metrics Source",
		"create_s3_bucket":          "false",
	}
	varsContent := []byte{}
	// Create a temporary vars.tfvars file
	varsFile := filepath.Join(TerraformDir, "vars.tfvars")
	err := os.WriteFile(varsFile, varsContent, 0644)
	if err != nil {
		t.Fatalf("Failed to create vars.tfvars file: %v", err)
	}

	// Get absolute path
	varsAbsPath, err := filepath.Abs(varsFile)
	if err != nil {
		fmt.Println("Error getting absolute path:", err)
		return
	}
	// Deploy the solution using Terraform
	test_structure.RunTestStage(t, "deploy", func() {
		resourceCount = deployTerraform(t, TerraformDir, Vars, varsAbsPath)
	})

	// Assert count of Expected resources.
	test_structure.RunTestStage(t, "AssertCount", func() {
		AssertResourceCounts(t, resourceCount, 187, 0, 0)
	})

	// Load the Terraform Options saved by the earlier deploy_terraform stage
	terraformOptions := test_structure.LoadTerraformOptions(t, TerraformDir)

	// Validate that the resources are created in Sumo Logic
	test_structure.RunTestStage(t, "validateSumoLogic", func() {
		// AWS IAM role
		iamRole := terraform.Output(t, terraformOptions, "aws_iam_role")
		validateIAMRole(t, terraformOptions, iamRole)
		// Classic ELB SNS Topic
		clbSNStopic := terraform.Output(t, terraformOptions, "classic_lb_sns_topic")
		validateSNSTopic(t, terraformOptions, clbSNStopic)
		// Classic ELB SNS Subscription
		clbSNSsub := terraform.Output(t, terraformOptions, "classic_lb_sns_sub")
		validateSNSsub(t, terraformOptions, clbSNSsub)
		// Classic ELB Source
		clbSourceID := terraform.Output(t, terraformOptions, "sumologic_classic_lb_source")
		validateSumoSource(t, terraformOptions, Vars["collector_id"].(string), clbSourceID)
		// Classic LB CloudFormation Stack
		clbStack := terraform.Output(t, terraformOptions, "clb_auto_enable_stack")
		validateCFStack(t, terraformOptions, clbStack)
		// CloudTrail SNS Topic
		cloudtrailSNStopic := terraform.Output(t, terraformOptions, "cloudtrail_sns_topic")
		validateSNSTopic(t, terraformOptions, cloudtrailSNStopic)
		// Cloudtrail SNS Subscription
		cloudtrailSNSsub := terraform.Output(t, terraformOptions, "cloudtrail_sns_sub")
		validateSNSsub(t, terraformOptions, cloudtrailSNSsub)
		// CloudTrail Source
		cloudtrailSourceID := terraform.Output(t, terraformOptions, "sumologic_cloudtrail_source")
		validateSumoSource(t, terraformOptions, Vars["collector_id"].(string), cloudtrailSourceID)
		// ALB SNS Topic
		albSNStopic := terraform.Output(t, terraformOptions, "alb_sns_topic")
		validateSNSTopic(t, terraformOptions, albSNStopic)
		// ALB SNS Subscription
		albSNSsub := terraform.Output(t, terraformOptions, "alb_sns_sub")
		validateSNSsub(t, terraformOptions, albSNSsub)
		// ALB CloudFormation Stack
		albStack := terraform.Output(t, terraformOptions, "alb_auto_enable_stack")
		validateCFStack(t, terraformOptions, albStack)
		// ALB Source
		elbSourceID := terraform.Output(t, terraformOptions, "sumologic_elb_source")
		validateSumoSource(t, terraformOptions, Vars["collector_id"].(string), elbSourceID)
		// Kf Logs Source
		kfLogsSourceID := terraform.Output(t, terraformOptions, "sumologic_kinesis_firehose_for_logs_source")
		validateSumoSource(t, terraformOptions, Vars["collector_id"].(string), kfLogsSourceID)
		// KF logs auto enable CloudFormation Stack
		kfStack := terraform.Output(t, terraformOptions, "kf_logs_auto_enable_stack")
		validateCFStack(t, terraformOptions, kfStack)
		// Kinesis Firehose for Logs
		kfLogsStream := terraform.Output(t, terraformOptions, "kf_logs_stream")
		validateKFstream(t, terraformOptions, kfLogsStream)
	})

	// At the end of the test, un-deploy the solution using Terraform
	defer test_structure.RunTestStage(t, "cleanup", func() {
		destroyTerraform(t, TerraformDir)
		// Delete the temporary vars.tfvars file
		err := os.Remove(varsAbsPath)
		if err != nil {
			t.Fatalf("Failed to delete vars.tfvars file: %v", err)
		}
	})
}

// Testing scenerio 5 - Collect CW Logs via Lambda Log forwarder + filter log groups based on AWS tag and CW Metrics via CW metric source + collect custom metrics namespace + filter metrics by AWS tags
func TestSourceModule5(t *testing.T) {
	// t.Parallel()

	TerraformDir := "../../examples/sourcemodule/testSource"
	props = loadPropertiesFile("../../examples/sourcemodule/testSource/main.auto.tfvars")

	Vars := map[string]interface{}{
		"executeTest5":                  "true",
		"collect_elb":                   "false",
		"collect_classic_lb":            "false",
		"collect_cloudtrail":            "false",
		"collect_rce":                   "None",
		"collect_logs_cloudwatch":       "Lambda Log Forwarder",
		"auto_enable_logs_tags_filters": "Environment=Production,Application=MyApp,creator=appsTeam",
		"collect_metric_cloudwatch":     "CloudWatch Metrics Source",
	}
	// Define the variable values
	varsContent := []byte(`
	metric_namespaces = ["AWS/ApplicationELB", "AWS/ApiGateway", "AWS/DynamoDB", "AWS/Lambda", "cwagent"]
	metrics_tag_filters = [
		{
			"type"=      "TagFilters",
			"namespace"= "AWS/DynamoDB",
			"tags"=      ["env=prod;dev"],
		},
		{
			"type"=      "TagFilters",
			"namespace"= "AWS/Lambda",
			"tags"=      ["env=prod"],
		},
		{
			"type"=      "TagFilters",
			"namespace"= "AWS/EC2",
			"tags"=      ["creator=appsTeam"],
		},
	]
	`)

	// Create a temporary vars.tfvars file
	varsFile := filepath.Join(TerraformDir, "vars.tfvars")
	err := os.WriteFile(varsFile, varsContent, 0644)
	if err != nil {
		t.Fatalf("Failed to create vars.tfvars file: %v", err)
	}

	// Get absolute path
	varsAbsPath, err := filepath.Abs(varsFile)
	if err != nil {
		fmt.Println("Error getting absolute path:", err)
		return
	}

	// Deploy the solution using Terraform
	test_structure.RunTestStage(t, "deploy", func() {
		resourceCount = deployTerraform(t, TerraformDir, Vars, varsAbsPath)
	})

	// Assert count of Expected resources.
	test_structure.RunTestStage(t, "AssertCount", func() {
		AssertResourceCounts(t, resourceCount, 73, 0, 0)
	})
	// Load the Terraform Options saved by the earlier deploy_terraform stage
	terraformOptions := test_structure.LoadTerraformOptions(t, TerraformDir)

	// Validate that the resources are created in Sumo Logic
	test_structure.RunTestStage(t, "validateSumoLogic", func() {
		// Collector
		collectorID := terraform.Output(t, terraformOptions, "sumologic_collector")
		validateSumoCollector(t, terraformOptions, collectorID)
		// AWS IAM role
		iamRole := terraform.Output(t, terraformOptions, "aws_iam_role")
		validateIAMRole(t, terraformOptions, iamRole)
		// LLF Logs Source
		cwLogsSourceID := terraform.Output(t, terraformOptions, "sumologic_cloudwatch_logs_source")
		validateSumoSource(t, terraformOptions, collectorID, cwLogsSourceID)
		// CloudWatch logs lambda forwarder
		lambdaName := terraform.Output(t, terraformOptions, "log_forwarder_lambda_name")
		validateLambda(t, terraformOptions, lambdaName)
		// // LLF logs CloudFormation Stack
		llfLogsStack := terraform.Output(t, terraformOptions, "cw_logs_auto_enable_stack")
		validateCFStack(t, terraformOptions, llfLogsStack)
	})

	// At the end of the test, un-deploy the solution using Terraform
	defer test_structure.RunTestStage(t, "cleanup", func() {
		destroyTerraform(t, TerraformDir)
		// Delete the temporary vars.tfvars file
		err := os.Remove(varsAbsPath)
		if err != nil {
			t.Fatalf("Failed to delete vars.tfvars file: %v", err)
		}
	})
}

// Testing scenerio 6 - Collect CW Logs via Kinesis source + filter log groups based on AWS tag and CW Metrics via Kinesis source + collect custom metrics namespace + filter metrics by AWS tags

func TestSourceModule6(t *testing.T) {
	// t.Parallel()

	TerraformDir := "../../examples/sourcemodule/testSource"
	props = loadPropertiesFile("../../examples/sourcemodule/testSource/main.auto.tfvars")

	Vars := map[string]interface{}{
		"executeTest6":                  "true",
		"collect_elb":                   "false",
		"collect_classic_lb":            "false",
		"collect_cloudtrail":            "false",
		"collect_rce":                   "None",
		"auto_enable_logs_tags_filters": "Environment=Production,Application=MyApp,creator=appsTeam",
	}
	// Define the variable values
	varsContent := []byte(`
	metric_namespaces = ["AWS/ApplicationELB", "AWS/ApiGateway", "AWS/DynamoDB", "AWS/Lambda", "cwagent"]
	metrics_tag_filters = [
		{
			"type"=      "TagFilters",
			"namespace"= "AWS/DynamoDB",
			"tags"=      ["env=prod;dev"],
		},
		{
			"type"=      "TagFilters",
			"namespace"= "AWS/Lambda",
			"tags"=      ["env=prod"],
		},
		{
			"type"=      "TagFilters",
			"namespace"= "AWS/EC2",
			"tags"=      ["creator=appsTeam"],
		},
	]
	`)

	// Create a temporary vars.tfvars file
	varsFile := filepath.Join(TerraformDir, "vars.tfvars")
	err := os.WriteFile(varsFile, varsContent, 0644)
	if err != nil {
		t.Fatalf("Failed to create vars.tfvars file: %v", err)
	}

	// Get absolute path
	varsAbsPath, err := filepath.Abs(varsFile)
	if err != nil {
		fmt.Println("Error getting absolute path:", err)
		return
	}

	// Deploy the solution using Terraform
	test_structure.RunTestStage(t, "deploy", func() {
		resourceCount = deployTerraform(t, TerraformDir, Vars, varsAbsPath)
	})

	// Assert count of Expected resources.
	test_structure.RunTestStage(t, "AssertCount", func() {
		AssertResourceCounts(t, resourceCount, 70, 0, 0)
	})
	// Load the Terraform Options saved by the earlier deploy_terraform stage
	terraformOptions := test_structure.LoadTerraformOptions(t, TerraformDir)

	// Validate that the resources are created in Sumo Logic
	test_structure.RunTestStage(t, "validateSumoLogic", func() {
		// Collector
		collectorID := terraform.Output(t, terraformOptions, "sumologic_collector")
		validateSumoCollector(t, terraformOptions, collectorID)
		// AWS IAM role
		iamRole := terraform.Output(t, terraformOptions, "aws_iam_role")
		validateIAMRole(t, terraformOptions, iamRole)
		// Cloud Watch metric stream
		cwMetricsStream := terraform.Output(t, terraformOptions, "cw_metrics_stream")
		validateCWmetricstream(t, terraformOptions, cwMetricsStream)
		// KF logs CloudFormation Stack
		kfLogsStack := terraform.Output(t, terraformOptions, "kf_logs_auto_enable_stack")
		validateCFStack(t, terraformOptions, kfLogsStack)
		// Kinesis Firehose for Logs
		kfLogsStream := terraform.Output(t, terraformOptions, "kf_logs_stream")
		validateKFstream(t, terraformOptions, kfLogsStream)
		// Kinesis Firehose for Metrics
		kfMetricsStream := terraform.Output(t, terraformOptions, "kf_metrics_stream")
		validateKFstream(t, terraformOptions, kfMetricsStream)
		// Kf Logs Source
		kfLogsSourceID := terraform.Output(t, terraformOptions, "sumologic_kinesis_firehose_for_logs_source")
		validateSumoSource(t, terraformOptions, collectorID, kfLogsSourceID)
		// Kf Metrics Source
		kfMetricsSourceID := terraform.Output(t, terraformOptions, "sumologic_kinesis_firehose_for_metrics_source")
		validateSumoSource(t, terraformOptions, collectorID, kfMetricsSourceID)
	})

	// At the end of the test, un-deploy the solution using Terraform
	defer test_structure.RunTestStage(t, "cleanup", func() {
		destroyTerraform(t, TerraformDir)
		// Delete the temporary vars.tfvars file
		err := os.Remove(varsAbsPath)
		if err != nil {
			t.Fatalf("Failed to delete vars.tfvars file: %v", err)
		}
	})
}
