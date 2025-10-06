package test

import (
	"regexp"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

// TestDiagnosticSettingNamingLogic tests the diagnostic setting naming transformation logic
// This validates the Terraform naming pattern: "diag-${replace(replace(each.value.name, "/", "-"), ".", "-")}"
func TestDiagnosticSettingNamingLogic(t *testing.T) {
	tests := []struct {
		name             string
		resourceName     string
		expectedDiagName string
		shouldBeValid    bool
		description      string
	}{
		{
			name:             "StandardKeyVaultName",
			resourceName:     "my-keyvault-001",
			expectedDiagName: "diag-my-keyvault-001",
			shouldBeValid:    true,
			description:      "Standard resource name should produce valid diagnostic setting name",
		},
		{
			name:             "ResourceNameWithSlashes",
			resourceName:     "my/resource/name",
			expectedDiagName: "diag-my-resource-name",
			shouldBeValid:    true,
			description:      "Resource name with slashes should be transformed correctly",
		},
		{
			name:             "ResourceNameWithDots",
			resourceName:     "my.resource.name",
			expectedDiagName: "diag-my-resource-name",
			shouldBeValid:    true,
			description:      "Resource name with dots should be transformed correctly",
		},
		{
			name:             "ResourceNameWithSlashesAndDots",
			resourceName:     "my/resource.name/test",
			expectedDiagName: "diag-my-resource-name-test",
			shouldBeValid:    true,
			description:      "Resource name with both slashes and dots should be transformed correctly",
		},
		{
			name:             "LongResourceName",
			resourceName:     "very-long-resource-name-that-could-potentially-exceed-limits-when-transformed-to-diagnostic-setting-name",
			expectedDiagName: "diag-very-long-resource-name-that-could-potentially-exceed-limits-when-transformed-to-diagnostic-setting-name",
			shouldBeValid:    false, // This would exceed 64 character limit
			description:      "Very long resource name should be flagged as potentially problematic",
		},
		{
			name:             "ResourceNameWithUnderscores",
			resourceName:     "my_resource_name",
			expectedDiagName: "diag-my_resource_name",
			shouldBeValid:    true,
			description:      "Resource name with underscores should remain valid",
		},
		{
			name:             "ResourceNameWithNumbers",
			resourceName:     "resource123",
			expectedDiagName: "diag-resource123",
			shouldBeValid:    true,
			description:      "Resource name with numbers should remain valid",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Apply the Terraform transformation logic
			actualDiagName := transformResourceNameToDiagnosticSettingName(tt.resourceName)

			// Verify the transformation matches expected result
			assert.Equal(t, tt.expectedDiagName, actualDiagName,
				"Diagnostic setting name transformation should match expected result for test case '%s'", tt.name)

			// Validate length requirements (Azure diagnostic setting names: 1-64 characters)
			nameLength := len(actualDiagName)
			lengthValid := nameLength >= 1 && nameLength <= 64

			if tt.shouldBeValid {
				assert.True(t, lengthValid,
					"Diagnostic setting name should be between 1-64 characters for test case '%s', got %d chars: '%s'", tt.name, nameLength, actualDiagName)
			} else {
				// For cases expected to be invalid due to length
				if !lengthValid {
					t.Logf("Test case '%s' correctly identified as invalid due to length: %d chars", tt.name, nameLength)
				}
			}

			// Validate characters (should only contain alphanumeric, hyphens, underscores after transformation)
			validPattern := regexp.MustCompile(`^[a-zA-Z0-9_-]+$`)
			assert.True(t, validPattern.MatchString(actualDiagName),
				"Diagnostic setting name should only contain alphanumeric, hyphens, and underscores for test case '%s': '%s'", tt.name, actualDiagName)

			// Validate that problematic characters were replaced
			assert.NotContains(t, actualDiagName, "/",
				"Diagnostic setting name should not contain '/' after transformation for test case '%s': '%s'", tt.name, actualDiagName)
			assert.NotContains(t, actualDiagName, ".",
				"Diagnostic setting name should not contain '.' after transformation for test case '%s': '%s'", tt.name, actualDiagName)

			// Additional edge case validations for diagnostic setting naming requirements
			// Validate no spaces (which could cause issues)
			assert.NotContains(t, actualDiagName, " ",
				"Diagnostic setting name should not contain spaces for test case '%s': '%s'", tt.name, actualDiagName)

			// Validate name doesn't start or end with hyphens/underscores (Azure best practice)
			if len(actualDiagName) > 0 {
				assert.True(t, !strings.HasPrefix(actualDiagName, "-") && !strings.HasPrefix(actualDiagName, "_"),
					"Diagnostic setting name should not start with hyphen or underscore for test case '%s': '%s'", tt.name, actualDiagName)
				assert.True(t, !strings.HasSuffix(actualDiagName, "-") && !strings.HasSuffix(actualDiagName, "_"),
					"Diagnostic setting name should not end with hyphen or underscore for test case '%s': '%s'", tt.name, actualDiagName)
			}

			// Validate no consecutive hyphens or underscores (best practice)
			assert.False(t, strings.Contains(actualDiagName, "--") || strings.Contains(actualDiagName, "__"),
				"Diagnostic setting name should not contain consecutive hyphens or underscores for test case '%s': '%s'", tt.name, actualDiagName)

			t.Logf("Test case '%s': Resource name '%s' -> Diagnostic setting name '%s' (length: %d, valid: %t)",
				tt.name, tt.resourceName, actualDiagName, nameLength, tt.shouldBeValid && lengthValid)
		})
	}
}

// transformResourceNameToDiagnosticSettingName applies the same transformation logic as in Terraform
// This mirrors: "diag-${replace(replace(each.value.name, "/", "-"), ".", "-")}"
func transformResourceNameToDiagnosticSettingName(resourceName string) string {
	// Apply the same transformations as in the Terraform configuration
	transformed := strings.ReplaceAll(resourceName, "/", "-")
	transformed = strings.ReplaceAll(transformed, ".", "-")
	return "diag-" + transformed
}

// TestDiagnosticSettingNamingEdgeCases tests specific edge cases that could arise
func TestDiagnosticSettingNamingEdgeCases(t *testing.T) {
	edgeCases := []struct {
		name         string
		resourceName string
		description  string
	}{
		{
			name:         "EmptyResourceName",
			resourceName: "",
			description:  "Empty resource name should be handled gracefully",
		},
		{
			name:         "OnlySpecialCharacters",
			resourceName: "/././///",
			description:  "Resource name with only special characters should be transformed",
		},
		{
			name:         "MixedSpecialCharacters",
			resourceName: "test/./_resource-name",
			description:  "Resource name with mixed special characters should be handled",
		},
	}

	for _, tt := range edgeCases {
		t.Run(tt.name, func(t *testing.T) {
			actualDiagName := transformResourceNameToDiagnosticSettingName(tt.resourceName)

			// At minimum, should always have the "diag-" prefix
			assert.True(t, strings.HasPrefix(actualDiagName, "diag-"),
				"Diagnostic setting name should always start with 'diag-' prefix for test case '%s': '%s'", tt.name, actualDiagName)

			// Should not contain problematic characters
			assert.NotContains(t, actualDiagName, "/", "Should not contain '/' for test case '%s'", tt.name)
			assert.NotContains(t, actualDiagName, ".", "Should not contain '.' for test case '%s'", tt.name)

			t.Logf("Edge case '%s': Resource name '%s' -> Diagnostic setting name '%s'",
				tt.name, tt.resourceName, actualDiagName)
		})
	}
}
