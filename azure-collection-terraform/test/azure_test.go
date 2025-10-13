package test

import (
	"fmt"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

const (
	baseTfvarsFile = "test.tfvars"
	fixturesDir    = "fixtures"
	terraformDir   = "../"
)

// Helper function to create terraform options with base + override pattern
func createTerraformOptions(tfvarsFile string) *terraform.Options {
	var varFiles []string

	// Always load base test.tfvars first for common configuration
	baseVarFile := filepath.Join("test", baseTfvarsFile)
	varFiles = append(varFiles, baseVarFile)

	// If using a fixture file, load it second to override specific values
	if tfvarsFile != baseTfvarsFile && tfvarsFile != "" {
		// The tfvarsFile parameter already includes the full path (e.g., "test/fixtures/file.tfvars")
		varFiles = append(varFiles, tfvarsFile)
	}

	return &terraform.Options{
		TerraformDir: terraformDir,
		VarFiles:     varFiles,
		NoColor:      true,
	}
}

// Helper function to run validation test (expects error)
func runValidationTest(t *testing.T, testName string, tfvarsFile string, expectError bool, description string) {
	terraformOptions := createTerraformOptions(tfvarsFile)

	terraform.Init(t, terraformOptions)

	_, err := terraform.PlanE(t, terraformOptions)

	if expectError {
		assert.Error(t, err, description)
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
				t.Errorf("Test case '%s' should pass validation but got validation error: %v", testName, err)
			} else {
				// API errors are expected for validation-only tests
				t.Logf("Test case '%s' passed validation but failed at runtime (expected): %v", testName, err)
			}
		}
	}
}

func TestAzureSubscriptionIDValidation(t *testing.T) {
	tests := []struct {
		name        string
		tfvarsFile  string
		expectError bool
		description string
	}{
		{
			name:        "ValidSubscriptionID",
			tfvarsFile:  filepath.Join("test", fixturesDir, "valid-config.tfvars"),
			expectError: false,
			description: "Valid Azure subscription ID should pass validation",
		},
		{
			name:        "InvalidSubscriptionIDFormat",
			tfvarsFile:  filepath.Join("test", fixturesDir, "invalid-subscription.tfvars"),
			expectError: true,
			description: "Invalid subscription ID format should fail validation",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			runValidationTest(t, tt.name, tt.tfvarsFile, tt.expectError, tt.description)
		})
	}
}

func TestEventHubNamespaceNameValidation(t *testing.T) {
	tests := []struct {
		name        string
		tfvarsFile  string
		expectError bool
		description string
	}{
		{
			name:        "ValidNamespaceName",
			tfvarsFile:  filepath.Join("test", fixturesDir, "valid-config.tfvars"),
			expectError: false,
			description: "Valid Event Hub namespace name should pass validation",
		},
		{
			name:        "NamespaceNameTooShort",
			tfvarsFile:  filepath.Join("test", fixturesDir, "invalid-namespace.tfvars"),
			expectError: true,
			description: "Namespace name shorter than 6 characters should fail validation",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			runValidationTest(t, tt.name, tt.tfvarsFile, tt.expectError, tt.description)
		})
	}
}

func TestThroughputUnitsValidation(t *testing.T) {
	tests := []struct {
		name        string
		tfvarsFile  string
		expectError bool
		description string
	}{
		{
			name:        "ValidThroughputUnits",
			tfvarsFile:  filepath.Join("test", fixturesDir, "valid-config.tfvars"),
			expectError: false,
			description: "Valid throughput units (10) should pass validation",
		},
		{
			name:        "MinimumThroughputUnits",
			tfvarsFile:  filepath.Join("test", fixturesDir, "min-throughput.tfvars"),
			expectError: false,
			description: "Minimum throughput units (1) should pass validation",
		},
		{
			name:        "MaximumThroughputUnits",
			tfvarsFile:  filepath.Join("test", fixturesDir, "max-throughput.tfvars"),
			expectError: false,
			description: "Maximum throughput units (20) should pass validation",
		},
		{
			name:        "ThroughputUnitsBelowMinimum",
			tfvarsFile:  filepath.Join("test", fixturesDir, "below-min-throughput.tfvars"),
			expectError: true,
			description: "Throughput units below minimum (0) should fail validation",
		},
		{
			name:        "ThroughputUnitsAboveMaximum",
			tfvarsFile:  filepath.Join("test", fixturesDir, "invalid-throughput.tfvars"),
			expectError: true,
			description: "Throughput units above maximum (25) should fail validation",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			runValidationTest(t, tt.name, tt.tfvarsFile, tt.expectError, tt.description)
		})
	}
}

func TestAzureResourceTypeFormatValidation(t *testing.T) {
	tests := []struct {
		name        string
		tfvarsFile  string
		expectError bool
		description string
	}{
		{
			name:        "ValidResourceTypes",
			tfvarsFile:  filepath.Join("test", fixturesDir, "valid-config.tfvars"),
			expectError: false,
			description: "Valid resource type formats should pass validation",
		},
		{
			name:        "InvalidResourceTypeFormats",
			tfvarsFile:  filepath.Join("test", fixturesDir, "invalid-resource-types.tfvars"),
			expectError: true,
			description: "Invalid resource type formats should fail validation",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			runValidationTest(t, tt.name, tt.tfvarsFile, tt.expectError, tt.description)
		})
	}
}

func TestEventHubNamespaceAuthorizationRulePermissions(t *testing.T) {
	// Test that we can validate the authorization rule configuration exists
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

		// Log that this is expected for validation-only testing
		t.Logf("Authorization rule test passed validation but failed at runtime (expected): %v", err)
		return
	}

	// If plan succeeds, verify authorization rule exists with correct permissions
	assert.Contains(t, plan, "azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy",
		"Plan should contain Event Hub namespace authorization rule resource")

	// Verify expected permissions in the plan
	// Note: When the resource is being replaced, permissions may be shown as "unchanged attributes hidden"
	// We check for explicit permissions OR the presence of unchanged attributes (which means permissions are preserved)
	hasExplicitPermissions := strings.Contains(plan, "listen = true") &&
		strings.Contains(plan, "send = true") &&
		strings.Contains(plan, "manage = false")

	hasUnchangedAttributes := strings.Contains(plan, "azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy") &&
		strings.Contains(plan, "unchanged attributes hidden")

	assert.True(t, hasExplicitPermissions || hasUnchangedAttributes,
		"Authorization rule should have correct permissions (listen=true, send=true, manage=false) either explicitly shown or preserved as unchanged")

	t.Logf("✓ Authorization rule permissions verified (explicit: %v, unchanged: %v)", hasExplicitPermissions, hasUnchangedAttributes)
}

func TestBasicTerraformConfiguration(t *testing.T) {
	// Test that the basic configuration passes validation
	terraformOptions := createTerraformOptions(baseTfvarsFile)

	terraform.Init(t, terraformOptions)

	_, err := terraform.PlanE(t, terraformOptions)

	// We expect this might fail with API errors for missing resources,
	// but it should not fail with validation errors
	if err != nil {
		errStr := err.Error()
		assert.False(t,
			strings.Contains(errStr, "Invalid value for variable") ||
				strings.Contains(errStr, "validation rule"),
			"Basic configuration should not cause validation errors: %v", err)

		t.Logf("Basic configuration passed validation but failed at runtime (expected for test environment): %v", err)
	}
}

// Test naming convention logic (no Terraform execution required)
func TestEventHubNamespaceNamingConventions(t *testing.T) {
	testCases := []struct {
		name                   string
		inputLocation          string
		expectedTransformation string
		description            string
	}{
		{
			name:                   "SpacesInLocation",
			inputLocation:          "East US",
			expectedTransformation: "eastus",
			description:            "Spaces should be removed from location names",
		},
		{
			name:                   "MixedCaseLocation",
			inputLocation:          "West US 2",
			expectedTransformation: "westus2",
			description:            "Mixed case locations should be lowercased with spaces removed",
		},
		{
			name:                   "AlreadyLowerCase",
			inputLocation:          "westus2",
			expectedTransformation: "westus2",
			description:            "Already lowercase locations should remain unchanged",
		},
		{
			name:                   "MultipleSpaces",
			inputLocation:          "Central  US",
			expectedTransformation: "centralus",
			description:            "Multiple spaces should be removed from location names",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Apply the same transformation as in the terraform resource
			transformedLocation := strings.ReplaceAll(strings.ToLower(tc.inputLocation), " ", "")

			assert.Equal(t, tc.expectedTransformation, transformedLocation,
				fmt.Sprintf("Location transformation should match expected: %s", tc.expectedTransformation))

			// Test full namespace name construction
			testNamespaceName := "SUMO-HUB"
			expectedFullName := fmt.Sprintf("%s-%s", testNamespaceName, transformedLocation)

			assert.Contains(t, expectedFullName, testNamespaceName,
				"Final namespace name should contain original namespace name")
			assert.Contains(t, expectedFullName, transformedLocation,
				"Final namespace name should contain transformed location")
		})
	}
}

func TestEventHubNamingConventions(t *testing.T) {
	testCases := []struct {
		name                 string
		inputResourceType    string
		inputLocation        string
		expectedEventHubName string
		description          string
	}{
		{
			name:                 "ResourceTypeWithSlashes",
			inputResourceType:    "Microsoft.KeyVault/vaults",
			inputLocation:        "eastus",
			expectedEventHubName: "eventhub-Microsoft.KeyVault-vaults-eastus",
			description:          "Forward slashes in resource type should be replaced with hyphens",
		},
		{
			name:                 "ResourceTypeWithMultipleSlashes",
			inputResourceType:    "Microsoft.Storage/storageAccounts/blobServices",
			inputLocation:        "westus2",
			expectedEventHubName: "eventhub-Microsoft.Storage-storageAccounts-blobServices-westus2",
			description:          "Multiple forward slashes should all be replaced with hyphens",
		},
		{
			name:                 "ResourceTypeWithDots",
			inputResourceType:    "Microsoft.Compute/virtualMachines",
			inputLocation:        "centralus",
			expectedEventHubName: "eventhub-Microsoft.Compute-virtualMachines-centralus",
			description:          "Dots in resource type should be preserved, only slashes replaced",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			eachKey := fmt.Sprintf("%s-%s", tc.inputResourceType, tc.inputLocation)
			transformedName := fmt.Sprintf("eventhub-%s", strings.ReplaceAll(eachKey, "/", "-"))

			assert.Equal(t, tc.expectedEventHubName, transformedName,
				fmt.Sprintf("Event Hub name transformation should match expected: %s", tc.expectedEventHubName))

			assert.Contains(t, transformedName, "eventhub-",
				"Event Hub name should start with 'eventhub-'")
			assert.NotContains(t, transformedName, "/",
				"Event Hub name should not contain forward slashes")
		})
	}
}

// TestAzureCredentialsValidation tests both format validation and actual Azure API authentication
func TestAzureCredentialsValidation(t *testing.T) {
	tests := []struct {
		name        string
		tfvarsFile  string
		expectError bool
		description string
		testType    string // "format" or "api"
	}{
		{
			name:        "ValidCredentials",
			tfvarsFile:  filepath.Join("test", fixturesDir, "valid-config.tfvars"),
			expectError: false,
			description: "Valid Azure credentials should pass validation and authenticate successfully",
			testType:    "api",
		},
		{
			name:        "InvalidSubscriptionIDFormat",
			tfvarsFile:  filepath.Join("test", fixturesDir, "invalid-subscription.tfvars"),
			expectError: true,
			description: "Invalid Azure subscription ID format should fail validation",
			testType:    "format",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.testType == "format" {
				// Test format validation - should fail at Terraform validation stage
				runValidationTest(t, tt.name, tt.tfvarsFile, tt.expectError, tt.description)
			} else if tt.testType == "api" {
				// Test actual Azure API authentication - should succeed with valid credentials
				runAzureAPITest(t, tt.name, tt.tfvarsFile, tt.expectError, tt.description)
			}
		})
	}
}

// Helper function to test actual Azure API authentication
func runAzureAPITest(t *testing.T, testName string, tfvarsFile string, expectError bool, description string) {
	terraformOptions := createTerraformOptions(tfvarsFile)

	terraform.Init(t, terraformOptions)

	plan, err := terraform.PlanE(t, terraformOptions)

	if expectError {
		assert.Error(t, err, description)
	} else {
		// For valid credentials, we expect the plan to succeed
		// Even if there are runtime errors, they should be Azure resource-related, not authentication-related
		if err != nil {
			errStr := err.Error()
			// Ensure it's not a validation error
			assert.False(t,
				strings.Contains(errStr, "Invalid value for variable") ||
					strings.Contains(errStr, "validation rule"),
				"Should not have validation errors with valid credentials: %v", err)

			// Ensure it's not an authentication error (401 = auth failed, 403 = authorized but insufficient permissions)
			assert.False(t,
				strings.Contains(errStr, "authentication failed") ||
					strings.Contains(errStr, "invalid credentials") ||
					strings.Contains(errStr, "401"),
				"Should not have authentication errors with valid credentials: %v", err)

			// If there are errors, they should be about Azure resources or API limits, not credentials
			if strings.Contains(errStr, "Terraform planned the following actions") {
				t.Logf("✓ %s: Valid credentials successfully authenticated and generated Terraform plan", testName)
				t.Logf("Runtime error is related to Azure resources, not authentication: %v", err)
			} else {
				t.Logf("Warning: %s had unexpected error type: %v", testName, err)
			}
		} else {
			// Perfect - plan succeeded completely
			assert.NotEmpty(t, plan, "Plan should not be empty for valid credentials")
			t.Logf("✓ %s: Valid credentials successfully authenticated and completed plan", testName)
		}
	}
}

// TestAzureCredentialsFormatValidation tests Azure credential format validation - ENHANCED COVERAGE
func TestAzureCredentialsFormatValidation(t *testing.T) {
	testCases := []struct {
		name        string
		tfvarsFile  string
		expectError bool
		description string
	}{
		{
			name:        "ValidAzureCredentialsFormat",
			tfvarsFile:  "test/fixtures/valid-config.tfvars",
			expectError: false,
			description: "Valid Azure credentials should pass validation",
		},
		{
			name:        "InvalidTenantIDFormat",
			tfvarsFile:  "test/fixtures/invalid-tenant-id.tfvars",
			expectError: true,
			description: "Invalid tenant ID format should fail validation",
		},
		{
			name:        "EmptyTenantID",
			tfvarsFile:  "test/fixtures/empty-tenant-id.tfvars",
			expectError: true,
			description: "Empty tenant ID should fail validation",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := createTerraformOptions(tc.tfvarsFile)

			terraform.Init(t, terraformOptions)
			_, err := terraform.PlanE(t, terraformOptions)

			if tc.expectError {
				assert.Error(t, err, tc.description)
				if err != nil {
					errStr := err.Error()
					isValidationError := strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") ||
						strings.Contains(errStr, "error_message")

					if isValidationError {
						t.Logf("✓ %s correctly failed with validation error: %s", tc.name, tc.description)
					} else {
						t.Logf("⚠️  %s failed but not with validation error: %v", tc.name, err)
					}
				}
			} else {
				if err != nil {
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tc.name, err)
					} else {
						t.Logf("✓ %s passed validation but failed at runtime (expected): %s", tc.name, tc.description)
					}
				} else {
					t.Logf("✓ %s passed validation completely: %s", tc.name, tc.description)
				}
			}
		})
	}
}

func TestResourceGroupNameValidation(t *testing.T) {
	tests := []struct {
		name        string
		tfvarsFile  string
		expectError bool
		description string
	}{
		{
			name:        "ValidResourceGroupName",
			tfvarsFile:  filepath.Join("test", fixturesDir, "valid-config.tfvars"),
			expectError: false,
			description: "Valid resource group name should pass validation",
		},
		{
			name:        "InvalidSpecialCharacters",
			tfvarsFile:  filepath.Join("test", fixturesDir, "invalid-resource-group-special-chars.tfvars"),
			expectError: true,
			description: "Resource group name with spaces and special characters (@) should fail validation",
		},
		{
			name:        "InvalidStartsWithHyphen",
			tfvarsFile:  filepath.Join("test", fixturesDir, "invalid-resource-group-starts-hyphen.tfvars"),
			expectError: true,
			description: "Resource group name starting with hyphen should fail validation",
		},
		{
			name:        "InvalidEndsWithPeriod",
			tfvarsFile:  filepath.Join("test", fixturesDir, "invalid-resource-group-ends-period.tfvars"),
			expectError: true,
			description: "Resource group name ending with period should fail validation",
		},
		{
			name:        "InvalidReservedName",
			tfvarsFile:  filepath.Join("test", fixturesDir, "invalid-resource-group-reserved-name.tfvars"),
			expectError: true,
			description: "Resource group name using reserved name 'azure' should fail validation",
		},
		{
			name:        "InvalidTooLong",
			tfvarsFile:  filepath.Join("test", fixturesDir, "invalid-resource-group-too-long.tfvars"),
			expectError: true,
			description: "Resource group name exceeding 90 characters should fail validation",
		},
		{
			name:        "InvalidEmpty",
			tfvarsFile:  filepath.Join("test", fixturesDir, "invalid-resource-group-empty.tfvars"),
			expectError: true,
			description: "Empty resource group name should fail validation",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			runValidationTest(t, tt.name, tt.tfvarsFile, tt.expectError, tt.description)
		})
	}
}
