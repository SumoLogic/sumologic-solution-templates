package test

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestResourceTypesParsing(t *testing.T) {
	tests := []struct {
		name           string
		input          string
		expectedOutput []string
		description    string
	}{
		{
			name:           "JSONArraySingleType",
			input:          `["Microsoft.KeyVault/vaults"]`,
			expectedOutput: []string{"Microsoft.KeyVault/vaults"},
			description:    "Single resource type in JSON array format",
		},
		{
			name:           "JSONArrayMultipleTypes",
			input:          `["Microsoft.KeyVault/vaults","Microsoft.Storage/storageAccounts","Microsoft.Sql/servers"]`,
			expectedOutput: []string{"Microsoft.KeyVault/vaults", "Microsoft.Storage/storageAccounts", "Microsoft.Sql/servers"},
			description:    "Multiple resource types in JSON array format",
		},
		{
			name:           "JSONArrayWithSpaces",
			input:          `["Microsoft.KeyVault/vaults", "Microsoft.Storage/storageAccounts", "Microsoft.Sql/servers"]`,
			expectedOutput: []string{"Microsoft.KeyVault/vaults", "Microsoft.Storage/storageAccounts", "Microsoft.Sql/servers"},
			description:    "Multiple resource types with spaces in JSON array format",
		},
		{
			name:           "CommaSeparatedFormat",
			input:          `Microsoft.KeyVault/vaults,Microsoft.Storage/storageAccounts,Microsoft.Sql/servers`,
			expectedOutput: []string{"Microsoft.KeyVault/vaults", "Microsoft.Storage/storageAccounts", "Microsoft.Sql/servers"},
			description:    "Multiple resource types in comma-separated format",
		},
		{
			name:           "CommaSeparatedWithSpaces",
			input:          `Microsoft.KeyVault/vaults, Microsoft.Storage/storageAccounts, Microsoft.Sql/servers`,
			expectedOutput: []string{"Microsoft.KeyVault/vaults", "Microsoft.Storage/storageAccounts", "Microsoft.Sql/servers"},
			description:    "Multiple resource types with spaces in comma-separated format",
		},
		{
			name:           "SingleResourceTypeNoArray",
			input:          `Microsoft.KeyVault/vaults`,
			expectedOutput: []string{"Microsoft.KeyVault/vaults"},
			description:    "Single resource type without array format",
		},
		{
			name:           "EmptyArray",
			input:          `[]`,
			expectedOutput: []string{},
			description:    "Empty JSON array",
		},
		{
			name:           "EmptyString",
			input:          ``,
			expectedOutput: []string{},
			description:    "Empty string",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := parseResourceTypesFromEnv(tt.input)
			assert.NoError(t, err, "Should parse successfully for test case '%s'", tt.name)
			assert.Equal(t, tt.expectedOutput, result, "Should match expected output for test case '%s': %s", tt.name, tt.description)
		})
	}
}

func TestTestEnvironmentHelperMethods(t *testing.T) {
	// Set up test environment with multiple resource types
	originalValue := os.Getenv("TARGET_RESOURCE_TYPES")
	defer os.Setenv("TARGET_RESOURCE_TYPES", originalValue)

	testCases := []struct {
		name             string
		resourceTypesEnv string
		expectedFirst    string
		expectedKeyVault string
		expectedStorage  string
		expectedSQL      string
		description      string
	}{
		{
			name:             "MultipleResourceTypes",
			resourceTypesEnv: `["Microsoft.KeyVault/vaults","Microsoft.Storage/storageAccounts","Microsoft.Sql/servers"]`,
			expectedFirst:    "Microsoft.KeyVault/vaults",
			expectedKeyVault: "Microsoft.KeyVault/vaults",
			expectedStorage:  "Microsoft.Storage/storageAccounts",
			expectedSQL:      "Microsoft.Sql/servers",
			description:      "Multiple resource types should be accessible through helper methods",
		},
		{
			name:             "SingleResourceType",
			resourceTypesEnv: `["Microsoft.KeyVault/vaults"]`,
			expectedFirst:    "Microsoft.KeyVault/vaults",
			expectedKeyVault: "Microsoft.KeyVault/vaults",
			expectedStorage:  "",
			expectedSQL:      "",
			description:      "Single resource type should work with helper methods",
		},
		{
			name:             "StorageFirst",
			resourceTypesEnv: `["Microsoft.Storage/storageAccounts","Microsoft.KeyVault/vaults"]`,
			expectedFirst:    "Microsoft.Storage/storageAccounts",
			expectedKeyVault: "Microsoft.KeyVault/vaults",
			expectedStorage:  "Microsoft.Storage/storageAccounts",
			expectedSQL:      "",
			description:      "Order should be preserved, patterns should still match",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Set environment variable
			os.Setenv("TARGET_RESOURCE_TYPES", tc.resourceTypesEnv)

			// Parse resource types
			resourceTypes, err := parseResourceTypesFromEnv(tc.resourceTypesEnv)
			assert.NoError(t, err, "Should parse resource types successfully")

			// Create test environment
			testEnv := &testEnvironment{
				TargetResourceTypes: resourceTypes,
			}

			// Test helper methods
			assert.Equal(t, tc.expectedFirst, testEnv.GetFirstResourceType(),
				"GetFirstResourceType should return expected value for test case '%s'", tc.name)

			assert.Equal(t, tc.expectedKeyVault, testEnv.GetKeyVaultType(),
				"GetKeyVaultType should return expected value for test case '%s'", tc.name)

			assert.Equal(t, tc.expectedStorage, testEnv.GetStorageType(),
				"GetStorageType should return expected value for test case '%s'", tc.name)

			// Test pattern matching by manually checking SQL
			expectedSQL := testEnv.GetResourceTypeByPattern("sql")
			assert.Equal(t, tc.expectedSQL, expectedSQL,
				"GetResourceTypeByPattern('sql') should return expected value for test case '%s'", tc.name)

			t.Logf("Test case '%s': %s", tc.name, tc.description)
			t.Logf("  Resource types: %v", resourceTypes)
			t.Logf("  First: %s, KeyVault: %s, Storage: %s, SQL: %s",
				testEnv.GetFirstResourceType(), testEnv.GetKeyVaultType(), testEnv.GetStorageType(), expectedSQL)
		})
	}
}
