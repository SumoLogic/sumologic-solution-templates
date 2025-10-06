package test

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/joho/godotenv"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Initialize environment variables from .env.test file
func init() {
	if err := godotenv.Load(".env.test"); err != nil {
		log.Printf("Warning: .env.test file not found, using system environment variables")
	}
}

// Helper function to get required environment variable (no defaults)
func getRequiredEnv(key string) string {
	value := os.Getenv(key)
	if value == "" {
		log.Fatalf("Required environment variable %s is not set. Please check your .env.test file.", key)
	}
	return value
}

func TestSumoLogicResourceTypesValidation(t *testing.T) {
	terraformDir := "../"

	// Test cases for Sumo Logic apps/resources
	testCases := []struct {
		name        string
		appsList    []map[string]string
		shouldPass  bool
		description string
	}{
		{
			name: "ValidApps",
			appsList: []map[string]string{
				{"uuid": "53376d23-2687-4500-b61e-4a2e2a119658", "name": "Azure Storage", "version": "1.0.3"},
				{"uuid": "b20abced-0122-4c7a-8833-c68c3c29c3d3", "name": "Azure Key Vault", "version": "1.0.2"},
			},
			shouldPass:  true,
			description: "Valid UUIDs, names, and versions should pass validation",
		},
		{
			name: "InvalidEmptyApps",
			appsList: []map[string]string{
				{"uuid": "", "name": "", "version": ""},
				{"uuid": "53376d23-2687-4500-b61e-4a2e2a119658", "name": "Azure Storage", "version": "1.0.3"},
			},
			shouldPass:  false,
			description: "Empty UUIDs, names, and versions should fail validation",
		},
		{
			name: "InvalidUUID",
			appsList: []map[string]string{
				{"uuid": "invalid-uuid", "name": "Test App", "version": "1.0.0"},
			},
			shouldPass:  false,
			description: "Invalid UUID format should fail validation",
		},
		{
			name: "InvalidVersion",
			appsList: []map[string]string{
				{"uuid": "53376d23-2687-4500-b61e-4a2e2a119658", "name": "Test App", "version": "invalid"},
			},
			shouldPass:  false,
			description: "Invalid semantic version should fail validation",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Get test collector name from environment
			testCollectorName := getRequiredEnv("TEST_COLLECTOR_NAME") // Create tfvars content for Sumo Logic apps
			tfvarsContent := fmt.Sprintf(`
installation_apps_list = %s
sumo_collector_name = "%s"
# Other variables will use defaults from variables.tf or environment
`, formatAppsList(tc.appsList), testCollectorName)

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-sumo-%s.tfvars", tc.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-sumo-%s.tfvars", tc.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and check if it succeeds or fails as expected
			_, err = terraform.PlanE(t, terraformOptions)

			if tc.shouldPass {
				// For positive cases, we might get API errors trying to create resources
				// We only care about validation errors, not API/resource errors
				if err != nil {
					// Check if this is a validation error vs an API error
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tc.name, err)
					}
					// Else it's likely an API error which is expected for validation-only tests
					t.Logf("Test case '%s' passed validation but failed at runtime (expected): %v", tc.name, err)
				}
			} else {
				assert.Error(t, err, tc.description)
				// Could add specific error message checks here based on validation rules
			}
		})
	}
}

// Helper function to format apps list for tfvars
func formatAppsList(appsList []map[string]string) string {
	if len(appsList) == 0 {
		return "[]"
	}

	var formattedApps []string
	for _, app := range appsList {
		var fields []string

		if uuid, exists := app["uuid"]; exists {
			fields = append(fields, fmt.Sprintf(`uuid = "%s"`, uuid))
		}
		if name, exists := app["name"]; exists {
			fields = append(fields, fmt.Sprintf(`name = "%s"`, name))
		}
		if version, exists := app["version"]; exists {
			fields = append(fields, fmt.Sprintf(`version = "%s"`, version))
		}

		formattedApp := fmt.Sprintf("{\n    %s\n  }", strings.Join(fields, "\n    "))
		formattedApps = append(formattedApps, formattedApp)
	}

	return fmt.Sprintf("[\n  %s\n]", strings.Join(formattedApps, ",\n  "))
}

func TestSumoLogicCollectorResourceConfiguration(t *testing.T) {
	// Get configuration from environment variables (required)
	subscriptionID := getRequiredEnv("AZURE_SUBSCRIPTION_ID")
	testCollectorName := getRequiredEnv("TEST_COLLECTOR_NAME")

	tests := []struct {
		name                  string
		collectorName         string
		expectedCollectorName string
		expectError           bool
		description           string
	}{
		{
			name:                  "ValidCollectorConfiguration",
			collectorName:         testCollectorName,
			expectedCollectorName: fmt.Sprintf("%s-%s", testCollectorName, subscriptionID),
			expectError:           false,
			description:           "Valid collector with proper naming",
		},
		{
			name:                  "ValidCollectorWithDashes",
			collectorName:         "Test-Collector-Name",
			expectedCollectorName: fmt.Sprintf("Test-Collector-Name-%s", subscriptionID),
			expectError:           false,
			description:           "Collector name with dashes should work",
		},
		{
			name:                  "ValidCollectorWithUnderscores",
			collectorName:         "Test_Collector_Name",
			expectedCollectorName: fmt.Sprintf("Test_Collector_Name-%s", subscriptionID),
			expectError:           false,
			description:           "Collector name with underscores should work",
		},
		{
			name:                  "CollectorNameWithSpecialChars",
			collectorName:         "Test@Collector#Name",
			expectedCollectorName: "",
			expectError:           true,
			description:           "Collector name with special characters should fail validation",
		},
		{
			name:                  "EmptyCollectorName",
			collectorName:         "",
			expectedCollectorName: "",
			expectError:           true,
			description:           "Empty collector name should fail validation",
		},
		{
			name:                  "LongCollectorName",
			collectorName:         strings.Repeat("X", 129),
			expectedCollectorName: "",
			expectError:           true,
			description:           "Collector name exceeding 128 characters should fail validation",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			terraformDir := "../"

			// Create temporary tfvars file
			tfvarsContent := fmt.Sprintf(`
sumo_collector_name = "%s"
installation_apps_list = []
# Other variables will use defaults from variables.tf or environment
`, tt.collectorName)

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-collector-%s.tfvars", tt.name))
			defer os.Remove(tfvarsFile)

			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			require.NoError(t, err)

			// Test terraform plan (validation only)
			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-collector-%s.tfvars", tt.name)},
				PlanFilePath: fmt.Sprintf("test-collector-plan-%s.out", tt.name),
			}
			defer os.Remove(terraformOptions.PlanFilePath)

			terraform.Init(t, terraformOptions)

			planOutput, err := terraform.PlanE(t, terraformOptions)

			if tt.expectError {
				assert.Error(t, err, "Expected terraform plan to fail: %s", tt.description)
			} else {
				// For positive cases, we might get API errors trying to create resources
				// We only care about validation errors, not API/resource errors
				if err != nil {
					// Check if this is a validation error vs an API error
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					}
					// Else it's likely an API error which is expected for validation-only tests
					t.Logf("Test case '%s' passed validation but failed at runtime (expected): %v", tt.name, err)
				} else {
					// Verify the plan contains expected collector resource
					assert.Contains(t, planOutput, "sumologic_collector.sumo_collector",
						"Plan should contain sumologic_collector resource")

					// If we have an expected name, verify it appears in the plan
					if tt.expectedCollectorName != "" {
						assert.Contains(t, planOutput, tt.expectedCollectorName,
							"Plan should contain expected collector name: %s", tt.expectedCollectorName)
					}

					// Verify collector description is present
					assert.Contains(t, planOutput, "Azure Collector",
						"Plan should contain collector description")

					// Verify tenant_name field is set
					assert.Contains(t, planOutput, "azure_account",
						"Plan should contain tenant_name field")
				}
			}
		})
	}
}

func TestSumoLogicEventHubLogSourceConfiguration(t *testing.T) {
	// Get configuration from environment variables (required)
	keyVaultResourceType := getRequiredEnv("TARGET_KEYVAULT_TYPE")
	storageAccountResourceType := getRequiredEnv("TARGET_STORAGE_TYPE")
	testCollectorName := getRequiredEnv("TEST_COLLECTOR_NAME")
	invalidResourceType := "Microsoft.Invalid/nonExistentType" // This passes format validation but doesn't exist in Azure

	// Define comprehensive expected content patterns
	azureEventHubLogContent := map[string]string{
		"content_type": "AzureEventHubLog",
		"type":         "AzureEventHubAuthentication",
	}

	// Create comprehensive expected content for single resource type
	singleResourceTypeContent := make(map[string]string)
	for k, v := range azureEventHubLogContent {
		singleResourceTypeContent[k] = v
	}
	// Main resource properties
	singleResourceTypeContent["content_type"] = "AzureEventHubLog"
	singleResourceTypeContent["category_prefix"] = fmt.Sprintf("azure/logs/%s-", keyVaultResourceType)
	singleResourceTypeContent["description_prefix"] = "Azure Logs Source for"

	// Authentication block properties
	singleResourceTypeContent["auth_type"] = "AzureEventHubAuthentication"
	singleResourceTypeContent["shared_access_policy_name"] = "SumoCollectionPolicy"

	// Path block properties
	singleResourceTypeContent["path_type"] = "AzureEventHubPath"
	singleResourceTypeContent["consumer_group"] = "$Default"
	singleResourceTypeContent["region"] = "Commercial"
	singleResourceTypeContent["eventhub_name_prefix"] = fmt.Sprintf("eventhub-%s", strings.ReplaceAll(keyVaultResourceType, "/", "-"))
	singleResourceTypeContent["namespace_pattern"] = "SUMO-.*-Hub-"

	tests := []struct {
		name            string
		resourceTypes   []string
		expectError     bool
		description     string
		expectedContent map[string]string // Expected content in plan
	}{
		{
			name:            "ValidSingleResourceType",
			resourceTypes:   []string{keyVaultResourceType},
			expectError:     false,
			description:     "Valid single resource type should create log source",
			expectedContent: singleResourceTypeContent,
		},
		{
			name:            "ValidMultipleResourceTypes",
			resourceTypes:   []string{keyVaultResourceType, storageAccountResourceType},
			expectError:     false,
			description:     "Multiple resource types should create multiple log sources",
			expectedContent: azureEventHubLogContent,
		},
		{
			name:            "EmptyResourceTypes",
			resourceTypes:   []string{},
			expectError:     false,
			description:     "Empty resource types should not create any log sources",
			expectedContent: map[string]string{},
		},
		{
			name:            "InvalidResourceTypeFormat",
			resourceTypes:   []string{invalidResourceType},
			expectError:     false, // This passes terraform validation but creates no resources since type doesn't exist
			description:     "Invalid resource type format should create no resources",
			expectedContent: map[string]string{
				// No expected content since invalid resource types should not create any resources
			},
		},
		{
			name:            "InvalidResourceTypeFormatWithoutSlash",
			resourceTypes:   []string{"InvalidFormatNoSlash"},
			expectError:     true,
			description:     "Resource type without slash should fail validation",
			expectedContent: map[string]string{},
		},
		{
			name:            "DuplicateResourceTypes",
			resourceTypes:   []string{keyVaultResourceType, keyVaultResourceType},
			expectError:     true,
			description:     "Duplicate resource types should fail validation",
			expectedContent: map[string]string{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			terraformDir := "../"

			// Create temporary tfvars file
			tfvarsContent := fmt.Sprintf(`
target_resource_types = %s
installation_apps_list = []
sumo_collector_name = "%s"
# Other variables will use defaults from variables.tf or environment
`, formatResourceTypes(tt.resourceTypes), testCollectorName)

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-logsource-%s.tfvars", tt.name))
			defer os.Remove(tfvarsFile)

			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			require.NoError(t, err)

			// Test terraform plan (validation only)
			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-logsource-%s.tfvars", tt.name)},
				PlanFilePath: fmt.Sprintf("test-logsource-plan-%s.out", tt.name),
			}
			defer os.Remove(terraformOptions.PlanFilePath)

			terraform.Init(t, terraformOptions)

			planOutput, err := terraform.PlanE(t, terraformOptions)

			if tt.expectError {
				assert.Error(t, err, "Expected terraform plan to fail: %s", tt.description)
			} else {
				// For positive cases, we might get API errors trying to create resources
				// We only care about validation errors, not API/resource errors
				if err != nil {
					// Check if this is a validation error vs an API error
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					}
					// Else it's likely an API error which is expected for validation-only tests
					t.Logf("Test case '%s' passed validation but failed at runtime (expected): %v", tt.name, err)
				} else {
					// Clean the plan output of ANSI escape sequences before checking content
					cleanPlanOutput := stripANSI(planOutput)

					// Debug: Print what we're looking for vs what we have
					t.Logf("Looking for expected content in plan output...")

					// Verify expected content appears in the plan
					for key, expectedValue := range tt.expectedContent {
						switch key {
						case "content_type":
							// Search for the value in terraform output format
							assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
								"Plan should contain correct content_type")
						case "type", "auth_type":
							// Search for the value in terraform output format
							assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
								"Plan should contain correct authentication type")
						case "path_type":
							// Search for the path type in terraform output format
							assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
								"Plan should contain correct path type")
						case "consumer_group":
							// Search for the value in terraform output format, accounting for special chars
							assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
								"Plan should contain correct consumer_group")
						case "region":
							// Search for the value in terraform output format
							assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
								"Plan should contain correct region")
						case "shared_access_policy_name":
							// Search for the policy name in terraform output format
							assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
								"Plan should contain correct shared access policy name")
						case "category":
							// Search for the value in terraform output format
							assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
								"Plan should contain correct category format")
						case "category_prefix":
							// For dynamic category format, check if category starts with expected prefix
							assert.Contains(t, cleanPlanOutput, expectedValue,
								"Plan should contain category with correct prefix: %s", expectedValue)
						case "description_prefix":
							// Check if description contains the expected prefix
							assert.Contains(t, cleanPlanOutput, expectedValue,
								"Plan should contain description with correct prefix: %s", expectedValue)
						case "eventhub_name_prefix":
							// Check if eventhub name contains the expected prefix
							assert.Contains(t, cleanPlanOutput, expectedValue,
								"Plan should contain eventhub name with correct prefix: %s", expectedValue)
						case "namespace_pattern":
							// Use regex to check namespace pattern
							namespaceRegex := regexp.MustCompile(expectedValue)
							assert.True(t, namespaceRegex.MatchString(cleanPlanOutput),
								"Plan should contain namespace matching pattern: %s", expectedValue)
						}
					}

					// Check if this is a negative test case (invalid resource types)
					isNegativeTest := false
					for _, resourceType := range tt.resourceTypes {
						if strings.Contains(strings.ToLower(resourceType), "invalid") {
							isNegativeTest = true
							break
						}
					}

					// If we have resource types, verify resources based on test type
					if len(tt.resourceTypes) > 0 {
						if isNegativeTest {
							// For negative tests, assert that no resources are created
							assert.NotContains(t, planOutput, "sumologic_azure_event_hub_log_source.sumo_azure_event_hub_log_source",
								"Plan should NOT contain log source resources for invalid resource types")
							assert.NotContains(t, planOutput, "azurerm_eventhub.eventhub",
								"Plan should NOT contain eventhub resources for invalid resource types")
						} else {
							// For positive tests, verify log source resources are created
							assert.Contains(t, planOutput, "sumologic_azure_event_hub_log_source.sumo_azure_event_hub_log_source",
								"Plan should contain log source resources")

							// Verify that eventhub names follow the expected pattern
							for _, resourceType := range tt.resourceTypes {
								expectedEventHubName := fmt.Sprintf("eventhub-%s", strings.ReplaceAll(resourceType, "/", "-"))
								assert.Contains(t, planOutput, expectedEventHubName,
									"Plan should contain eventhub with correct name pattern: %s", expectedEventHubName)
							}
						}
					}
				}
			}
		})
	}
}

// Helper function to format resource types for tfvars
func formatResourceTypes(resourceTypes []string) string {
	if len(resourceTypes) == 0 {
		return "[]"
	}

	var formattedTypes []string
	for _, resourceType := range resourceTypes {
		formattedTypes = append(formattedTypes, fmt.Sprintf(`"%s"`, resourceType))
	}

	return fmt.Sprintf("[%s]", strings.Join(formattedTypes, ", "))
}

func TestSumoLogicActivityLogSourceConfiguration(t *testing.T) {
	// Get configuration from environment variables (required)
	testCollectorName := getRequiredEnv("TEST_COLLECTOR_NAME")
	activityLogExportName := getRequiredEnv("AZURE_ACTIVITY_LOG_EXPORT_NAME")
	activityLogExportCategory := getRequiredEnv("AZURE_ACTIVITY_LOG_EXPORT_CATEGORY")

	tests := []struct {
		name               string
		enableActivityLogs bool
		expectError        bool
		description        string
		expectedContent    map[string]string
	}{
		{
			name:               "ActivityLogsEnabled",
			enableActivityLogs: true,
			expectError:        false,
			description:        "Activity logs enabled should create activity log source",
			expectedContent: map[string]string{
				"resource_name":         "sumologic_azure_event_hub_log_source.sumo_activity_log_source",
				"content_type":          "AzureEventHubLog",
				"auth_type":             "AzureEventHubAuthentication",
				"path_type":             "AzureEventHubPath",
				"consumer_group":        "$Default",
				"region":                "Commercial",
				"description":           "Azure Subscription Activity Logs",
				"activity_log_name":     activityLogExportName,
				"activity_log_category": activityLogExportCategory,
			},
		},
		{
			name:               "ActivityLogsDisabled",
			enableActivityLogs: false,
			expectError:        false,
			description:        "Activity logs disabled should not create activity log source",
			expectedContent:    map[string]string{
				// No expected content since resource should not be created
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			terraformDir := "../"

			// Create temporary tfvars file
			tfvarsContent := fmt.Sprintf(`
sumo_collector_name = "%s"
enable_activity_logs = %t
activity_log_export_name = "%s"
activity_log_export_category = "%s"
installation_apps_list = []
target_resource_types = []
# Other variables will use defaults from variables.tf or environment
`, testCollectorName, tt.enableActivityLogs, activityLogExportName, activityLogExportCategory)

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-activity-log-%s.tfvars", tt.name))
			defer os.Remove(tfvarsFile)

			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			require.NoError(t, err)

			// Test terraform plan (validation only)
			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-activity-log-%s.tfvars", tt.name)},
				PlanFilePath: fmt.Sprintf("test-activity-log-plan-%s.out", tt.name),
			}
			defer os.Remove(terraformOptions.PlanFilePath)

			terraform.Init(t, terraformOptions)

			planOutput, err := terraform.PlanE(t, terraformOptions)

			if tt.expectError {
				assert.Error(t, err, "Expected terraform plan to fail: %s", tt.description)
			} else {
				// For positive cases, we might get API errors trying to create resources
				// We only care about validation errors, not API/resource errors
				if err != nil {
					// Check if this is a validation error vs an API error
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					}
					// Else it's likely an API error which is expected for validation-only tests
					t.Logf("Test case '%s' passed validation but failed at runtime (expected): %v", tt.name, err)
				} else {
					// Clean the plan output of ANSI escape sequences before checking content
					cleanPlanOutput := stripANSI(planOutput)

					// Debug: Print what we're looking for vs what we have
					t.Logf("Looking for expected content in plan output for activity logs...")

					if tt.enableActivityLogs {
						// When activity logs are enabled, verify the resource is created
						for key, expectedValue := range tt.expectedContent {
							switch key {
							case "resource_name":
								assert.Contains(t, cleanPlanOutput, expectedValue,
									"Plan should contain activity log source resource")
							case "content_type":
								assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
									"Plan should contain correct content_type for activity logs")
							case "auth_type":
								assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
									"Plan should contain correct authentication type for activity logs")
							case "path_type":
								assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
									"Plan should contain correct path type for activity logs")
							case "consumer_group":
								assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
									"Plan should contain correct consumer_group for activity logs")
							case "region":
								assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
									"Plan should contain correct region for activity logs")
							case "description":
								assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
									"Plan should contain correct description for activity logs")
							case "activity_log_name":
								assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
									"Plan should contain correct activity log name")
							case "activity_log_category":
								assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
									"Plan should contain correct activity log category")
							}
						}

						// Verify related activity log resources are also created
						assert.Contains(t, cleanPlanOutput, "azurerm_eventhub_namespace.activity_logs_namespace",
							"Plan should contain activity logs namespace when activity logs are enabled")
						assert.Contains(t, cleanPlanOutput, "azurerm_eventhub.eventhub_for_activity_logs",
							"Plan should contain activity logs eventhub when activity logs are enabled")
						assert.Contains(t, cleanPlanOutput, "azurerm_eventhub_namespace_authorization_rule.activity_logs_policy",
							"Plan should contain activity logs authorization rule when activity logs are enabled")
					} else {
						// When activity logs are disabled, verify the resource is NOT created
						assert.NotContains(t, cleanPlanOutput, "sumologic_azure_event_hub_log_source.sumo_activity_log_source",
							"Plan should NOT contain activity log source resource when activity logs are disabled")
						assert.NotContains(t, cleanPlanOutput, "azurerm_eventhub_namespace.activity_logs_namespace",
							"Plan should NOT contain activity logs namespace when activity logs are disabled")
						assert.NotContains(t, cleanPlanOutput, "azurerm_eventhub.eventhub_for_activity_logs",
							"Plan should NOT contain activity logs eventhub when activity logs are disabled")
						assert.NotContains(t, cleanPlanOutput, "azurerm_eventhub_namespace_authorization_rule.activity_logs_policy",
							"Plan should NOT contain activity logs authorization rule when activity logs are disabled")
					}
				}
			}
		})
	}
}

func TestSumoLogicAzureMetricsSourceConfiguration(t *testing.T) {
	// Get configuration from environment variables (required)
	testCollectorName := getRequiredEnv("TEST_COLLECTOR_NAME")
	azureTenantID := getRequiredEnv("AZURE_TENANT_ID")
	azureClientID := getRequiredEnv("AZURE_CLIENT_ID")
	azureClientSecret := getRequiredEnv("AZURE_CLIENT_SECRET")
	keyVaultResourceType := getRequiredEnv("TARGET_KEYVAULT_TYPE")
	storageAccountResourceType := getRequiredEnv("TARGET_STORAGE_TYPE")

	tests := []struct {
		name            string
		resourceTypes   []string
		expectError     bool
		description     string
		expectedContent map[string]string
	}{
		{
			name:          "ValidSingleResourceTypeMetrics",
			resourceTypes: []string{keyVaultResourceType},
			expectError:   false,
			description:   "Valid single resource type should create metrics source",
			expectedContent: map[string]string{
				"resource_name":   "sumologic_azure_metrics_source.terraform_azure_metrics_source",
				"content_type":    "AzureMetrics",
				"auth_type":       "AzureClientSecretAuthentication",
				"path_type":       "AzureMetricsPath",
				"environment":     "Azure",
				"tenant_id":       azureTenantID,
				"client_id":       azureClientID,
				"name_pattern":    strings.ReplaceAll(strings.ReplaceAll(keyVaultResourceType, "/", "-"), ".", "-"),
				"category_prefix": fmt.Sprintf("azure/%s/metrics", strings.ToLower(strings.ReplaceAll(strings.ReplaceAll(keyVaultResourceType, "/", "-"), ".", "-"))),
				"description":     fmt.Sprintf("Metrics for %s", keyVaultResourceType),
			},
		},
		{
			name:          "ValidMultipleResourceTypesMetrics",
			resourceTypes: []string{keyVaultResourceType, storageAccountResourceType},
			expectError:   false,
			description:   "Multiple resource types should create multiple metrics sources",
			expectedContent: map[string]string{
				"resource_name": "sumologic_azure_metrics_source.terraform_azure_metrics_source",
				"content_type":  "AzureMetrics",
				"auth_type":     "AzureClientSecretAuthentication",
				"path_type":     "AzureMetricsPath",
				"environment":   "Azure",
				"tenant_id":     azureTenantID,
				"client_id":     azureClientID,
			},
		},
		{
			name:            "EmptyResourceTypesMetrics",
			resourceTypes:   []string{},
			expectError:     false,
			description:     "Empty resource types should not create any metrics sources",
			expectedContent: map[string]string{
				// No expected content since no resources should be created
			},
		},
		{
			name:            "NonExistentResourceTypeMetrics",
			resourceTypes:   []string{"Microsoft.Invalid/nonExistentType"},
			expectError:     false, // This passes terraform validation but creates no resources since type doesn't exist
			description:     "Non-existent resource type should create no metrics resources",
			expectedContent: map[string]string{
				// No expected content since non-existent resource types should not create any resources
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			terraformDir := "../"

			// Create temporary tfvars file
			tfvarsContent := fmt.Sprintf(`
target_resource_types = %s
installation_apps_list = []
sumo_collector_name = "%s"
azure_tenant_id = "%s"
azure_client_id = "%s"
azure_client_secret = "%s"
# Other variables will use defaults from variables.tf or environment
`, formatResourceTypes(tt.resourceTypes), testCollectorName, azureTenantID, azureClientID, azureClientSecret)

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-metrics-%s.tfvars", tt.name))
			defer os.Remove(tfvarsFile)

			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			require.NoError(t, err)

			// Test terraform plan (validation only)
			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-metrics-%s.tfvars", tt.name)},
				PlanFilePath: fmt.Sprintf("test-metrics-plan-%s.out", tt.name),
			}
			defer os.Remove(terraformOptions.PlanFilePath)

			terraform.Init(t, terraformOptions)

			planOutput, err := terraform.PlanE(t, terraformOptions)

			if tt.expectError {
				assert.Error(t, err, "Expected terraform plan to fail: %s", tt.description)
			} else {
				// For positive cases, we might get API errors trying to create resources
				// We only care about validation errors, not API/resource errors
				if err != nil {
					// Check if this is a validation error vs an API error
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					}
					// Else it's likely an API error which is expected for validation-only tests
					t.Logf("Test case '%s' passed validation but failed at runtime (expected): %v", tt.name, err)
				} else {
					// Clean the plan output of ANSI escape sequences before checking content
					cleanPlanOutput := stripANSI(planOutput)

					// Debug: Print what we're looking for vs what we have
					t.Logf("Looking for expected content in plan output for metrics sources...")

					// Verify expected content appears in the plan
					for key, expectedValue := range tt.expectedContent {
						switch key {
						case "resource_name":
							if len(tt.resourceTypes) > 0 && !isInvalidResourceType(tt.resourceTypes) {
								assert.Contains(t, cleanPlanOutput, expectedValue,
									"Plan should contain metrics source resource")
							} else {
								assert.NotContains(t, cleanPlanOutput, expectedValue,
									"Plan should NOT contain metrics source resource for empty/invalid resource types")
							}
						case "content_type":
							assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
								"Plan should contain correct content_type for metrics source")
						case "auth_type":
							assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
								"Plan should contain correct authentication type for metrics source")
						case "path_type":
							assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
								"Plan should contain correct path type for metrics source")
						case "environment":
							assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
								"Plan should contain correct environment for metrics source")
						case "tenant_id":
							assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
								"Plan should contain correct tenant_id for metrics source")
						case "client_id":
							assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
								"Plan should contain correct client_id for metrics source")
						case "name_pattern":
							assert.Contains(t, cleanPlanOutput, expectedValue,
								"Plan should contain correct name pattern: %s", expectedValue)
						case "category_prefix":
							assert.Contains(t, cleanPlanOutput, expectedValue,
								"Plan should contain category with correct prefix: %s", expectedValue)
						case "description":
							assert.Contains(t, cleanPlanOutput, fmt.Sprintf(`= "%s"`, expectedValue),
								"Plan should contain correct description: %s", expectedValue)
						}
					}

					// Additional verification for valid resource types
					if len(tt.resourceTypes) > 0 && !isInvalidResourceType(tt.resourceTypes) {
						// Verify that metrics sources are created for each resource type
						for _, resourceType := range tt.resourceTypes {
							expectedName := strings.ReplaceAll(strings.ReplaceAll(resourceType, "/", "-"), ".", "-")
							assert.Contains(t, planOutput, expectedName,
								"Plan should contain metrics source with correct name pattern: %s", expectedName)

							expectedCategory := fmt.Sprintf("azure/%s/metrics", strings.ToLower(expectedName))
							assert.Contains(t, planOutput, expectedCategory,
								"Plan should contain metrics source with correct category: %s", expectedCategory)

							expectedDescription := fmt.Sprintf("Metrics for %s", resourceType)
							assert.Contains(t, planOutput, expectedDescription,
								"Plan should contain metrics source with correct description: %s", expectedDescription)
						}

						// Verify authentication block contains required fields
						assert.Contains(t, planOutput, "AzureClientSecretAuthentication",
							"Plan should contain correct authentication type")
						assert.Contains(t, planOutput, azureTenantID,
							"Plan should contain tenant_id")
						assert.Contains(t, planOutput, azureClientID,
							"Plan should contain client_id")
						// Note: client_secret should be present but we won't assert its value for security

						// Verify path block contains required fields
						assert.Contains(t, planOutput, "AzureMetricsPath",
							"Plan should contain correct path type")
						assert.Contains(t, planOutput, "Azure",
							"Plan should contain correct environment")
						assert.Contains(t, planOutput, "limit_to_regions",
							"Plan should contain limit_to_regions configuration")
						assert.Contains(t, planOutput, "limit_to_namespaces",
							"Plan should contain limit_to_namespaces configuration")
					} else if len(tt.resourceTypes) == 0 || isInvalidResourceType(tt.resourceTypes) {
						// For empty or invalid resource types, verify no metrics sources are created
						assert.NotContains(t, planOutput, "sumologic_azure_metrics_source.terraform_azure_metrics_source",
							"Plan should NOT contain metrics source resources for empty/invalid resource types")
					}
				}
			}
		})
	}
}

// Helper function to check if resource types contain invalid entries
func isInvalidResourceType(resourceTypes []string) bool {
	for _, resourceType := range resourceTypes {
		if strings.Contains(strings.ToLower(resourceType), "invalid") {
			return true
		}
	}
	return false
}

// stripANSI removes ANSI escape sequences from a string
func stripANSI(str string) string {
	ansiRegex := regexp.MustCompile(`\x1b\[[0-9;]*m`)
	return ansiRegex.ReplaceAllString(str, "")
}

func TestAzureCredentialsValidation(t *testing.T) {
	// Test Azure credential validation in the context of metrics source configuration
	// This tests real-world scenarios where invalid Azure IDs would cause problems
	terraformDir := "../"
	testCollectorName := getRequiredEnv("TEST_COLLECTOR_NAME")
	validTenantID := getRequiredEnv("AZURE_TENANT_ID")
	validClientID := getRequiredEnv("AZURE_CLIENT_ID")
	validClientSecret := getRequiredEnv("AZURE_CLIENT_SECRET")

	tests := []struct {
		name         string
		tenantID     string
		clientID     string
		clientSecret string
		expectError  bool
		description  string
	}{
		{
			name:         "ValidAzureCredentials",
			tenantID:     validTenantID,
			clientID:     validClientID,
			clientSecret: validClientSecret,
			expectError:  false,
			description:  "Valid Azure credentials should pass validation",
		},
		{
			name:         "InvalidTenantIDFormat",
			tenantID:     "invalid-tenant-id-format",
			clientID:     validClientID,
			clientSecret: validClientSecret,
			expectError:  true,
			description:  "Invalid tenant ID format should fail validation",
		},
		{
			name:         "InvalidClientIDFormat",
			tenantID:     validTenantID,
			clientID:     "not-a-valid-uuid",
			clientSecret: validClientSecret,
			expectError:  true,
			description:  "Invalid client ID format should fail validation",
		},
		{
			name:         "EmptyTenantID",
			tenantID:     "",
			clientID:     validClientID,
			clientSecret: validClientSecret,
			expectError:  true,
			description:  "Empty tenant ID should fail validation",
		},
		{
			name:         "EmptyClientID",
			tenantID:     validTenantID,
			clientID:     "",
			clientSecret: validClientSecret,
			expectError:  true,
			description:  "Empty client ID should fail validation",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars content with Azure credentials
			tfvarsContent := fmt.Sprintf(`
target_resource_types = ["Microsoft.KeyVault/vaults"]
installation_apps_list = []
sumo_collector_name = "%s"
azure_tenant_id = "%s"
azure_client_id = "%s"
azure_client_secret = "%s"
`, testCollectorName, tt.tenantID, tt.clientID, tt.clientSecret)

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-azure-creds-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-azure-creds-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and check if it succeeds or fails as expected
			_, err = terraform.PlanE(t, terraformOptions)

			if tt.expectError {
				assert.Error(t, err, tt.description)
				// Verify it's a validation error, not an API error
				if err != nil {
					errStr := err.Error()
					assert.True(t,
						strings.Contains(errStr, "Invalid value for variable") ||
							strings.Contains(errStr, "validation rule") ||
							strings.Contains(errStr, "error_message"),
						"Should be a validation error, got: %v", err)
				}
			} else {
				// For valid configurations, we might get API errors trying to access resources
				// We only care that validation passed
				if err != nil {
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					} else {
						// API errors are expected for validation-only tests
						t.Logf("Test case '%s' passed validation but failed at runtime (expected): %v", tt.name, err)
					}
				}
			}
		})
	}
}

func TestResourceGroupNameValidation(t *testing.T) {
	// Test resource group name validation in the context of Azure resource creation
	// This tests real-world scenarios where invalid resource group names would cause problems
	terraformDir := "../"
	testCollectorName := getRequiredEnv("TEST_COLLECTOR_NAME")

	tests := []struct {
		name              string
		resourceGroupName string
		expectError       bool
		description       string
	}{
		{
			name:              "ValidResourceGroupName",
			resourceGroupName: "RG-SUMO-TEST",
			expectError:       false,
			description:       "Valid resource group name should pass validation",
		},
		{
			name:              "ResourceGroupNameWithSpaces",
			resourceGroupName: "RG SUMO TEST",
			expectError:       true,
			description:       "Resource group name with spaces should fail validation",
		},
		{
			name:              "ResourceGroupNameWithSpecialChars",
			resourceGroupName: "RG@SUMO#TEST",
			expectError:       true,
			description:       "Resource group name with special characters should fail validation",
		},
		{
			name:              "ReservedResourceGroupName",
			resourceGroupName: "Microsoft",
			expectError:       true,
			description:       "Reserved resource group name should fail validation",
		},
		{
			name:              "ResourceGroupNameEndingWithPeriod",
			resourceGroupName: "RG-SUMO-TEST.",
			expectError:       true,
			description:       "Resource group name ending with period should fail validation",
		},
		{
			name:              "EmptyResourceGroupName",
			resourceGroupName: "",
			expectError:       true,
			description:       "Empty resource group name should fail validation",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars content with resource group name
			tfvarsContent := fmt.Sprintf(`
target_resource_types = ["Microsoft.KeyVault/vaults"]
installation_apps_list = []
sumo_collector_name = "%s"
resource_group_name = "%s"
`, testCollectorName, tt.resourceGroupName)

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-rg-name-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-rg-name-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and check if it succeeds or fails as expected
			_, err = terraform.PlanE(t, terraformOptions)

			if tt.expectError {
				assert.Error(t, err, tt.description)
				// Verify it's a validation error, not an API error
				if err != nil {
					errStr := err.Error()
					assert.True(t,
						strings.Contains(errStr, "Invalid value for variable") ||
							strings.Contains(errStr, "validation rule") ||
							strings.Contains(errStr, "error_message"),
						"Should be a validation error, got: %v", err)
				}
			} else {
				// For valid configurations, we might get API errors trying to access resources
				// We only care that validation passed
				if err != nil {
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					} else {
						// API errors are expected for validation-only tests
						t.Logf("Test case '%s' passed validation but failed at runtime (expected): %v", tt.name, err)
					}
				}
			}
		})
	}
}
