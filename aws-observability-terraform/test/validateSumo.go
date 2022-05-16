package test

import (
	"encoding/base64"
	"fmt"
	"net/url"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

var props = loadPropertiesFile("../examples/default/main.auto.tfvars")

func loadPropertiesFile(file string) map[string]string {
	props, err := ReadPropertiesFile(file)
	if err != nil {
		fmt.Println("Error while reading properties file " + err.Error())
	}
	return props
}

//SumoLogic Environment URL
var sumologicURL = getSumologicURL()

func getSumologicURL() string {
	u, _ := url.Parse(getProperty("sumo_api_endpoint"))
	return u.Scheme + "://" + u.Host
}

func getProperty(property string) string {
	return props[property]
}

var customValidation = func(statusCode int, body string) bool { return statusCode == 200 }

// We are creating admin header because Folder is not visible in case of Admin Recom Folder with share = false, only visible with admin mode
var headers = map[string]string{"Authorization": "Basic " + base64.StdEncoding.EncodeToString([]byte(getProperty("sumologic_access_id")+":"+getProperty("sumologic_access_key"))), "isAdminMode": "true"}

// Validate that the Sumo Logic Resources have been created
func validateSumoLogicResources(t *testing.T, workingDir string) {

	// Load the Terraform Options saved by the earlier deploy_terraform stage
	terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)

	// App Folders
	// Validate if the AWSO Apps folder is created successfully
	awsoFolderID := terraform.Output(t, terraformOptions, "apps_folder_id")
	validateSumoLogicAppsFolder(t, terraformOptions, awsoFolderID)
	// Validate if the ALB App folder is created successfully
	albFolderID := terraform.Output(t, terraformOptions, "alb_apps_folder_id")
	validateSumoLogicAppsFolder(t, terraformOptions, albFolderID)
	// Validate if the API Gateway App folder is created successfully
	apigatewayFolderID := terraform.Output(t, terraformOptions, "apigateway_apps_folder_id")
	validateSumoLogicAppsFolder(t, terraformOptions, apigatewayFolderID)
	// Validate if the CLB App folder is created successfully
	clbFolderID := terraform.Output(t, terraformOptions, "clb_apps_folder_id")
	validateSumoLogicAppsFolder(t, terraformOptions, clbFolderID)
	time.Sleep(2 * time.Second)
	// Validate if the DynamoDB App folder is created successfully
	dynamodbFolderID := terraform.Output(t, terraformOptions, "dynamodb_apps_folder_id")
	validateSumoLogicAppsFolder(t, terraformOptions, dynamodbFolderID)
	// Validate if the EC2 metrics App folder is created successfully
	ec2metricsFolderID := terraform.Output(t, terraformOptions, "ec2metrics_apps_folder_id")
	validateSumoLogicAppsFolder(t, terraformOptions, ec2metricsFolderID)
	// Validate if the ECS App folder is created successfully
	ecsFolderID := terraform.Output(t, terraformOptions, "ecs_apps_folder_id")
	validateSumoLogicAppsFolder(t, terraformOptions, ecsFolderID)
	// Validate if the Elasticache App folder is created successfully
	elasticacheFolderID := terraform.Output(t, terraformOptions, "elasticache_apps_folder_id")
	validateSumoLogicAppsFolder(t, terraformOptions, elasticacheFolderID)
	time.Sleep(2 * time.Second)
	// Validate if the Lambda App folder is created successfully
	lambdaFolderID := terraform.Output(t, terraformOptions, "lambda_apps_folder_id")
	validateSumoLogicAppsFolder(t, terraformOptions, lambdaFolderID)
	// Validate if the NLB App folder is created successfully
	nlbFolderID := terraform.Output(t, terraformOptions, "nlb_apps_folder_id")
	validateSumoLogicAppsFolder(t, terraformOptions, nlbFolderID)
	// Validate if the RCE App folder is created successfully
	rceFolderID := terraform.Output(t, terraformOptions, "rce_apps_folder_id")
	validateSumoLogicAppsFolder(t, terraformOptions, rceFolderID)
	// Validate if the RDS App folder is created successfully
	rdsFolderID := terraform.Output(t, terraformOptions, "rds_apps_folder_id")
	validateSumoLogicAppsFolder(t, terraformOptions, rdsFolderID)
	time.Sleep(2 * time.Second)

	// Monitor Folder
	// Validate if the Monitors folder is created successfully
	validateSumoLogicMonitorsFolder(t, terraformOptions)

	// Hierarchy
	validateSumoLogicHierarchy(t, terraformOptions)

	// FERs
	// Validate if the ALB FER is created successfully
	albFerID := terraform.Output(t, terraformOptions, "sumologic_field_extraction_rule_alb")
	validateSumoLogicFER(t, terraformOptions, albFerID)
	// Validate if the API Gateway FER is created successfully
	apigatewayFerID := terraform.Output(t, terraformOptions, "sumologic_field_extraction_rule_apigateway")
	validateSumoLogicFER(t, terraformOptions, apigatewayFerID)
	time.Sleep(2 * time.Second)
	// Validate if the DynamoDB FER is created successfully
	dynamodbFerID := terraform.Output(t, terraformOptions, "sumologic_field_extraction_rule_dynamodb")
	validateSumoLogicFER(t, terraformOptions, dynamodbFerID)
	// Validate if the ECS FER is created successfully
	ecsFerID := terraform.Output(t, terraformOptions, "sumologic_field_extraction_rule_ecs")
	validateSumoLogicFER(t, terraformOptions, ecsFerID)
	// Validate if the Elasticache FER is created successfully
	elasticacheFerID := terraform.Output(t, terraformOptions, "sumologic_field_extraction_rule_elasticache")
	validateSumoLogicFER(t, terraformOptions, elasticacheFerID)
	// Validate if the ELB FER is created successfully
	elbFerID := terraform.Output(t, terraformOptions, "sumologic_field_extraction_rule_elb")
	validateSumoLogicFER(t, terraformOptions, elbFerID)
	time.Sleep(2 * time.Second)
	// Validate if the Lambda FER is created successfully
	lambdaFerID := terraform.Output(t, terraformOptions, "sumologic_field_extraction_rule_lambda")
	validateSumoLogicFER(t, terraformOptions, lambdaFerID)
	// Validate if the Lambda CW FER is created successfully
	lambdacwFerID := terraform.Output(t, terraformOptions, "sumologic_field_extraction_rule_lambda_cw")
	validateSumoLogicFER(t, terraformOptions, lambdacwFerID)
	// Validate if the RDS FER is created successfully
	rdsFerID := terraform.Output(t, terraformOptions, "sumologic_field_extraction_rule_rds")
	validateSumoLogicFER(t, terraformOptions, rdsFerID)

	// Fields
	// Validate if the account Field is created successfully
	accountField := terraform.Output(t, terraformOptions, "sumologic_field_account")
	validateSumoLogicField(t, terraformOptions, accountField)
	time.Sleep(2 * time.Second)
	// Validate if the accountid Field is created successfully
	accountidField := terraform.Output(t, terraformOptions, "sumologic_field_accountid")
	validateSumoLogicField(t, terraformOptions, accountidField)
	// Validate if the region Field is created successfully
	regionField := terraform.Output(t, terraformOptions, "sumologic_field_region")
	validateSumoLogicField(t, terraformOptions, regionField)
	// Validate if the namespace Field is created successfully
	namespaceField := terraform.Output(t, terraformOptions, "sumologic_field_namespace")
	validateSumoLogicField(t, terraformOptions, namespaceField)
	// Validate if the apiname Field is created successfully
	apigatewayField := terraform.Output(t, terraformOptions, "sumologic_field_apiname")
	validateSumoLogicField(t, terraformOptions, apigatewayField)
	time.Sleep(2 * time.Second)
	// Validate if the cacheclusterid Field is created successfully
	elasticacheField := terraform.Output(t, terraformOptions, "sumologic_field_cacheclusterid")
	validateSumoLogicField(t, terraformOptions, elasticacheField)
	// Validate if the loadbalancer Field is created successfully
	loadbalancerField := terraform.Output(t, terraformOptions, "sumologic_field_loadbalancer")
	validateSumoLogicField(t, terraformOptions, loadbalancerField)
	// Validate if the loadbalancername Field is created successfully
	loadbalancernameField := terraform.Output(t, terraformOptions, "sumologic_field_loadbalancername")
	validateSumoLogicField(t, terraformOptions, loadbalancernameField)
	// Validate if the tablename Field is created successfully
	tablenameField := terraform.Output(t, terraformOptions, "sumologic_field_tablename")
	validateSumoLogicField(t, terraformOptions, tablenameField)
	time.Sleep(2 * time.Second)
	// Validate if the instanceid Field is created successfully
	instanceidField := terraform.Output(t, terraformOptions, "sumologic_field_instanceid")
	validateSumoLogicField(t, terraformOptions, instanceidField)
	// Validate if the clustername Field is created successfully
	clusternameField := terraform.Output(t, terraformOptions, "sumologic_field_clustername")
	validateSumoLogicField(t, terraformOptions, clusternameField)
	// Validate if the functionname Field is created successfully
	functionnameField := terraform.Output(t, terraformOptions, "sumologic_field_functionname")
	validateSumoLogicField(t, terraformOptions, functionnameField)
	// Validate if the networkloadbalancer Field is created successfully
	networkloadbalancerField := terraform.Output(t, terraformOptions, "sumologic_field_networkloadbalancer")
	validateSumoLogicField(t, terraformOptions, networkloadbalancerField)
	time.Sleep(2 * time.Second)
	// Validate if the dbidentifier Field is created successfully
	dbidentifierField := terraform.Output(t, terraformOptions, "sumologic_field_dbidentifier")
	validateSumoLogicField(t, terraformOptions, dbidentifierField)

	// Metric Rules
	// NLB
	nlbMetricRule := terraform.Output(t, terraformOptions, "sumologic_metric_rule_nlb")
	validateSumoLogicMetricRule(t, terraformOptions, nlbMetricRule)
	//RDS Cluster
	rdsMetricRule := terraform.Output(t, terraformOptions, "sumologic_metric_rule_rds_cluster")
	validateSumoLogicMetricRule(t, terraformOptions, rdsMetricRule)
	//RDS Instance
	rdsInsMetricRule := terraform.Output(t, terraformOptions, "sumologic_metric_rule_rds_instance")
	validateSumoLogicMetricRule(t, terraformOptions, rdsInsMetricRule)
	time.Sleep(2 * time.Second)

}

func validateSumoLogicAppsFolder(t *testing.T, terraformOptions *terraform.Options, folderID string) {
	// Verify that we get back a 200 OK
	http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v2/content/folders/%s", sumologicURL, folderID), nil, headers, customValidation, nil)
}

func validateSumoLogicFER(t *testing.T, terraformOptions *terraform.Options, ferId string) {
	// Verify that we get back a 200 OK
	http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/extractionRules/%s", sumologicURL, ferId), nil, headers, customValidation, nil)
}

func validateSumoLogicField(t *testing.T, terraformOptions *terraform.Options, fieldID string) {
	// Verify that we get back a 200 OK
	http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/fields/%s", sumologicURL, fieldID), nil, headers, customValidation, nil)
}

func validateSumoLogicMetricRule(t *testing.T, terraformOptions *terraform.Options, metricRuleID string) {
	// Verify that we get back a 200 OK
	http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/metricsRules/%s", sumologicURL, metricRuleID), nil, headers, customValidation, nil)
}

func validateSumoLogicMonitorsFolder(t *testing.T, terraformOptions *terraform.Options) {
	// Run `terraform output` to get the value of an output variable
	folderID := terraform.Output(t, terraformOptions, "monitors_folder_id")

	// Verify that we get back a 200 OK
	http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/monitors/%s", sumologicURL, folderID), nil, headers, customValidation, nil)
}

func validateSumoLogicHierarchy(t *testing.T, terraformOptions *terraform.Options) {
	// Run `terraform output` to get the value of an output variable
	hierarchyID := terraform.Output(t, terraformOptions, "hierarchy_id")

	// Verify that we get back a 200 OK
	http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/entities/hierarchies/%s", sumologicURL, hierarchyID), nil, headers, customValidation, nil)
}
