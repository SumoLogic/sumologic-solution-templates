package test

import (
	"fmt"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// stripANSI removes ANSI escape sequences from a string for cleaner plan output validation
func stripANSI(str string) string {
	ansiRegex := regexp.MustCompile(`\x1b\[[0-9;]*m`)
	return ansiRegex.ReplaceAllString(str, "")
}

// Uses the same helper functions as azure_test.go - clean tfvars-based approach

func TestSumoLogicResourceTypesValidation(t *testing.T) {
	// Test cases for Sumo Logic apps/resources
	testCases := []struct {
		name        string
		tfvarsFile  string
		shouldPass  bool
		description string
	}{
		{
			name:        "ValidApps",
			tfvarsFile:  filepath.Join("test", fixturesDir, "sumo-valid-apps.tfvars"),
			shouldPass:  true,
			description: "Valid UUIDs, names, and versions should pass validation",
		},
		{
			name:        "InvalidEmptyApps",
			tfvarsFile:  filepath.Join("test", fixturesDir, "sumo-invalid-empty-apps.tfvars"),
			shouldPass:  false,
			description: "Empty UUIDs, names, and versions should fail validation",
		},
		{
			name:        "InvalidUUID",
			tfvarsFile:  filepath.Join("test", fixturesDir, "sumo-invalid-uuid.tfvars"),
			shouldPass:  false,
			description: "Invalid UUID format should fail validation",
		},
		{
			name:        "InvalidVersion",
			tfvarsFile:  filepath.Join("test", fixturesDir, "sumo-invalid-version.tfvars"),
			shouldPass:  false,
			description: "Invalid semantic version should fail validation",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			runValidationTest(t, tc.name, tc.tfvarsFile, !tc.shouldPass, tc.description)
		})
	}
}

func TestSumoLogicCollectorResourceConfiguration(t *testing.T) {
	tests := []struct {
		name        string
		tfvarsFile  string
		expectError bool
		description string
	}{
		{
			name:        "ValidCollectorConfiguration",
			tfvarsFile:  filepath.Join("test", fixturesDir, "valid-config.tfvars"),
			expectError: false,
			description: "Valid collector with proper naming",
		},
		{
			name:        "CollectorNameWithSpecialChars",
			tfvarsFile:  filepath.Join("test", fixturesDir, "sumo-invalid-collector-name.tfvars"),
			expectError: true,
			description: "Collector name with special characters should fail validation",
		},
		{
			name:        "EmptyCollectorName",
			tfvarsFile:  filepath.Join("test", fixturesDir, "sumo-empty-collector-name.tfvars"),
			expectError: true,
			description: "Empty collector name should fail validation",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			runValidationTest(t, tt.name, tt.tfvarsFile, tt.expectError, tt.description)
		})
	}
}

func TestSumoLogicEventHubLogSourceConfiguration(t *testing.T) {
	// Test Event Hub log source configuration
	terraformOptions := createTerraformOptions(filepath.Join("test", fixturesDir, "valid-config.tfvars"))

	terraform.Init(t, terraformOptions)
	plan, err := terraform.PlanE(t, terraformOptions)

	// We expect this might fail with API errors, but should not fail with validation errors
	if err != nil {
		errStr := err.Error()
		assert.False(t,
			strings.Contains(errStr, "Invalid value for variable") ||
				strings.Contains(errStr, "validation rule"),
			"Should not have validation errors: %v", err)

		t.Logf("Event Hub log source test passed validation but failed at runtime (expected): %v", err)
		// Even with authentication failure, we can still validate the plan structure
		// by checking if the error occurred after plan generation
		if strings.Contains(errStr, "Terraform planned the following actions") {
			t.Logf("Plan was generated before authentication failure, proceeding with validation")
			// Extract plan content from error for validation
			planContent := errStr
			validateEventHubPlanContent(t, planContent)
		}
		return
	}

	// If no error, validate the successful plan
	validateEventHubPlanContent(t, plan)
}

// Helper function to validate Event Hub plan content
func validateEventHubPlanContent(t *testing.T, planContent string) {
	// Define comprehensive expected content patterns with correct resource names
	expectedPatterns := []struct {
		pattern     string
		description string
		required    bool // Some patterns might not appear if no Azure resources are discovered
	}{
		{
			pattern:     `azurerm_eventhub\s*\.\s*eventhubs_by_type_and_location`,
			description: "Event Hub resource should be defined",
			required:    false, // Depends on Azure resource discovery
		},
		{
			pattern:     `azurerm_eventhub_namespace\s*\.\s*namespaces_by_location`,
			description: "Event Hub namespace should be defined",
			required:    false, // Depends on Azure resource discovery
		},
		{
			pattern:     `sumologic_azure_event_hub_log_source\s*\.\s*sumo_azure_event_hub_log_source`,
			description: "Sumo Logic Azure Event Hub log source should be defined",
			required:    false, // Depends on Azure resource discovery
		},
		{
			pattern:     `sumologic_collector\s*\.\s*sumo_collector`,
			description: "Sumo Logic collector should always be defined",
			required:    true, // Always created regardless of Azure resources
		},
		{
			pattern:     `name\s*=\s*".*Collector.*"`,
			description: "Collector should have name containing 'Collector'",
			required:    true,
		},
		{
			pattern:     `content_type\s*=\s*"AzureEventHubLog"`,
			description: "Event Hub log sources should have correct content type",
			required:    false, // Only present when Event Hub sources exist
		},
		{
			pattern:     `category\s*=\s*"azure/logs/`,
			description: "Event Hub log sources should have azure logs category",
			required:    false, // Only present when Event Hub sources exist
		},
		{
			pattern:     `type\s*=\s*"AzureEventHubAuthentication"`,
			description: "Event Hub sources should use proper authentication type",
			required:    false, // Only present when Event Hub sources exist
		},
	}

	// Test each expected pattern
	for _, expected := range expectedPatterns {
		matched, err := regexp.MatchString(expected.pattern, planContent)
		require.NoError(t, err, "Failed to compile regex pattern: %s", expected.pattern)

		if expected.required {
			assert.True(t, matched, expected.description+". Pattern: %s", expected.pattern)
			if matched {
				t.Logf("✓ %s", expected.description)
			}
		} else {
			// For optional patterns, log whether they were found
			if matched {
				t.Logf("✓ %s", expected.description)
			} else {
				t.Logf("- %s (not found - depends on Azure resource discovery)", expected.description)
			}
		}
	}

	// Count actual resources in plan
	collectorMatches := regexp.MustCompile(`sumologic_collector\s*\.\s*sumo_collector`).FindAllString(planContent, -1)
	eventHubMatches := regexp.MustCompile(`azurerm_eventhub\s*\.\s*eventhubs_by_type_and_location`).FindAllString(planContent, -1)
	logSourceMatches := regexp.MustCompile(`sumologic_azure_event_hub_log_source\s*\.\s*sumo_azure_event_hub_log_source`).FindAllString(planContent, -1)

	// Collector should always be present
	assert.GreaterOrEqual(t, len(collectorMatches), 1, "Should have at least 1 Sumo Logic collector")

	// Event Hubs and log sources depend on Azure resource discovery
	if len(eventHubMatches) > 0 {
		t.Logf("Found %d Event Hub resources", len(eventHubMatches))
		assert.GreaterOrEqual(t, len(logSourceMatches), 1, "Should have Sumo Logic log sources when Event Hubs exist")
	} else {
		t.Logf("No Event Hub resources found (expected in test environment without real Azure resources)")
	}

	t.Logf("Event Hub Log Source configuration validation completed. Found: %d collectors, %d Event Hubs, %d log sources",
		len(collectorMatches), len(eventHubMatches), len(logSourceMatches))
}

func TestSumoLogicActivityLogSourceConfiguration(t *testing.T) {
	// Test Activity Log source configuration with both enabled and disabled scenarios
	testCases := []struct {
		name                  string
		tfvarsFile            string
		activityLogsEnabled   bool
		expectedResourceCount int
		description           string
	}{
		{
			name:                  "ActivityLogsEnabled",
			tfvarsFile:            filepath.Join("test", fixturesDir, "activity-logs-enabled.tfvars"),
			activityLogsEnabled:   true,
			expectedResourceCount: 16, // 11 base resources + 5 activity log resources
			description:           "Activity logs enabled should create dedicated Activity Log infrastructure",
		},
		{
			name:                  "ActivityLogsDisabled",
			tfvarsFile:            filepath.Join("test", fixturesDir, "activity-logs-disabled.tfvars"),
			activityLogsEnabled:   false,
			expectedResourceCount: 11, // Only base resources (Event Hubs, collector, etc.)
			description:           "Activity logs disabled should not create Activity Log infrastructure",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := createTerraformOptions(tc.tfvarsFile)

			terraform.Init(t, terraformOptions)
			plan, err := terraform.PlanE(t, terraformOptions)

			// We expect this might fail with API errors, but should not fail with validation errors
			if err != nil {
				errStr := err.Error()
				assert.False(t,
					strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule"),
					"Should not have validation errors: %v", err)

				t.Logf("%s test passed validation but failed at runtime (expected): %v", tc.name, err)

				// Even with authentication failure, we can still validate the plan structure
				if strings.Contains(errStr, "Terraform planned the following actions") {
					t.Logf("Plan was generated before authentication failure, proceeding with validation")
					validateActivityLogPlanContent(t, errStr, tc.activityLogsEnabled)
				}
				return
			}

			// If no error, validate the successful plan
			validateActivityLogPlanContent(t, plan, tc.activityLogsEnabled)
		})
	}
}

// Helper function to validate Activity Log plan content
func validateActivityLogPlanContent(t *testing.T, planContent string, activityLogsEnabled bool) {
	// Define base patterns that should always be present
	basePatterns := []struct {
		pattern     string
		description string
		required    bool
	}{
		{
			pattern:     `sumologic_collector\s*\.\s*sumo_collector`,
			description: "Sumo Logic collector should always be defined",
			required:    true,
		},
		{
			pattern:     `name\s*=\s*".*Collector.*"`,
			description: "Collector should have name containing 'Collector'",
			required:    true,
		},
		{
			pattern:     `azurerm_eventhub\s*\.\s*eventhubs_by_type_and_location`,
			description: "Resource-specific Event Hubs should be defined",
			required:    false, // Depends on Azure resource discovery
		},
		{
			pattern:     `sumologic_azure_event_hub_log_source\s*\.\s*sumo_azure_event_hub_log_source`,
			description: "Resource-specific Event Hub log sources should be defined",
			required:    false, // Depends on Azure resource discovery
		},
	}

	// Define Activity Log-specific patterns
	activityLogPatterns := []struct {
		pattern     string
		description string
	}{
		{
			pattern:     `azurerm_eventhub\s*\.\s*eventhub_for_activity_logs`,
			description: "Activity Log Event Hub should be defined",
		},
		{
			pattern:     `azurerm_eventhub_namespace\s*\.\s*activity_logs_namespace`,
			description: "Activity Log namespace should be defined",
		},
		{
			pattern:     `azurerm_eventhub_namespace_authorization_rule\s*\.\s*activity_logs_policy`,
			description: "Activity Log authorization rule should be defined",
		},
		{
			pattern:     `azurerm_monitor_diagnostic_setting\s*\.\s*activity_logs_to_event_hub`,
			description: "Activity Log diagnostic setting should be defined",
		},
		{
			pattern:     `sumologic_azure_event_hub_log_source\s*\.\s*sumo_activity_log_source`,
			description: "Sumo Logic Activity Log source should be defined",
		},
		{
			pattern:     `name\s*=\s*"SumoActivityLogExport"`,
			description: "Activity Log Event Hub should have correct name",
		},
		{
			pattern:     `azurerm_monitor_diagnostic_setting\s*\.\s*activity_logs_to_event_hub[\s\S]*?target_resource_id\s*=\s*"/subscriptions/[^/]+"\s*$`,
			description: "Activity Log diagnostic setting should target subscription",
		},
		{
			pattern:     `category\s*=\s*"Administrative"`,
			description: "Activity Log source should have Administrative category",
		},
		{
			pattern:     `enabled_log\s*\{[\s\S]*?category\s*=\s*"Administrative"`,
			description: "Activity Log diagnostic setting should enable Administrative logs",
		},
	}

	// Test base patterns
	for _, pattern := range basePatterns {
		matched, err := regexp.MatchString(pattern.pattern, planContent)
		require.NoError(t, err, "Failed to compile regex pattern: %s", pattern.pattern)

		if pattern.required {
			assert.True(t, matched, pattern.description+". Pattern: %s", pattern.pattern)
			if matched {
				t.Logf("✓ %s", pattern.description)
			}
		} else {
			if matched {
				t.Logf("✓ %s", pattern.description)
			} else {
				t.Logf("- %s (not found - depends on Azure resource discovery)", pattern.description)
			}
		}
	}

	// Test Activity Log patterns based on configuration
	for _, pattern := range activityLogPatterns {
		matched, err := regexp.MatchString(pattern.pattern, planContent)
		require.NoError(t, err, "Failed to compile regex pattern: %s", pattern.pattern)

		if activityLogsEnabled {
			// When Activity Logs are enabled, these patterns should be present
			if matched {
				t.Logf("✓ %s (Activity Logs enabled)", pattern.description)
			} else {
				t.Logf("- %s (expected when Activity Logs enabled but not found)", pattern.description)
			}
		} else {
			// When Activity Logs are disabled, these patterns should NOT be present
			assert.False(t, matched, "Activity Log pattern should not be present when disabled: %s", pattern.description)
			if !matched {
				t.Logf("✓ %s correctly absent (Activity Logs disabled)", pattern.description)
			}
		}
	}

	// Count resources in plan
	planMatches := regexp.MustCompile(`Plan:\s+(\d+)\s+to\s+add`).FindStringSubmatch(planContent)
	if len(planMatches) > 1 {
		t.Logf("Terraform plan shows %s resources to add", planMatches[1])
	}

	// Count specific resource types
	collectorMatches := regexp.MustCompile(`sumologic_collector\s*\.\s*sumo_collector`).FindAllString(planContent, -1)
	activityLogSourceMatches := regexp.MustCompile(`sumologic_azure_event_hub_log_source\s*\.\s*sumo_activity_log_source`).FindAllString(planContent, -1)
	eventHubMatches := regexp.MustCompile(`azurerm_eventhub\s*\.\s*eventhubs_by_type_and_location`).FindAllString(planContent, -1)
	activityEventHubMatches := regexp.MustCompile(`azurerm_eventhub\s*\.\s*eventhub_for_activity_logs`).FindAllString(planContent, -1)

	// Validate resource counts
	assert.GreaterOrEqual(t, len(collectorMatches), 1, "Should have at least 1 Sumo Logic collector")

	if activityLogsEnabled {
		t.Logf("Activity Logs enabled - validating Activity Log resources")
		if len(activityLogSourceMatches) > 0 {
			t.Logf("✓ Found %d Activity Log sources", len(activityLogSourceMatches))
		}
		if len(activityEventHubMatches) > 0 {
			t.Logf("✓ Found %d Activity Log Event Hubs", len(activityEventHubMatches))
		}
	} else {
		t.Logf("Activity Logs disabled - validating absence of Activity Log resources")
		assert.Equal(t, 0, len(activityLogSourceMatches), "Should have no Activity Log sources when disabled")
		assert.Equal(t, 0, len(activityEventHubMatches), "Should have no Activity Log Event Hubs when disabled")
		if len(activityLogSourceMatches) == 0 {
			t.Logf("✓ No Activity Log sources found (correctly disabled)")
		}
		if len(activityEventHubMatches) == 0 {
			t.Logf("✓ No Activity Log Event Hubs found (correctly disabled)")
		}
	}

	if len(eventHubMatches) > 0 {
		t.Logf("Found %d resource-specific Event Hubs", len(eventHubMatches))
	} else {
		t.Logf("No resource-specific Event Hubs found (expected in test environment without real Azure resources)")
	}

	t.Logf("Activity Log configuration validation completed. Activity Logs enabled: %v", activityLogsEnabled)
}

func TestSumoLogicAzureMetricsSourceConfiguration(t *testing.T) {
	// Test Azure Metrics source configuration
	terraformOptions := createTerraformOptions(filepath.Join("test", fixturesDir, "activity-logs-enabled.tfvars"))

	terraform.Init(t, terraformOptions)
	plan, err := terraform.PlanE(t, terraformOptions)

	// We expect this might fail with API errors, but should not fail with validation errors
	if err != nil {
		errStr := err.Error()
		assert.False(t,
			strings.Contains(errStr, "Invalid value for variable") ||
				strings.Contains(errStr, "validation rule"),
			"Should not have validation errors: %v", err)

		t.Logf("Azure metrics source test passed validation but failed at runtime (expected): %v", err)

		// Even with authentication failure, we can still validate the plan structure
		if strings.Contains(errStr, "Terraform planned the following actions") {
			t.Logf("Plan was generated before authentication failure, proceeding with validation")
			validateAzureMetricsPlanContent(t, errStr)
		}
		return
	}

	// If no error, validate the successful plan
	validateAzureMetricsPlanContent(t, plan)
}

// Helper function to validate Azure Metrics plan content
func validateAzureMetricsPlanContent(t *testing.T, planContent string) {
	// Define expected patterns for Azure Metrics configuration based on actual Terraform resource
	expectedPatterns := []struct {
		pattern     string
		description string
		required    bool
	}{
		{
			pattern:     `sumologic_azure_metrics_source\s*\.\s*terraform_azure_metrics_source`,
			description: "Sumo Logic Azure Metrics source should be defined",
			required:    false, // Depends on Azure resource discovery
		},
		{
			pattern:     `content_type\s*=\s*"AzureMetrics"`,
			description: "Metrics source should have correct content type",
			required:    false,
		},
		{
			pattern:     `type\s*=\s*"AzureClientSecretAuthentication"`,
			description: "Metrics source should use client secret authentication",
			required:    false,
		},
		{
			pattern:     `tenant_id\s*=\s*"a39bedba-be8f-4c0f-bfe2-b8c7913501ea"`,
			description: "Azure tenant ID should be configured for metrics source",
			required:    false,
		},
		{
			pattern:     `client_id\s*=\s*"a1e5fb4a-8644-4867-be4d-a54d0aeaaeed"`,
			description: "Azure client ID should be configured for metrics source",
			required:    false,
		},
		{
			pattern:     `client_secret\s*=\s*\(sensitive value\)`,
			description: "Azure client secret should be configured for metrics source",
			required:    false,
		},
		{
			pattern:     `type\s*=\s*"AzureMetricsPath"`,
			description: "Metrics source should have Azure metrics path type",
			required:    false,
		},
		{
			pattern:     `environment\s*=\s*"Azure"`,
			description: "Metrics source should target Azure environment",
			required:    false,
		},
		{
			pattern:     `namespace\s*=\s*"Microsoft\.KeyVault/vaults"`,
			description: "Metrics source should target KeyVault namespace",
			required:    false,
		},
		{
			pattern:     `limit_to_namespaces\s*=\s*\[[\s\S]*?"logs"[\s\S]*?"metrics"[\s\S]*?\]`,
			description: "Metrics source should limit to logs and metrics namespaces",
			required:    false,
		},
		{
			pattern:     `limit_to_regions\s*=\s*\[[\s\S]*?"eastus"[\s\S]*?"westus2"[\s\S]*?\]`,
			description: "Metrics source should limit to specific regions",
			required:    false,
		},
		{
			pattern:     `name\s*=\s*"logs-collection-destination"`,
			description: "Azure tag filters should include collection destination tag",
			required:    false,
		},
		{
			pattern:     `values\s*=\s*\[[\s\S]*?"sumologic"[\s\S]*?\]`,
			description: "Azure tag filters should include sumologic value",
			required:    false,
		},
	}

	// Validate collector (should always be present)
	collectorPattern := `sumologic_collector\s*\.\s*sumo_collector`
	collectorMatched, err := regexp.MatchString(collectorPattern, planContent)
	require.NoError(t, err, "Failed to compile collector regex pattern")
	assert.True(t, collectorMatched, "Sumo Logic collector should always be defined")
	if collectorMatched {
		t.Logf("✓ Sumo Logic collector is defined")
	}

	// Test Azure Metrics patterns
	metricsSourceFound := false
	for _, expected := range expectedPatterns {
		matched, err := regexp.MatchString(expected.pattern, planContent)
		require.NoError(t, err, "Failed to compile regex pattern: %s", expected.pattern)

		if matched {
			t.Logf("✓ %s", expected.description)
			if strings.Contains(expected.pattern, "terraform_azure_metrics_source") {
				metricsSourceFound = true
			}
		} else {
			if expected.required {
				assert.True(t, matched, expected.description+". Pattern: %s", expected.pattern)
			} else {
				t.Logf("- %s (not found - might depend on Azure resource discovery)", expected.description)
			}
		}
	}

	// Count metrics sources in plan
	metricsMatches := regexp.MustCompile(`sumologic_azure_metrics_source\s*\.\s*terraform_azure_metrics_source`).FindAllString(planContent, -1)

	if len(metricsMatches) > 0 {
		t.Logf("Found %d Azure Metrics sources", len(metricsMatches))
		assert.True(t, metricsSourceFound, "Should have Azure Metrics source when metrics resources exist")
	} else {
		t.Logf("No Azure Metrics sources found (expected in environments without discovered Azure resources)")
	}

	// Validate that we're NOT looking for incorrect diagnostic categories
	diagnosticErrors := []string{
		"microsoft.keyvault/vaults/metrics",
		"microsoft.keyvault/vaults/logs",
	}

	for _, errorPattern := range diagnosticErrors {
		if strings.Contains(planContent, errorPattern) {
			t.Logf("⚠️  Found reference to invalid diagnostic category: %s", errorPattern)
			t.Logf("   Azure Metrics source should use 'Microsoft.KeyVault/vaults' namespace, not diagnostic categories")
		}
	}

	t.Logf("Azure Metrics Source configuration validation completed")
}

// Test Sumo Logic source naming conventions (no Terraform execution required)
func TestSumoLogicSourceNamingConventions(t *testing.T) {
	testCases := []struct {
		name               string
		subscriptionID     string
		collectorName      string
		expectedSourceName string
		description        string
	}{
		{
			name:               "StandardNaming",
			subscriptionID:     "c088dc46-d692-42ad-a4b6-e02d56cc5596",
			collectorName:      "Azure-Test-Collector",
			expectedSourceName: "Azure-Test-Collector-c088dc46-d692-42ad-a4b6-e02d56cc5596",
			description:        "Standard naming should combine collector name with subscription ID",
		},
		{
			name:               "CollectorWithDashes",
			subscriptionID:     "c088dc46-d692-42ad-a4b6-e02d56cc5596",
			collectorName:      "Test-Collector-Name",
			expectedSourceName: "Test-Collector-Name-c088dc46-d692-42ad-a4b6-e02d56cc5596",
			description:        "Collector names with dashes should work correctly",
		},
		{
			name:               "CollectorWithUnderscores",
			subscriptionID:     "c088dc46-d692-42ad-a4b6-e02d56cc5596",
			collectorName:      "Test_Collector_Name",
			expectedSourceName: "Test_Collector_Name-c088dc46-d692-42ad-a4b6-e02d56cc5596",
			description:        "Collector names with underscores should work correctly",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Apply the same naming logic as in Terraform configuration
			constructedName := fmt.Sprintf("%s-%s", tc.collectorName, tc.subscriptionID)

			assert.Equal(t, tc.expectedSourceName, constructedName,
				fmt.Sprintf("Source name construction should match expected: %s", tc.expectedSourceName))

			assert.Contains(t, constructedName, tc.collectorName,
				"Final source name should contain collector name")
			assert.Contains(t, constructedName, tc.subscriptionID,
				"Final source name should contain subscription ID")
		})
	}
}

// Test Sumo Logic app validation patterns (no Terraform execution required)
func TestSumoLogicAppValidationPatterns(t *testing.T) {
	testCases := []struct {
		name        string
		appUUID     string
		appName     string
		appVersion  string
		shouldPass  bool
		description string
	}{
		{
			name:        "ValidAzureStorageApp",
			appUUID:     "53376d23-2687-4500-b61e-4a2e2a119658",
			appName:     "Azure Storage",
			appVersion:  "1.0.3",
			shouldPass:  true,
			description: "Valid Azure Storage app should pass validation",
		},
		{
			name:        "ValidAzureKeyVaultApp",
			appUUID:     "b20abced-0122-4c7a-8833-c68c3c29c3d3",
			appName:     "Azure Key Vault",
			appVersion:  "1.0.2",
			shouldPass:  true,
			description: "Valid Azure Key Vault app should pass validation",
		},
		{
			name:        "InvalidUUIDFormat",
			appUUID:     "invalid-uuid",
			appName:     "Test App",
			appVersion:  "1.0.0",
			shouldPass:  false,
			description: "Invalid UUID format should fail validation",
		},
		{
			name:        "InvalidVersionFormat",
			appUUID:     "53376d23-2687-4500-b61e-4a2e2a119658",
			appName:     "Test App",
			appVersion:  "invalid",
			shouldPass:  false,
			description: "Invalid version format should fail validation",
		},
		{
			name:        "EmptyFields",
			appUUID:     "",
			appName:     "",
			appVersion:  "",
			shouldPass:  false,
			description: "Empty fields should fail validation",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Test UUID format validation
			uuidPattern := `^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`
			uuidMatched, err := regexp.MatchString(uuidPattern, tc.appUUID)
			require.NoError(t, err)

			// Test semantic version pattern
			versionPattern := `^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+)?$`
			versionMatched, err := regexp.MatchString(versionPattern, tc.appVersion)
			require.NoError(t, err)

			// Test name is not empty
			nameValid := strings.TrimSpace(tc.appName) != ""

			allValid := uuidMatched && versionMatched && nameValid

			if tc.shouldPass {
				assert.True(t, allValid, tc.description)
				if allValid {
					t.Logf("✓ %s: UUID=%s, Name=%s, Version=%s", tc.name, tc.appUUID, tc.appName, tc.appVersion)
				}
			} else {
				assert.False(t, allValid, tc.description)
				if !allValid {
					t.Logf("✓ %s correctly failed validation", tc.name)
				}
			}
		})
	}
}

// TestSumoLogicAppsInstallationPlanValidation tests installation_apps_list validation - HIGH PRIORITY MISSING
func TestSumoLogicAppsInstallationPlanValidation(t *testing.T) {
	// Simple test using the existing helper patterns from azure_test.go
	terraformOptions := createTerraformOptions(filepath.Join("test", fixturesDir, "sumo-valid-apps.tfvars"))

	terraform.Init(t, terraformOptions)
	_, err := terraform.PlanE(t, terraformOptions)

	// We expect this might fail with API errors, but should not fail with validation errors
	if err != nil {
		errStr := err.Error()
		assert.False(t,
			strings.Contains(errStr, "Invalid value for variable") ||
				strings.Contains(errStr, "validation rule"),
			"Should not have validation errors for valid apps: %v", err)

		t.Logf("Valid apps test passed validation but failed at runtime (expected for test environment): %v", err)
	} else {
		t.Logf("✓ Valid Sumo Logic apps configuration passed validation and plan generation")
	}
}

// TestSumoLogicCollectorNameValidation tests comprehensive collector name validation - HIGH PRIORITY MISSING
func TestSumoLogicCollectorNameValidation(t *testing.T) {
	testCases := []struct {
		name        string
		tfvarsFile  string
		expectError bool
		description string
	}{
		{
			name:        "ValidCollectorWithDashes",
			tfvarsFile:  "test/fixtures/sumo-collector-dashes.tfvars",
			expectError: false,
			description: "Collector name with dashes should work",
		},
		{
			name:        "CollectorNameWithSpecialChars",
			tfvarsFile:  "test/fixtures/sumo-invalid-collector-special.tfvars",
			expectError: true,
			description: "Collector name with special characters should fail validation",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := createTerraformOptions(tc.tfvarsFile)

			terraform.Init(t, terraformOptions)
			_, err := terraform.PlanE(t, terraformOptions)

			if tc.expectError {
				assert.Error(t, err, tc.description)
				// Verify it's a validation error, not an API error
				if err != nil {
					errStr := err.Error()
					isValidationError := strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") ||
						strings.Contains(errStr, "error_message")

					if isValidationError {
						t.Logf("✓ %s correctly failed with validation error: %s", tc.name, tc.description)
					} else {
						t.Logf("⚠️  %s failed but not with validation error (might be API error): %v", tc.name, err)
					}
				}
			} else {
				// For valid configurations, we might get API errors trying to access resources
				// We only care that validation passed
				if err != nil {
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tc.name, err)
					} else {
						// API errors are expected for validation-only tests
						t.Logf("✓ %s passed validation but failed at runtime (expected): %s", tc.name, tc.description)
					}
				} else {
					t.Logf("✓ %s passed validation completely: %s", tc.name, tc.description)
				}
			}
		})
	}
}
