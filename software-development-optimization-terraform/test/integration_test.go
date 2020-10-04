package test

import (
	"encoding/base64"
	"fmt"
	"net/url"
	"os"
	"strings"
	"testing"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

var props = loadPropertiesFile("../sumologic.auto.tfvars")

//SumoLogic Environment URL
var sumologicURL = getSumologicURL()

var customValidation = func(statusCode int, body string) bool { return statusCode == 200 }
var headers = map[string]string{"Authorization": "Basic " + base64.StdEncoding.EncodeToString([]byte(getProperty("sumo_access_id")+":"+getProperty("sumo_access_key")))}

// Main function, define stages and run.
func TestTerraformSumoLogic(t *testing.T) {
	t.Parallel()

	workingDir := "../"

	// A unique ID we can use to namespace resources so we don't clash with anything already in the Sumo Logic
	uniqueID := random.UniqueId()
	collectorName := fmt.Sprintf("SDO_%s", uniqueID)

	// At the end of the test, un-deploy the solution using Terraform
	defer test_structure.RunTestStage(t, "cleanup", func() {
		destroyTerraform(t, workingDir)
	})

	// Deploy the solution using Terraform
	test_structure.RunTestStage(t, "deploy", func() {
		deployTerraform(t, workingDir, collectorName)
	})

	// Validate that the resources are created in Sumo Logic
	test_structure.RunTestStage(t, "validateSumoLogic", func() {
		validateSumoLogicResources(t, workingDir)
	})

	// Validate that the resources are created in Atlassian Systems
	test_structure.RunTestStage(t, "validateAtlassian", func() {
		validateAtlassianResources(t, workingDir)
	})

	// Validate Pagerduty Resources
	test_structure.RunTestStage(t, "validatePagerduty", func() {
		validatePagerdutyToSumologicWebhook(t, workingDir)
	})

	// // Validate Github Resources
	// test_structure.RunTestStage(t, "validateGithub", func() {
	// 	validateGithubToSumologicWebhook(t, workingDir)
	// })

}

func loadPropertiesFile(file string) map[string]string {
	props, err := ReadPropertiesFile(file)
	if err != nil {
		fmt.Println("Error while reading properties file " + err.Error())
	}
	return props
}

func getProperty(property string) string {
	return props[property]
}

func getSumologicURL() string {
	u, _ := url.Parse(getProperty("sumo_api_endpoint"))
	return u.Scheme + "://" + u.Host
}

// Validate that the Sumo Logic Resources have been created
func validateSumoLogicResources(t *testing.T, workingDir string) {

	// Load the Terraform Options saved by the earlier deploy_terraform stage
	terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
	// Get folder where the Apps are installed
	folderName := strings.Replace(terraform.Output(t, terraformOptions, "folder_name"), " ", "%20", -1)
	// Run `terraform output` to get the value of an output variable
	collectorID := terraform.Output(t, terraformOptions, "sdo_collector_id")
	// Validate if the collector is created successfully
	validateSumoLogicCollector(t, terraformOptions, collectorID)
	// Validate if the folder is created successfully
	validateSumoLogicFolder(t, terraformOptions)
	// Validate if the Jira Server Source is created successfully
	validateSumoLogicJiraServerSource(t, terraformOptions, collectorID)
	// Validate if the Jira Cloud Source is created successfully
	validateSumoLogicJiraCloudSource(t, terraformOptions, collectorID)
	// Validate if the Bitbucket Source is created successfully
	validateSumoLogicBitbucketSource(t, terraformOptions, collectorID)
	// Validate if the Opsgenie Source is created successfully
	validateSumoLogicOpsgenieSource(t, terraformOptions, collectorID)
	// Validate if the Github Source is created successfully
	validateSumoLogicGithubSource(t, terraformOptions, collectorID)
	// Validate if the Pagerduty Source is created successfully
	validateSumoLogicPagerdutySource(t, terraformOptions, collectorID)
	// Validate if the Sumologic Pagerduty Webhook is created successfully
	validateSumoLogicPagerdutyWebhook(t, terraformOptions)
	// Validate if the Sumologic Opsgenie Webhook is created successfully
	validateSumoLogicOpsgenieWebhook(t, terraformOptions)
	// Validate if the Jira Cloud Webhook is created successfully
	validateSumoLogicJiraCloudWebhook(t, terraformOptions)
	// Validate if the Jira Server Webhook is created successfully
	validateSumoLogicJiraServerWebhook(t, terraformOptions)
	// Validate if the Jira Service Desk Webhook is created successfully
	validateSumoLogicJiraServiceDeskWebhook(t, terraformOptions)
	// Validate if the Jira Server App is installed
	validateSumoLogicJiraServerAppInstallation(t, terraformOptions, folderName)
	// Validate if the Jira Cloud App is installed
	validateSumoLogicJiraCloudAppInstallation(t, terraformOptions, folderName)
	// Validate if the Bitbucket App is installed
	validateSumoLogicBitbucketAppInstallation(t, terraformOptions, folderName)
	// Validate if the Opsgenie App is installed
	validateSumoLogicOpsgenieAppInstallation(t, terraformOptions, folderName)
	// Validate if the Pagerduty App is installed
	validateSumoLogicPagerdutyAppInstallation(t, terraformOptions, folderName)
	// Validate if the Github App is installed
	validateSumoLogicGithubAppInstallation(t, terraformOptions, folderName)
	// Validate if the jenkins App is installed
	validateSumoLogicJenkinsAppInstallation(t, terraformOptions, folderName)
	// Validate if the Github Field is added successfully
	validateSumoLogicGithubField(t, terraformOptions)
	// Validate if the Bitbucket Field is added successfully
	validateSumoLogicBitbucketField(t, terraformOptions)
	// Validate if the Bitbucket PR FER is added successfully
	validateSumoLogicBitbucketPrFER(t, terraformOptions)
	// Validate if the Bitbucket Build FER is added successfully
	validateSumoLogicBitbucketBuildFER(t, terraformOptions)
	// Validate if the Bitbucket Deploy FER is added successfully
	validateSumoLogicBitbucketDeployFER(t, terraformOptions)
	// Validate if the Jenkins Build FER is added successfully
	validateSumoLogicJenkinsBuildFER(t, terraformOptions)
	// Validate if the Jenkins Deploy FER is added successfully
	validateSumoLogicJenkinsDeployFER(t, terraformOptions)
	// Validate if the Pagerduty alerts FER is added successfully
	validateSumoLogicPagerdutyAlertsFER(t, terraformOptions)
	// Validate if the Github PR FER is added successfully
	validateSumoLogicGithubPrFER(t, terraformOptions)
	// Validate if the Opsgenie Alerts FER is added successfully
	validateSumoLogicOpsgenieAlertsFER(t, terraformOptions)
	// Validate if the Jira Cloud FER is added successfully
	validateSumoLogicJiraFER(t, terraformOptions)
}

func validateSumoLogicCollector(t *testing.T, terraformOptions *terraform.Options, collectorID string) {
	// Verify that we get back a 200 OK
	http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/collectors/%s", sumologicURL, collectorID), nil, headers, customValidation, nil)
}

func validateSumoLogicFolder(t *testing.T, terraformOptions *terraform.Options) {
	// Run `terraform output` to get the value of an output variable
	folderID := terraform.Output(t, terraformOptions, "folder_id")

	// Verify that we get back a 200 OK
	http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v2/content/folders/%s", sumologicURL, folderID), nil, headers, customValidation, nil)
}

func validateSumoLogicJiraServerSource(t *testing.T, terraformOptions *terraform.Options, collectorID string) {
	// Run `terraform output` to get the value of an output variable
	sourceID := terraform.Output(t, terraformOptions, "jira_server_source_id")
	if sourceID != "[]" && getProperty("install_jira_server") == "true" {
		sourceID = strings.Split(sourceID, "\"")[1]

		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/collectors/%s/sources/%s", sumologicURL, collectorID, sourceID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicJiraCloudSource(t *testing.T, terraformOptions *terraform.Options, collectorID string) {
	// Run `terraform output` to get the value of an output variable
	sourceID := terraform.Output(t, terraformOptions, "jira_cloud_source_id")
	if sourceID != "[]" && getProperty("install_jira_cloud") == "true" {
		sourceID = strings.Split(sourceID, "\"")[1]

		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/collectors/%s/sources/%s", sumologicURL, collectorID, sourceID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicBitbucketSource(t *testing.T, terraformOptions *terraform.Options, collectorID string) {
	// Run `terraform output` to get the value of an output variable
	sourceID := terraform.Output(t, terraformOptions, "bitbucket_cloud_source_id")
	if sourceID != "[]" && getProperty("install_bitbucket_cloud") == "true" {
		sourceID = strings.Split(sourceID, "\"")[1]

		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/collectors/%s/sources/%s", sumologicURL, collectorID, sourceID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicOpsgenieSource(t *testing.T, terraformOptions *terraform.Options, collectorID string) {
	// Run `terraform output` to get the value of an output variable
	sourceID := terraform.Output(t, terraformOptions, "opsgenie_source_id")
	if sourceID != "[]" && getProperty("install_opsgenie") == "true" {
		sourceID = strings.Split(sourceID, "\"")[1]

		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/collectors/%s/sources/%s", sumologicURL, collectorID, sourceID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicGithubSource(t *testing.T, terraformOptions *terraform.Options, collectorID string) {
	// Run `terraform output` to get the value of an output variable
	sourceID := terraform.Output(t, terraformOptions, "github_source_id")
	if sourceID != "[]" && getProperty("install_github") == "true" {
		sourceID = strings.Split(sourceID, "\"")[1]

		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/collectors/%s/sources/%s", sumologicURL, collectorID, sourceID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicPagerdutySource(t *testing.T, terraformOptions *terraform.Options, collectorID string) {
	// Run `terraform output` to get the value of an output variable
	sourceID := terraform.Output(t, terraformOptions, "pagerduty_source_id")
	if sourceID != "[]" && getProperty("install_pagerduty") == "true" {
		sourceID = strings.Split(sourceID, "\"")[1]

		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/collectors/%s/sources/%s", sumologicURL, collectorID, sourceID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicPagerdutyWebhook(t *testing.T, terraformOptions *terraform.Options) {
	// Run `terraform output` to get the value of an output variable
	webhookID := terraform.Output(t, terraformOptions, "sumo_pagerduty_webhook_id")
	if webhookID != "[]" && getProperty("install_sumo_to_pagerduty_webhook") == "true" {
		webhookID = strings.Split(webhookID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/connections/%s", sumologicURL, webhookID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicOpsgenieWebhook(t *testing.T, terraformOptions *terraform.Options) {
	// Run `terraform output` to get the value of an output variable
	webhookID := terraform.Output(t, terraformOptions, "sumo_opsgenie_webhook_id")
	if webhookID != "[]" && getProperty("install_sumo_to_opsgenie_webhook") == "true" {
		webhookID = strings.Split(webhookID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/connections/%s", sumologicURL, webhookID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicJiraCloudWebhook(t *testing.T, terraformOptions *terraform.Options) {
	// Run `terraform output` to get the value of an output variable
	webhookID := terraform.Output(t, terraformOptions, "sumo_jiracloud_webhook_id")
	if webhookID != "[]" && getProperty("install_sumo_to_jiracloud_webhook") == "true" {
		webhookID = strings.Split(webhookID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/connections/%s", sumologicURL, webhookID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicJiraServerWebhook(t *testing.T, terraformOptions *terraform.Options) {
	// Run `terraform output` to get the value of an output variable
	webhookID := terraform.Output(t, terraformOptions, "sumo_jiraserver_webhook_id")
	if webhookID != "[]" && getProperty("install_sumo_to_jiraserver_webhook") == "true" {
		webhookID = strings.Split(webhookID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/connections/%s", sumologicURL, webhookID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicJiraServiceDeskWebhook(t *testing.T, terraformOptions *terraform.Options) {
	// Run `terraform output` to get the value of an output variable
	webhookID := terraform.Output(t, terraformOptions, "sumo_jiraservicedesk_webhook_id")
	if webhookID != "[]" && getProperty("install_sumo_to_jiraservicedesk_webhook") == "true" {
		webhookID = strings.Split(webhookID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/connections/%s", sumologicURL, webhookID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicJiraCloudAppInstallation(t *testing.T, terraformOptions *terraform.Options, folderName string) {

	if getProperty("install_jira_cloud") == "true" {
		appFolderPath := fmt.Sprintf("/Library/Users/%s/%s/Jira%%20Cloud", strings.Replace(os.Getenv("SUMOLOGIC_USERNAME"), "+", "%2B", -1), folderName)
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v2/content/path?path=%s", sumologicURL, appFolderPath), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicJiraServerAppInstallation(t *testing.T, terraformOptions *terraform.Options, folderName string) {

	if getProperty("install_jira_server") == "true" {
		appFolderPath := fmt.Sprintf("/Library/Users/%s/%s/Jira", strings.Replace(os.Getenv("SUMOLOGIC_USERNAME"), "+", "%2B", -1), folderName)
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v2/content/path?path=%s", sumologicURL, appFolderPath), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicBitbucketAppInstallation(t *testing.T, terraformOptions *terraform.Options, folderName string) {

	if getProperty("install_bitbucket_cloud") == "true" {
		appFolderPath := fmt.Sprintf("/Library/Users/%s/%s/Bitbucket", strings.Replace(os.Getenv("SUMOLOGIC_USERNAME"), "+", "%2B", -1), folderName)
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v2/content/path?path=%s", sumologicURL, appFolderPath), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicOpsgenieAppInstallation(t *testing.T, terraformOptions *terraform.Options, folderName string) {

	if getProperty("install_opsgenie") == "true" {
		appFolderPath := fmt.Sprintf("/Library/Users/%s/%s/Opsgenie", strings.Replace(os.Getenv("SUMOLOGIC_USERNAME"), "+", "%2B", -1), folderName)
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v2/content/path?path=%s", sumologicURL, appFolderPath), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicPagerdutyAppInstallation(t *testing.T, terraformOptions *terraform.Options, folderName string) {

	if getProperty("install_pagerduty") == "true" {
		appFolderPath := fmt.Sprintf("/Library/Users/%s/%s/Pagerduty%%20V2", strings.Replace(os.Getenv("SUMOLOGIC_USERNAME"), "+", "%2B", -1), folderName)
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v2/content/path?path=%s", sumologicURL, appFolderPath), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicGithubAppInstallation(t *testing.T, terraformOptions *terraform.Options, folderName string) {

	if getProperty("install_github") == "true" {
		appFolderPath := fmt.Sprintf("/Library/Users/%s/%s/Github", strings.Replace(os.Getenv("SUMOLOGIC_USERNAME"), "+", "%2B", -1), folderName)
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v2/content/path?path=%s", sumologicURL, appFolderPath), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicJenkinsAppInstallation(t *testing.T, terraformOptions *terraform.Options, folderName string) {

	if getProperty("install_jenkins") == "true" {
		appFolderPath := fmt.Sprintf("/Library/Users/%s/%s/Jenkins", strings.Replace(os.Getenv("SUMOLOGIC_USERNAME"), "+", "%2B", -1), folderName)
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v2/content/path?path=%s", sumologicURL, appFolderPath), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicGithubPrFER(t *testing.T, terraformOptions *terraform.Options) {

	// Run `terraform output` to get the value of an output variable
	ferID := terraform.Output(t, terraformOptions, "github_pr_fer_id")
	if ferID != "[]" && getProperty("install_github") == "true" {
		ferID = strings.Split(ferID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/extractionRules/%s", sumologicURL, ferID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicJenkinsBuildFER(t *testing.T, terraformOptions *terraform.Options) {

	// Run `terraform output` to get the value of an output variable
	ferID := terraform.Output(t, terraformOptions, "jenkins_build_fer_id")
	if ferID != "[]" && getProperty("install_jenkins") == "true" {
		ferID = strings.Split(ferID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/extractionRules/%s", sumologicURL, ferID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicJenkinsDeployFER(t *testing.T, terraformOptions *terraform.Options) {

	// Run `terraform output` to get the value of an output variable
	ferID := terraform.Output(t, terraformOptions, "jenkins_deploy_fer_id")
	if ferID != "[]" && getProperty("install_jenkins") == "true" {
		ferID = strings.Split(ferID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/extractionRules/%s", sumologicURL, ferID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicOpsgenieAlertsFER(t *testing.T, terraformOptions *terraform.Options) {

	// Run `terraform output` to get the value of an output variable
	ferID := terraform.Output(t, terraformOptions, "opsgenie_alerts_fer_id")
	if ferID != "[]" && getProperty("install_opsgenie") == "true" {
		ferID = strings.Split(ferID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/extractionRules/%s", sumologicURL, ferID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicBitbucketPrFER(t *testing.T, terraformOptions *terraform.Options) {

	// Run `terraform output` to get the value of an output variable
	ferID := terraform.Output(t, terraformOptions, "bitbucket_pr_fer_id")
	if ferID != "[]" && getProperty("install_bitbucket_cloud") == "true" {
		ferID = strings.Split(ferID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/extractionRules/%s", sumologicURL, ferID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicPagerdutyAlertsFER(t *testing.T, terraformOptions *terraform.Options) {

	// Run `terraform output` to get the value of an output variable
	ferID := terraform.Output(t, terraformOptions, "pagerduty_alerts_fer_id")
	if ferID != "[]" && getProperty("install_pagerduty") == "true" {
		ferID = strings.Split(ferID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/extractionRules/%s", sumologicURL, ferID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicJiraFER(t *testing.T, terraformOptions *terraform.Options) {

	// Run `terraform output` to get the value of an output variable
	ferID := terraform.Output(t, terraformOptions, "jira_issues_fer_id")
	if ferID != "[]" && (getProperty("install_jira_cloud") == "true" || getProperty("install_jira_server") == "true") {
		ferID = strings.Split(ferID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/extractionRules/%s", sumologicURL, ferID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicBitbucketDeployFER(t *testing.T, terraformOptions *terraform.Options) {

	// Run `terraform output` to get the value of an output variable
	ferID := terraform.Output(t, terraformOptions, "bitbucket_deploy_fer_id")
	if ferID != "[]" && getProperty("install_bitbucket_cloud") == "true" {
		ferID = strings.Split(ferID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/extractionRules/%s", sumologicURL, ferID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicBitbucketBuildFER(t *testing.T, terraformOptions *terraform.Options) {

	// Run `terraform output` to get the value of an output variable
	ferID := terraform.Output(t, terraformOptions, "bitbucket_build_fer_id")
	if ferID != "[]" && getProperty("install_bitbucket_cloud") == "true" {
		ferID = strings.Split(ferID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/extractionRules/%s", sumologicURL, ferID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicGithubField(t *testing.T, terraformOptions *terraform.Options) {

	// Run `terraform output` to get the value of an output variable
	fieldID := terraform.Output(t, terraformOptions, "sumo_github_field_id")
	if fieldID != "[]" && getProperty("install_github") == "true" {
		fieldID = strings.Split(fieldID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/fields/%s", sumologicURL, fieldID), nil, headers, customValidation, nil)
	}
}

func validateSumoLogicBitbucketField(t *testing.T, terraformOptions *terraform.Options) {

	// Run `terraform output` to get the value of an output variable
	fieldID := terraform.Output(t, terraformOptions, "sumo_bitbucket_field_id")
	if fieldID != "[]" && getProperty("install_bitbucket_cloud") == "true" {
		fieldID = strings.Split(fieldID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/api/v1/fields/%s", sumologicURL, fieldID), nil, headers, customValidation, nil)
	}
}

// Validate that the Atlassian Resources has been deployed
func validateAtlassianResources(t *testing.T, workingDir string) {

	// Load the Terraform Options saved by the earlier deploy_terraform stage
	terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
	validateAtlassianOpsgenieWebhook(t, terraformOptions)
	//validateAtlassianBitbucketWebhook(t, terraformOptions) - See method comment  as for why this  is commented.
	//validateAtlassianJiraServerWebhook(t, terraformOptions) - Commented because Webhook api's can be called only from connect apps. https://developer.atlassian.com/cloud/jira/platform/rest/v2/#api-rest-api-2-webhook-get
	//validateAtlassianJiraCloudWebhook(t, terraformOptions) - Commented because Webhook api's can be called only from connect apps. https://developer.atlassian.com/cloud/jira/platform/rest/v2/#api-rest-api-2-webhook-get
}

// Below function is commented because right now there is no way to identify workspace, repo and id mapping as the terraform creation returns  only id.
// https://github.com/terraform-providers/terraform-provider-bitbucket/blob/a677ca55116512a845b66e1d3df5973492d12328/bitbucket/resource_hook.go#L92
// https://developer.atlassian.com/bitbucket/api/2/reference/resource/repositories/%7Bworkspace%7D/%7Brepo_slug%7D
// func validateAtlassianBitbucketWebhook(t *testing.T, terraformOptions *terraform.Options) {
//  var bitbucketURL = "https://api.bitbucket.org"
//  var bitbucketheaders = map[string]string{"Authorization": "Basic " + base64.StdEncoding.EncodeToString([]byte("bitbucket_username:bitbucket_password"))}
// 	// Run `terraform output` to get the value of an output variable
// 	webhookID := terraform.Output(t, terraformOptions, "bitbucket_webhook_id")
// 	if webhookID != "[]" {
// 		webhookID = strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(webhookID, "{", "", -1), "}", "", -1), "[", "", -1), "]", "", -1), "\"", "", -1)
// 		webhookIDs := strings.Split(webhookID, ",")
// 		for i := 0; i < len(webhookIDs); i++ {
// 			// Verify that we get back a 200 OK
// 			http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/2.0/repositories/<workspace>/<repo>/hooks/%s", bitbucketURL, strings.TrimSpace(webhookIDs[i])), nil, bitbucketheaders, customValidation, nil)
// 		}
// 	}
// }

func validateAtlassianOpsgenieWebhook(t *testing.T, terraformOptions *terraform.Options) {
	var opsProps = loadPropertiesFile("../atlassian.auto.tfvars")
	var opsgenieURL = opsProps["opsgenie_api_url"]
	var opsgenieheaders = map[string]string{"Authorization": "GenieKey " + opsProps["opsgenie_key"], "Content-Type": "application/json"}
	// Run `terraform output` to get the value of an output variable
	webhookID := terraform.Output(t, terraformOptions, "opsgenie_webhook_id")
	if webhookID != "[]" && getProperty("install_opsgenie") == "true" {
		webhookID = strings.Split(webhookID, "\"")[1]
		// Verify that we get back a 200 OK
		http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("%s/v2/integrations/%s", opsgenieURL, webhookID), nil, opsgenieheaders, customValidation, nil)
	}
}

func validatePagerdutyToSumologicWebhook(t *testing.T, workingDir string) {
	terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
	var pdProps = loadPropertiesFile("../pagerduty.auto.tfvars")
	var pdheaders = map[string]string{"Authorization": "Token token=" + pdProps["pagerduty_api_key"], "Accept": "application/vnd.pagerduty+json;version=2"}
	// Run `terraform output` to get the value of an output variable
	webhookID := terraform.Output(t, terraformOptions, "pagerduty_webhook_id")
	if webhookID != "[]" && getProperty("install_pagerduty") == "true" {
		webhookID = strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(webhookID, "{", "", -1), "}", "", -1), "[", "", -1), "]", "", -1), "\"", "", -1)
		webhookIDs := strings.Split(webhookID, ",")
		for i := 0; i < len(webhookIDs); i++ {
			// Verify that we get back a 200 OK
			http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("https://api.pagerduty.com/extensions/%s", strings.TrimSpace(webhookIDs[i])), nil, pdheaders, customValidation, nil)
		}
	}
}

/* In - Progress
func validateGithubToSumologicWebhook(t *testing.T, workingDir string) {
	terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
	var ghProps = loadPropertiesFile("../github.auto.tfvars")
	var ghheaders = map[string]string{"Authorization": "token " + ghProps["github_token"], "Accept": "application/vnd.github.v3+json"}
	// Run `terraform output` to get the value of an output variable
	repoWebhookID := terraform.Output(t, terraformOptions, "github_repo_webhook_id")
	if repoWebhookID != "[]" && getProperty("install_github") == "true" && getProperty("github_repo_webhook_create") == "true" {
		repoWebhookID = strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(repoWebhookID, "{", "", -1), "}", "", -1), "[", "", -1), "]", "", -1), "\"", "", -1)
		webhookIDs := strings.Split(repoWebhookID, ",")
		for i := 0; i < len(webhookIDs); i++ {
			// Verify that we get back a 200 OK
			http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("https://api.github.com/repos/{owner}/{repo}/hooks/{hook_id}/%s", ghProps["github_organiztion"], ghProps["github_token"], strings.TrimSpace(webhookIDs[i])), nil, ghheaders, customValidation, nil)
		}
	}

	// Run `terraform output` to get the value of an output variable
	orgWebhookID := terraform.Output(t, terraformOptions, "github_org_webhook_id")
	if orgWebhookID != "[]" && getProperty("install_github") == "true" && getProperty("github_org_webhook_create") == "true" {
		orgWebhookID = strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(orgWebhookID, "{", "", -1), "}", "", -1), "[", "", -1), "]", "", -1), "\"", "", -1)
		webhookIDs := strings.Split(orgWebhookID, ",")
		for i := 0; i < len(webhookIDs); i++ {
			// Verify that we get back a 200 OK
			http_helper.HTTPDoWithCustomValidation(t, "GET", fmt.Sprintf("https://api.github.com/extensions/%s", strings.TrimSpace(webhookIDs[i])), nil, ghheaders, customValidation, nil)
		}
	}
}
*/

// Deploy the resources using Terraform
func deployTerraform(t *testing.T, workingDir string, collectorName string) {

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: workingDir,

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"collector_name": collectorName,
		},

		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: true,
	}

	// Save the Terraform Options struct, instance name, and instance text so future test stages can use it
	test_structure.SaveTerraformOptions(t, workingDir, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)
}

// Destroy the resources using Terraform
func destroyTerraform(t *testing.T, workingDir string) {
	// Load the Terraform Options saved by the earlier deploy_terraform stage
	terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)

	terraform.Destroy(t, terraformOptions)
}
