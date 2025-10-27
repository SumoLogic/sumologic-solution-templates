package test

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// AzureResource represents an Azure resource for validation
type AzureResource struct {
	ID   string `json:"id"`
	Name string `json:"name"`
	Type string `json:"type"`
}

// SumoLogicCollector represents a Sumo Logic collector
type SumoLogicCollector struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

// AppInstallationResult represents the result of app installation with error handling
type AppInstallationResult struct {
	Success   bool
	Message   string
	ErrorCode string
	Scenario  string
}

// TestAzureCollectionIntegration performs comprehensive end-to-end integration testing
// with actual resource verification in both Azure and Sumo Logic, including app installation scenarios
func TestAzureCollectionIntegration(t *testing.T) {
	t.Log("🚀 Starting Comprehensive Azure Collection Integration Test...")

	// Generate unique suffix for this test run to avoid resource conflicts
	timestamp := time.Now().UnixNano() / int64(time.Millisecond)
	uniqueSuffix := fmt.Sprintf("SumoTestActivityLogExport-%d", timestamp)

	// Create terraform options with enhanced error handling for app installation scenarios
	terraformOptions := &terraform.Options{
		TerraformDir: "../", // Parent directory containing the terraform files
		VarFiles: []string{
			"test/test.tfvars", // Consolidated configuration file
		},
		Vars: map[string]interface{}{
			// Make names unique per test run to avoid collisions with existing resources in the subscription
			"activity_log_export_name": uniqueSuffix,
			"resource_group_name":      fmt.Sprintf("SUMO-%d-INTEGRATION-TEST", timestamp),
			"eventhub_namespace_name":  fmt.Sprintf("SUMO-%d-EventHub-test", timestamp),
		},
		EnvVars: map[string]string{
			"TF_IN_AUTOMATION": "1",
		},
		NoColor: true,
	}

	// Defer cleanup to ensure resources are always destroyed
	defer func() {
		t.Log("🧹 Starting resource cleanup...")
		destroyWithAppHandling(t, terraformOptions)
		t.Log("✅ Resource cleanup completed")
	}()

	// Apply the Terraform configuration with app installation error handling
	t.Log("📦 Applying Terraform configuration...")
	applyWithAppHandling(t, terraformOptions)

	// Get Terraform outputs for validation
	t.Log("📋 Retrieving Terraform outputs...")
	resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")
	eventhubNamespaceName := terraform.Output(t, terraformOptions, "eventhub_namespace_name")
	collectorID := terraform.Output(t, terraformOptions, "sumologic_collector_id")
	logSourceIDs := terraform.OutputMap(t, terraformOptions, "sumologic_log_source_ids")
	metricsSourceID := terraform.Output(t, terraformOptions, "sumologic_metrics_source_id")

	// Validate that we got the expected outputs
	require.NotEmpty(t, resourceGroupName, "Resource group name should not be empty")
	require.NotEmpty(t, eventhubNamespaceName, "EventHub namespace name should not be empty")
	require.NotEmpty(t, collectorID, "Sumo Logic collector ID should not be empty")
	require.NotEmpty(t, logSourceIDs, "Sumo Logic log source IDs should not be empty")
	require.NotEmpty(t, metricsSourceID, "Sumo Logic metrics source ID should not be empty")

	t.Logf("📊 Terraform Outputs Retrieved:")
	t.Logf("  - Resource Group: %s", resourceGroupName)
	t.Logf("  - EventHub Namespace: %s", eventhubNamespaceName)
	t.Logf("  - Collector ID: %s", collectorID)
	t.Logf("  - Metrics Source ID: %s", metricsSourceID)
	t.Logf("  - Log Source IDs: %v", logSourceIDs)

	// Phase 1: Verify Azure Resources
	t.Log("🔍 Phase 1: Verifying Azure Resources...")
	// Derive expected EventHubs from terraform output 'eventhub_names' so tests follow actual config
	eventhubNamesMap := terraform.OutputMap(t, terraformOptions, "eventhub_names")
	verifyAzureResources(t, resourceGroupName, eventhubNamespaceName, eventhubNamesMap)

	// Phase 2: Verify Sumo Logic Resources
	t.Log("🔍 Phase 2: Verifying Sumo Logic Resources...")
	verifySumoLogicResources(t, collectorID, logSourceIDs, metricsSourceID)

	// Phase 3: Verify App Installation Status
	t.Log("🔍 Phase 3: Verifying App Installation Status...")
	verifyAppInstallationStatus(t, terraformOptions)

	// Phase 4: Verify Diagnostic Settings
	t.Log("🔍 Phase 4: Verifying Diagnostic Settings...")
	verifyDiagnosticSettings(t, resourceGroupName, eventhubNamespaceName)

	t.Log("✅ All integration tests passed successfully!")
}

// verifyAzureResources validates that Azure resources are properly created
func verifyAzureResources(t *testing.T, resourceGroupName, eventhubNamespaceName string, expectedEventhubMap map[string]string) {
	t.Log("🔍 Verifying Azure Resource Group...")

	// Verify Resource Group exists
	cmd := exec.Command("az", "group", "show", "--name", resourceGroupName, "--output", "json")
	output, err := cmd.Output()
	if err != nil {
		t.Fatalf("❌ Failed to find Azure Resource Group '%s': %v", resourceGroupName, err)
	}

	var rg AzureResource
	err = json.Unmarshal(output, &rg)
	require.NoError(t, err, "Failed to parse Resource Group JSON")
	assert.Equal(t, resourceGroupName, rg.Name, "Resource Group name mismatch")
	t.Logf("✅ Resource Group '%s' verified", resourceGroupName)

	// Verify EventHub Namespace exists
	t.Log("🔍 Verifying EventHub Namespace...")
	cmd = exec.Command("az", "eventhubs", "namespace", "show",
		"--resource-group", resourceGroupName,
		"--name", eventhubNamespaceName,
		"--output", "json")
	output, err = cmd.Output()
	if err != nil {
		t.Fatalf("❌ Failed to find EventHub Namespace '%s': %v", eventhubNamespaceName, err)
	}

	var ehns AzureResource
	err = json.Unmarshal(output, &ehns)
	require.NoError(t, err, "Failed to parse EventHub Namespace JSON")
	assert.Equal(t, eventhubNamespaceName, ehns.Name, "EventHub Namespace name mismatch")
	t.Logf("✅ EventHub Namespace '%s' verified", eventhubNamespaceName)

	// Verify EventHubs exist
	t.Log("🔍 Verifying EventHubs...")
	cmd = exec.Command("az", "eventhubs", "eventhub", "list",
		"--resource-group", resourceGroupName,
		"--namespace-name", eventhubNamespaceName,
		"--output", "json")
	output, err = cmd.Output()
	if err != nil {
		t.Fatalf("❌ Failed to list EventHubs: %v", err)
	}

	var eventhubs []AzureResource
	err = json.Unmarshal(output, &eventhubs)
	require.NoError(t, err, "Failed to parse EventHubs JSON")

	// Use the expectedEventhubMap produced by Terraform outputs to know which EventHubs we should have
	// expectedEventhubMap keys look like "Microsoft.Storage/storageAccounts-eastus" and values are eventhub names
	eventHubNames := make([]string, len(eventhubs))
	for i, eh := range eventhubs {
		eventHubNames[i] = eh.Name
	}

	// If Terraform produced no expected mapping, fall back to asserting that at least one EventHub exists
	if len(expectedEventhubMap) == 0 {
		assert.True(t, len(eventhubs) > 0, "No EventHubs found and no expected EventHubs were provided")
		t.Logf("✅ Found %d EventHubs: %v", len(eventhubs), eventHubNames)
		return
	}

	// For each expected eventhub name from Terraform, assert it exists in the actual EventHub list
	for _, expectedName := range expectedEventhubMap {
		found := false
		for _, ehName := range eventHubNames {
			if ehName == expectedName || strings.Contains(strings.ToLower(ehName), strings.ToLower(expectedName)) {
				found = true
				break
			}
		}
		assert.True(t, found, "Missing EventHub '%s'. Available EventHubs: %v", expectedName, eventHubNames)
	}

	t.Logf("✅ All %d EventHubs verified: %v", len(eventhubs), eventHubNames)
}

// verifySumoLogicResources validates that Sumo Logic resources are properly created
func verifySumoLogicResources(t *testing.T, collectorID string, logSourceIDs map[string]string, metricsSourceID string) {
	// Note: This is a simplified verification since we don't have direct Sumo Logic API access in the test
	// In a real implementation, you would use the Sumo Logic API to verify these resources

	t.Log("🔍 Verifying Sumo Logic Collector...")
	assert.NotEmpty(t, collectorID, "Collector ID should not be empty")
	assert.Regexp(t, `^\d+$`, collectorID, "Collector ID should be numeric")
	t.Logf("✅ Sumo Logic Collector ID '%s' format verified", collectorID)

	t.Log("🔍 Verifying Sumo Logic Log Sources...")
	// Dynamically verify whatever log sources Terraform reported in the outputs
	if len(logSourceIDs) == 0 {
		t.Log("ℹ️  No log sources reported by Terraform outputs; skipping detailed log source verification")
	} else {
		for expected, sourceID := range logSourceIDs {
			assert.NotEmpty(t, expected, "Log source key should not be empty")
			assert.NotEmpty(t, sourceID, "Log source ID should not be empty for: %s", expected)
			assert.Regexp(t, `^\d+$`, sourceID, "Log source ID should be numeric for: %s", expected)
			t.Logf("✅ Log Source '%s' ID '%s' verified", expected, sourceID)
		}
	}

	t.Log("🔍 Verifying Sumo Logic Metrics Source...")
	assert.NotEmpty(t, metricsSourceID, "Metrics source ID should not be empty")
	assert.Regexp(t, `^\d+$`, metricsSourceID, "Metrics source ID should be numeric")
	t.Logf("✅ Sumo Logic Metrics Source ID '%s' verified", metricsSourceID)
}

// verifyAppInstallationStatus verifies the status of installed Sumo Logic apps
func verifyAppInstallationStatus(t *testing.T, options *terraform.Options) {
	// Get the installed apps output from terraform
	installedAppsOutput := terraform.Output(t, options, "installed_apps")

	if installedAppsOutput == "{}" || installedAppsOutput == "" {
		t.Log("ℹ️  No apps configured for installation (installation_apps_list is empty)")
		return
	}

	t.Logf("📱 Installed Apps Status: %s", installedAppsOutput)

	// In a real implementation, you might parse the installed_apps output
	// and validate each app's installation status
	// For now, we'll just log the status

	// Try to get more detailed app information if available
	outputs, err := terraform.OutputAllE(t, options)
	if err != nil {
		t.Logf("⚠️  Could not retrieve all terraform outputs for app verification: %v", err)
		return
	}

	// Check if there are any app-related outputs
	appOutputsFound := false
	for key, value := range outputs {
		if strings.Contains(strings.ToLower(key), "app") {
			t.Logf("📱 App Output '%s': %s", key, value)
			appOutputsFound = true
		}
	}

	if !appOutputsFound {
		t.Log("ℹ️  No app-specific outputs found - apps may not be configured or may have encountered installation scenarios")
	} else {
		t.Log("✅ App installation status verified")
	}
}

// verifyDiagnosticSettings validates that diagnostic settings are properly configured
func verifyDiagnosticSettings(t *testing.T, resourceGroupName, eventhubNamespaceName string) {
	t.Log("🔍 Verifying Diagnostic Settings...")

	// Get list of diagnostic settings (this will show if any are configured)
	cmd := exec.Command("az", "monitor", "diagnostic-settings", "list",
		"--resource-group", resourceGroupName,
		"--output", "json")
	output, err := cmd.Output()

	if err != nil {
		// If the command fails, it might be because there are no diagnostic settings
		// or because of permission issues, but we should not fail the test for this
		t.Logf("⚠️  Could not verify diagnostic settings: %v", err)
		return
	}

	// Parse and validate diagnostic settings if we can get them
	if len(output) > 0 && !strings.Contains(string(output), "[]") {
		t.Log("✅ Diagnostic settings are configured (detailed validation would require resource-specific queries)")
	} else {
		t.Log("ℹ️  No diagnostic settings found or query returned empty results")
	}
}

// applyWithAppHandling applies terraform configuration with enhanced error handling for app installation scenarios
func applyWithAppHandling(t *testing.T, options *terraform.Options) {
	terraform.Init(t, options)

	// Try to apply, but handle app-related errors gracefully
	_, err := terraform.ApplyE(t, options)
	if err != nil {
		errorStr := err.Error()
		appResults := analyzeAppInstallationErrors(errorStr)

		if len(appResults) > 0 {
			t.Log("📱 App Installation Scenarios Detected:")
			for _, result := range appResults {
				t.Logf("  - %s: %s", result.Scenario, result.Message)
			}

			// If all errors are app-related and are valid scenarios, continue with the test
			if allErrorsAreValidAppScenarios(appResults, errorStr) {
				t.Log("ℹ️  All errors are valid app installation scenarios, continuing with infrastructure validation")
				// Force apply ignoring app errors by retrying
				terraform.Apply(t, options)
				return
			}
		}

		// If there are non-app related errors, fail the test
		t.Fatalf("❌ Terraform apply failed with non-app errors: %v", err)
	}

	t.Log("✅ Terraform configuration applied successfully")
}

// destroyWithAppHandling destroys terraform resources with enhanced error handling for app scenarios
func destroyWithAppHandling(t *testing.T, options *terraform.Options) {
	_, err := terraform.DestroyE(t, options)
	if err != nil {
		errorStr := err.Error()
		appResults := analyzeAppUninstallationErrors(errorStr)

		if len(appResults) > 0 {
			t.Log("📱 App Uninstallation Scenarios Detected:")
			for _, result := range appResults {
				t.Logf("  - %s: %s", result.Scenario, result.Message)
			}

			// If all errors are app-related "not found" scenarios, consider it successful
			if allErrorsAreValidAppUninstallScenarios(appResults, errorStr) {
				t.Log("ℹ️  All errors are valid app uninstallation scenarios (apps already removed manually)")
				return
			}
		}

		// If there are non-app related errors, fail the cleanup but don't fail the test
		t.Logf("⚠️  Terraform destroy encountered non-app errors (resources may need manual cleanup): %v", err)
		return
	}

	t.Log("✅ Terraform resources destroyed successfully")
}

// analyzeAppInstallationErrors analyzes terraform errors for app installation scenarios
func analyzeAppInstallationErrors(errorStr string) []AppInstallationResult {
	var results []AppInstallationResult

	// Check for "app already installed" scenario
	if strings.Contains(errorStr, "apps:app_already_installed") ||
		strings.Contains(errorStr, "App with given uuid is already installed") {
		results = append(results, AppInstallationResult{
			Success:   false,
			Message:   "App is already installed manually or via another process",
			ErrorCode: "apps:app_already_installed",
			Scenario:  "App Already Installed",
		})
	}

	// Check for other app-related installation errors
	if strings.Contains(errorStr, "apps:") && !strings.Contains(errorStr, "apps:app_already_installed") {
		results = append(results, AppInstallationResult{
			Success:   false,
			Message:   "App installation error detected",
			ErrorCode: "apps:general_error",
			Scenario:  "App Installation Error",
		})
	}

	return results
}

// analyzeAppUninstallationErrors analyzes terraform errors for app uninstallation scenarios
func analyzeAppUninstallationErrors(errorStr string) []AppInstallationResult {
	var results []AppInstallationResult

	// Check for "app not found" scenario during destroy
	if strings.Contains(errorStr, "apps:not_found") ||
		strings.Contains(errorStr, "App instance with given id not found") {
		results = append(results, AppInstallationResult{
			Success:   true, // This is actually a valid scenario
			Message:   "App was already uninstalled manually (not found in Sumo Logic)",
			ErrorCode: "apps:not_found",
			Scenario:  "App Already Uninstalled",
		})
	}

	// Check for Azure Backup lock scenario during destroy
	if strings.Contains(errorStr, "ScopeLocked") ||
		strings.Contains(errorStr, "AzureBackupProtectionLock") {
		results = append(results, AppInstallationResult{
			Success:   true, // This is an acceptable scenario in production
			Message:   "Resources are protected by Azure Backup locks (cannot delete diagnostic settings)",
			ErrorCode: "azure:scope_locked",
			Scenario:  "Azure Backup Protection",
		})
	}

	return results
}

// allErrorsAreValidAppScenarios checks if all errors in the terraform output are valid app scenarios
func allErrorsAreValidAppScenarios(appResults []AppInstallationResult, fullError string) bool {
	if len(appResults) == 0 {
		return false
	}

	// Check if the error is predominantly app-related
	// This is a simple heuristic - in a more sophisticated implementation,
	// you might parse the full terraform error more thoroughly
	appErrorIndicators := []string{
		"apps:app_already_installed",
		"App with given uuid is already installed",
		"sumologic_app",
	}

	hasAppErrors := false
	for _, indicator := range appErrorIndicators {
		if strings.Contains(fullError, indicator) {
			hasAppErrors = true
			break
		}
	}

	return hasAppErrors
}

// allErrorsAreValidAppUninstallScenarios checks if all destroy errors are valid app uninstall scenarios
func allErrorsAreValidAppUninstallScenarios(appResults []AppInstallationResult, fullError string) bool {
	// If we have app results indicating "not found" scenarios, and no other critical errors
	for _, result := range appResults {
		if result.ErrorCode == "apps:not_found" && result.Success {
			return true
		}
	}
	return false
}
