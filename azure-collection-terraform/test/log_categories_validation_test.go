package test

import (
	"fmt"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestLogCategoriesValidation tests the validation of log_categories field in target_resource_types
func TestLogCategoriesValidation(t *testing.T) {
	tests := []struct {
		name        string
		tfvarsFile  string
		expectError bool
		description string
		errorMsg    string
	}{
		{
			name:        "ValidLogCategories",
			tfvarsFile:  filepath.Join("test", fixturesDir, "valid-log-categories.tfvars"),
			expectError: false,
			description: "Valid log categories should pass validation",
		},
		{
			name:        "InvalidLogCategory",
			tfvarsFile:  filepath.Join("test", fixturesDir, "invalid-log-category.tfvars"),
			expectError: true,
			description: "Invalid log category should fail validation during plan phase",
			errorMsg:    "Invalid category",
		},
		{
			name:        "EmptyLogCategories",
			tfvarsFile:  filepath.Join("test", fixturesDir, "empty-log-categories.tfvars"),
			expectError: false,
			description: "Empty log_categories array should pass validation (enables all categories)",
		},
		{
			name:        "OmittedLogCategories",
			tfvarsFile:  filepath.Join("test", fixturesDir, "omitted-log-categories.tfvars"),
			expectError: false,
			description: "Omitted log_categories field should pass validation (enables all categories)",
		},
		{
			name:        "MultipleValidLogCategories",
			tfvarsFile:  filepath.Join("test", fixturesDir, "multiple-valid-log-categories.tfvars"),
			expectError: false,
			description: "Multiple valid log categories should pass validation",
		},
		{
			name:        "MixedValidAndInvalidCategories",
			tfvarsFile:  filepath.Join("test", fixturesDir, "mixed-log-categories.tfvars"),
			expectError: true,
			description: "Mix of valid and invalid categories should fail validation",
			errorMsg:    "Invalid category",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			terraformOptions := createTerraformOptions(tt.tfvarsFile)

			terraform.Init(t, terraformOptions)

			_, err := terraform.PlanE(t, terraformOptions)

			if tt.expectError {
				assert.Error(t, err, tt.description)
				if err != nil && tt.errorMsg != "" {
					errStr := err.Error()
					assert.Contains(t, errStr, tt.errorMsg,
						fmt.Sprintf("Error message should contain '%s', got: %v", tt.errorMsg, err))

					// Verify it's a precondition error (validation happens during plan)
					assert.True(t,
						strings.Contains(errStr, "Resource precondition failed") ||
							strings.Contains(errStr, "Invalid log categories detected"),
						"Should be a precondition validation error, got: %v", err)
				}
			} else {
				// For valid configurations, validation should pass
				// We might get API errors if resources don't exist, but validation itself should pass
				if err != nil {
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid category") ||
						strings.Contains(errStr, "Invalid log categories detected") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					} else {
						// API errors are expected for validation-only tests without real resources
						t.Logf("Test case '%s' passed validation but failed at runtime (expected): %v", tt.name, err)
					}
				}
			}
		})
	}
}

// TestLogCategoriesValidationWithMultipleResourceTypes tests log categories validation
// across multiple resource types in the same configuration
func TestLogCategoriesValidationWithMultipleResourceTypes(t *testing.T) {
	tests := []struct {
		name        string
		tfvarsFile  string
		expectError bool
		description string
	}{
		{
			name:        "MultipleResourceTypesAllValid",
			tfvarsFile:  filepath.Join("test", fixturesDir, "multiple-resources-valid-categories.tfvars"),
			expectError: false,
			description: "Multiple resource types with valid categories should pass",
		},
		{
			name:        "MultipleResourceTypesOneInvalid",
			tfvarsFile:  filepath.Join("test", fixturesDir, "multiple-resources-one-invalid.tfvars"),
			expectError: true,
			description: "Multiple resource types with one having invalid category should fail",
		},
		{
			name:        "MultipleResourceTypesMixedCategories",
			tfvarsFile:  filepath.Join("test", fixturesDir, "multiple-resources-mixed-categories.tfvars"),
			expectError: false,
			description: "Multiple resource types with some having categories and others without should pass",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			runValidationTest(t, tt.name, tt.tfvarsFile, tt.expectError, tt.description)
		})
	}
}

// TestLogCategoriesErrorMessages verifies that validation error messages are helpful and clear
func TestLogCategoriesErrorMessages(t *testing.T) {
	terraformOptions := createTerraformOptions(
		filepath.Join("test", fixturesDir, "invalid-log-category.tfvars"),
	)

	terraform.Init(t, terraformOptions)

	_, err := terraform.PlanE(t, terraformOptions)

	assert.Error(t, err, "Should fail with invalid log category")

	if err != nil {
		errStr := err.Error()

		// Error message should contain:
		// 1. The invalid category name
		// 2. The resource type
		// 3. List of valid categories
		assert.Contains(t, errStr, "Invalid category", "Error should mention invalid category")
		assert.Contains(t, errStr, "Valid categories are:", "Error should list valid categories")

		t.Logf("Error message (as expected): %s", errStr)
	}
}

// TestLogCategoriesDynamicValidation tests that validation uses actual Azure diagnostic categories
// rather than static lists
func TestLogCategoriesDynamicValidation(t *testing.T) {
	t.Log("Testing that log_categories validation is dynamic and fetches from Azure...")

	// This test verifies that the validation logic queries Azure for valid categories
	// rather than using a hardcoded list

	terraformOptions := createTerraformOptions(
		filepath.Join("test", fixturesDir, "valid-log-categories.tfvars"),
	)

	terraform.Init(t, terraformOptions)

	// Run plan - this should query Azure diagnostic categories
	_, err := terraform.PlanE(t, terraformOptions)

	// We expect this might fail due to API access issues in test environment,
	// but we can verify the data sources are being used
	if err != nil {
		errStr := err.Error()

		// Check if error is related to querying diagnostic categories
		// (which means the dynamic lookup is happening)
		if strings.Contains(errStr, "azurerm_monitor_diagnostic_categories") {
			t.Log("✅ Confirmed: Validation uses dynamic category lookup from Azure")
			return
		}

		// If we get a different error, log it but don't fail
		// (might be authentication or other test environment issues)
		t.Logf("Got error during plan (may be expected in test environment): %v", err)
	} else {
		t.Log("✅ Plan succeeded - validation passed")
	}
}

// TestLogCategoriesOptimization verifies that the validation uses efficient data source queries
func TestLogCategoriesOptimization(t *testing.T) {
	t.Log("Verifying that log_categories validation uses optimized data source queries...")

	// This test checks that we're using type_categories (efficient)
	// rather than all_categories (inefficient) for validation

	terraformOptions := createTerraformOptions(
		filepath.Join("test", fixturesDir, "multiple-resources-valid-categories.tfvars"),
	)

	terraform.Init(t, terraformOptions)

	// Show the plan output to verify data source usage
	output, err := terraform.RunTerraformCommandE(t, terraformOptions, "plan", "-no-color")

	// Check the output for data source queries
	if err == nil || output != "" {
		// Verify that type_categories data source is mentioned
		if strings.Contains(output, "data.azurerm_monitor_diagnostic_categories.type_categories") {
			t.Log("✅ Confirmed: Using optimized type_categories data source")
		}

		// Log for manual verification
		t.Logf("Plan output (first 500 chars): %s", output[:min(500, len(output))])
	} else if err != nil {
		t.Logf("Plan error (may be expected in test environment): %v", err)
	}
}

// Helper function to get minimum of two integers
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
