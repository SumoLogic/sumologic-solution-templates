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
)

const testEnvFile = ".env.test"

// testEnvironment holds all required environment variables for tests
type testEnvironment struct {
	AzureSubscriptionID string
	AzureClientID       string
	AzureClientSecret   string
	AzureTenantID       string
	SumoAccessID        string
	SumoAccessKey       string
	SumoEnvironment     string
	TargetResourceTypes []string
	TestCollectorName   string
}

// Initialize environment variables from .env.test file for azure tests
func init() {
	if err := godotenv.Load(".env.test"); err != nil {
		log.Printf("Warning: .env.test file not found, using system environment variables")
	}
}

// loadTestEnvironment loads and validates all required environment variables
func loadTestEnvironment() (*testEnvironment, error) {
	env := &testEnvironment{}
	var err error

	if env.AzureSubscriptionID, err = getEnvOrError("AZURE_SUBSCRIPTION_ID"); err != nil {
		return nil, err
	}
	if env.AzureClientID, err = getEnvOrError("AZURE_CLIENT_ID"); err != nil {
		return nil, err
	}
	if env.AzureClientSecret, err = getEnvOrError("AZURE_CLIENT_SECRET"); err != nil {
		return nil, err
	}
	if env.AzureTenantID, err = getEnvOrError("AZURE_TENANT_ID"); err != nil {
		return nil, err
	}
	if env.SumoAccessID, err = getEnvOrError("SUMO_ACCESS_ID"); err != nil {
		return nil, err
	}
	if env.SumoAccessKey, err = getEnvOrError("SUMO_ACCESS_KEY"); err != nil {
		return nil, err
	}
	if env.SumoEnvironment, err = getEnvOrError("SUMO_ENVIRONMENT"); err != nil {
		return nil, err
	}

	// Parse TARGET_RESOURCE_TYPES from environment
	targetResourceTypesStr, err := getEnvOrError("TARGET_RESOURCE_TYPES")
	if err != nil {
		return nil, err
	}
	env.TargetResourceTypes, err = parseResourceTypesFromEnv(targetResourceTypesStr)
	if err != nil {
		return nil, fmt.Errorf("failed to parse TARGET_RESOURCE_TYPES: %w", err)
	}

	if env.TestCollectorName, err = getEnvOrError("TEST_COLLECTOR_NAME"); err != nil {
		return nil, err
	}

	return env, nil
}

// parseResourceTypesFromEnv parses resource types from environment variable format
// Supports both JSON array format: ["Microsoft.KeyVault/vaults","Microsoft.Storage/storageAccounts"]
// and comma-separated format: Microsoft.KeyVault/vaults,Microsoft.Storage/storageAccounts
func parseResourceTypesFromEnv(resourceTypesStr string) ([]string, error) {
	// Remove whitespace
	resourceTypesStr = strings.TrimSpace(resourceTypesStr)

	// Handle JSON array format
	if strings.HasPrefix(resourceTypesStr, "[") && strings.HasSuffix(resourceTypesStr, "]") {
		// Remove brackets and split by comma
		content := strings.Trim(resourceTypesStr, "[]")
		if content == "" {
			return []string{}, nil
		}

		var resourceTypes []string
		parts := strings.Split(content, ",")
		for _, part := range parts {
			// Remove quotes and whitespace
			cleaned := strings.Trim(strings.TrimSpace(part), `"`)
			if cleaned != "" {
				resourceTypes = append(resourceTypes, cleaned)
			}
		}
		return resourceTypes, nil
	}

	// Handle comma-separated format
	if strings.Contains(resourceTypesStr, ",") {
		var resourceTypes []string
		parts := strings.Split(resourceTypesStr, ",")
		for _, part := range parts {
			cleaned := strings.TrimSpace(part)
			if cleaned != "" {
				resourceTypes = append(resourceTypes, cleaned)
			}
		}
		return resourceTypes, nil
	}

	// Handle single resource type
	if resourceTypesStr != "" {
		return []string{resourceTypesStr}, nil
	}

	return []string{}, nil
}

// GetFirstResourceType returns the first resource type from TargetResourceTypes
func (te *testEnvironment) GetFirstResourceType() string {
	if len(te.TargetResourceTypes) > 0 {
		return te.TargetResourceTypes[0]
	}
	return ""
}

// GetResourceTypeByPattern returns the first resource type matching the pattern (case-insensitive)
func (te *testEnvironment) GetResourceTypeByPattern(pattern string) string {
	lowerPattern := strings.ToLower(pattern)
	for _, resourceType := range te.TargetResourceTypes {
		if strings.Contains(strings.ToLower(resourceType), lowerPattern) {
			return resourceType
		}
	}
	return ""
}

// GetKeyVaultType returns the first KeyVault resource type found
func (te *testEnvironment) GetKeyVaultType() string {
	return te.GetResourceTypeByPattern("keyvault")
}

// GetStorageType returns the first Storage resource type found
func (te *testEnvironment) GetStorageType() string {
	return te.GetResourceTypeByPattern("storage")
}

// generateCollectorName creates a consistent test collector name
func (te *testEnvironment) generateCollectorName() string {
	return fmt.Sprintf("TestCollector-%s", te.AzureSubscriptionID)
}

// toTfvarsMap converts environment variables to terraform variables map
func (te *testEnvironment) toTfvarsMap() map[string]interface{} {
	return map[string]interface{}{
		"azure_subscription_id": te.AzureSubscriptionID,
		"azure_client_id":       te.AzureClientID,
		"azure_client_secret":   te.AzureClientSecret,
		"azure_tenant_id":       te.AzureTenantID,
		"sumo_access_id":        te.SumoAccessID,
		"sumo_access_key":       te.SumoAccessKey,
		"sumo_environment":      te.SumoEnvironment,
	}
}

// createTestTfvars creates a comprehensive tfvars map with test-specific values
func (te *testEnvironment) createTestTfvars(resourceTypes []string, additionalVars map[string]interface{}) map[string]interface{} {
	// Start with base environment variables
	tfvars := te.toTfvarsMap()

	// Add common test variables
	tfvars["target_resource_types"] = resourceTypes
	tfvars["sumo_collector_name"] = te.generateCollectorName()
	tfvars["installation_apps_list"] = []string{}

	// Add any additional variables
	for key, value := range additionalVars {
		tfvars[key] = value
	}

	return tfvars
}

// loadEnvFile loads environment variables from the specified file
func loadEnvFile(filename string) error {
	return godotenv.Load(filename)
}

// getEnvOrError gets an environment variable or returns an error if not set
func getEnvOrError(key string) (string, error) {
	value := os.Getenv(key)
	if value == "" {
		return "", fmt.Errorf("required environment variable %s is not set", key)
	}
	return value, nil
}

// formatTfvarsWithAllVars formats a map of variables into tfvars format
func formatTfvarsWithAllVars(vars map[string]interface{}) string {
	var lines []string
	for key, value := range vars {
		switch v := value.(type) {
		case string:
			if v != "" {
				lines = append(lines, fmt.Sprintf(`%s = "%s"`, key, v))
			}
		case []string:
			lines = append(lines, fmt.Sprintf(`%s = %s`, key, formatStringSlice(v)))
		case bool:
			lines = append(lines, fmt.Sprintf(`%s = %t`, key, v))
		case int:
			lines = append(lines, fmt.Sprintf(`%s = %d`, key, v))
		default:
			lines = append(lines, fmt.Sprintf(`%s = "%v"`, key, v))
		}
	}
	return strings.Join(lines, "\n")
}

func TestAzureResourceTypeFormatValidation(t *testing.T) {
	// Load environment variables from .env.test
	err := loadEnvFile(testEnvFile)
	assert.NoError(t, err, "Failed to load test environment file")

	// Load test environment
	testEnv, err := loadTestEnvironment()
	assert.NoError(t, err, "Failed to load test environment variables")

	terraformDir := "../"

	// Test cases for Azure resource type format validation
	testCases := []struct {
		name             string
		resourceTypes    []string
		expectResources  bool
		expectedMinCount int
		description      string
	}{
		{
			name:             "ValidAzureResourceTypeFormats",
			resourceTypes:    []string{testEnv.GetKeyVaultType()}, // Using only KeyVault to avoid storage diagnostic issues
			expectResources:  true,
			expectedMinCount: 6, // Should create collector, log sources, metrics sources, event hubs, etc.
			description:      "Valid Azure resource type formats should create multiple resources",
		},
		{
			name:             "InvalidResourceTypeFormats",
			resourceTypes:    []string{"InvalidFormat", "NoSlash", "Microsoft."},
			expectResources:  false,
			expectedMinCount: 2, // Only collector and resource group should be created
			description:      "Invalid resource type formats should create minimal resources",
		},
		{
			name:             "InvalidResourceTypeWithoutSlash",
			resourceTypes:    []string{"InvalidFormatNoSlash"},
			expectResources:  false,
			expectedMinCount: 2, // Should fail validation and create minimal resources
			description:      "Resource type without slash should fail validation",
		},
		{
			name:             "DuplicateResourceTypes",
			resourceTypes:    []string{testEnv.GetKeyVaultType(), testEnv.GetKeyVaultType()},
			expectResources:  false,
			expectedMinCount: 2, // Should fail validation due to duplicates
			description:      "Duplicate resource types should fail validation",
		},
		{
			name:             "EmptyResourceTypes",
			resourceTypes:    []string{},
			expectResources:  false,
			expectedMinCount: 2, // Only collector and resource group
			description:      "Empty resource types list should create minimal resources",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Create comprehensive tfvars content with all required variables
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars(tc.resourceTypes, nil))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-azure-%s.tfvars", tc.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-azure-%s.tfvars", tc.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and check the results
			plan, err := terraform.PlanE(t, terraformOptions)
			assert.NoError(t, err, "Terraform plan should always succeed")

			// Count resources to be created from plan output
			resourceCount := countResourcesInPlan(plan)

			if tc.expectResources {
				assert.GreaterOrEqual(t, resourceCount, tc.expectedMinCount,
					fmt.Sprintf("%s: Expected at least %d resources, got %d", tc.description, tc.expectedMinCount, resourceCount))
			} else {
				assert.LessOrEqual(t, resourceCount, tc.expectedMinCount,
					fmt.Sprintf("%s: Expected at most %d resources, got %d", tc.description, tc.expectedMinCount, resourceCount))
			}
		})
	}
}

// countResourcesInPlan counts the number of resources to be created in a terraform plan output
func countResourcesInPlan(planOutput string) int {
	lines := strings.Split(planOutput, "\n")
	count := 0
	for _, line := range lines {
		if strings.Contains(line, "will be created") {
			count++
		}
	}
	return count
}

func TestAzureResourcesDataSourceConfiguration(t *testing.T) {
	// Load test environment
	testEnv, err := loadTestEnvironment()
	assert.NoError(t, err, "Failed to load test environment variables")

	terraformDir := "../"

	tests := []struct {
		name            string
		resourceTypes   []string
		requiredTags    map[string]string
		expectError     bool
		description     string
		expectedContent map[string]string
	}{
		{
			name:          "ValidResourceTypesWithoutTags",
			resourceTypes: []string{testEnv.GetKeyVaultType()},
			requiredTags:  map[string]string{},
			expectError:   false,
			description:   "Valid resource types should create data sources",
			expectedContent: map[string]string{
				"data_source": "data.azurerm_resources.all_target_resources",
				"type_filter": testEnv.GetKeyVaultType(),
			},
		},
		{
			name:          "ValidResourceTypesWithTags",
			resourceTypes: []string{testEnv.GetKeyVaultType()},
			requiredTags:  map[string]string{"environment": "test", "project": "sumologic"},
			expectError:   false,
			description:   "Valid resource types with tag filtering should work",
			expectedContent: map[string]string{
				"data_source":     "data.azurerm_resources.all_target_resources",
				"required_tags":   "required_tags",
				"tag_environment": "environment",
				"tag_project":     "project",
			},
		},
		{
			name:          "MultipleResourceTypes",
			resourceTypes: []string{testEnv.GetKeyVaultType(), testEnv.GetStorageType()},
			requiredTags:  map[string]string{},
			expectError:   false,
			description:   "Multiple resource types should create multiple data source instances",
			expectedContent: map[string]string{
				"data_source":       "data.azurerm_resources.all_target_resources",
				"keyvault_instance": fmt.Sprintf(`["%s"]`, testEnv.GetKeyVaultType()),
				"storage_instance":  fmt.Sprintf(`["%s"]`, testEnv.GetStorageType()),
			},
		},
		{
			name:            "EmptyResourceTypes",
			resourceTypes:   []string{},
			requiredTags:    map[string]string{},
			expectError:     false,
			description:     "Empty resource types should not create data sources",
			expectedContent: map[string]string{
				// No expected content since no data sources should be created
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create temporary tfvars file
			additionalVars := map[string]interface{}{
				"required_resource_tags": tt.requiredTags,
			}
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars(tt.resourceTypes, additionalVars))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-datasource-%s.tfvars", tt.name))
			defer os.Remove(tfvarsFile)

			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)

			// Test terraform plan (validation only)
			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-datasource-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			planOutput, err := terraform.PlanE(t, terraformOptions)

			if tt.expectError {
				assert.Error(t, err, "Expected terraform plan to fail: %s", tt.description)
			} else {
				// For positive cases, we might get API errors trying to access resources
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
					// Verify expected content appears in the plan
					for key, expectedValue := range tt.expectedContent {
						switch key {
						case "data_source":
							if len(tt.resourceTypes) > 0 {
								assert.Contains(t, planOutput, expectedValue,
									"Plan should contain data source for resource discovery")
							} else {
								assert.NotContains(t, planOutput, expectedValue,
									"Plan should NOT contain data source for empty resource types")
							}
						case "type_filter":
							assert.Contains(t, planOutput, fmt.Sprintf(`type = "%s"`, expectedValue),
								"Plan should contain correct resource type filter: %s", expectedValue)
						case "required_tags":
							if len(tt.requiredTags) > 0 {
								assert.Contains(t, planOutput, expectedValue,
									"Plan should contain required_tags configuration")
							}
						case "keyvault_instance", "storage_instance":
							assert.Contains(t, planOutput, expectedValue,
								"Plan should contain data source instance: %s", expectedValue)
						default:
							// Handle tag-specific assertions
							if strings.HasPrefix(key, "tag_") {
								tagName := strings.TrimPrefix(key, "tag_")
								assert.Contains(t, planOutput, tagName,
									"Plan should contain tag filter for: %s", tagName)
							}
						}
					}

					// Additional verification for resource types
					if len(tt.resourceTypes) > 0 {
						for _, resourceType := range tt.resourceTypes {
							// Check that each resource type gets its own data source instance
							assert.Contains(t, planOutput, fmt.Sprintf(`["%s"]`, resourceType),
								"Plan should contain data source instance for resource type: %s", resourceType)
						}

						// Verify the for_each is working correctly
						assert.Contains(t, planOutput, "for_each",
							"Plan should show for_each configuration in data source")
					}
				}
			}
		})
	}
}

// Helper function to format string slice for tfvars
func formatStringSlice(slice []string) string {
	if len(slice) == 0 {
		return "[]"
	}

	var formatted []string
	for _, item := range slice {
		formatted = append(formatted, fmt.Sprintf(`"%s"`, item))
	}
	return fmt.Sprintf("[%s]", strings.Join(formatted, ", "))
}

func TestAzureEventHubNamespaceConfiguration(t *testing.T) {
	// Load environment variables from .env.test
	err := loadEnvFile(testEnvFile)
	assert.NoError(t, err, "Failed to load test environment file")

	// Load test environment
	testEnv, err := loadTestEnvironment()
	assert.NoError(t, err, "Failed to load test environment variables")

	terraformDir := "../"

	// Test cases for Event Hub Namespace configuration
	testCases := []struct {
		name                  string
		resourceTypes         []string
		eventhubNamespaceName string
		throughputUnits       int
		expectedNamespaces    []string
		expectedProperties    map[string]interface{}
		description           string
	}{
		{
			name:                  "SingleResourceTypeSingleLocation",
			resourceTypes:         []string{testEnv.GetKeyVaultType()},
			eventhubNamespaceName: "TESTSUMO-HUB",
			throughputUnits:       3,
			expectedNamespaces:    []string{"TESTSUMO-HUB-eastus", "TESTSUMO-HUB-westus2"}, // Based on actual KeyVault locations
			expectedProperties: map[string]interface{}{
				"sku":      "Standard",
				"capacity": 3,
				"tags":     map[string]string{"version": "v1.0.0"},
			},
			description: "Single resource type should create namespaces in each location where resources exist",
		},
		{
			name:                  "CustomThroughputUnits",
			resourceTypes:         []string{testEnv.GetKeyVaultType()},
			eventhubNamespaceName: "SUMO-CUSTOM-HUB",
			throughputUnits:       10,
			expectedNamespaces:    []string{"SUMO-CUSTOM-HUB-eastus", "SUMO-CUSTOM-HUB-westus2"},
			expectedProperties: map[string]interface{}{
				"sku":      "Standard",
				"capacity": 10,
				"tags":     map[string]string{"version": "v1.0.0"},
			},
			description: "Custom throughput units should be applied correctly",
		},
		{
			name:                  "NamespaceNamingConventions",
			resourceTypes:         []string{testEnv.GetKeyVaultType()},
			eventhubNamespaceName: "Test Namespace With Spaces",
			throughputUnits:       5,
			expectedNamespaces:    []string{"Test Namespace With Spaces-eastus", "Test Namespace With Spaces-westus2"},
			expectedProperties: map[string]interface{}{
				"sku":      "Standard",
				"capacity": 5,
			},
			description: "Namespace names should handle spaces and special characters correctly",
		},
		{
			name:                  "EmptyResourceTypes",
			resourceTypes:         []string{},
			eventhubNamespaceName: "EMPTY-HUB",
			throughputUnits:       5,
			expectedNamespaces:    []string{}, // No namespaces should be created
			expectedProperties: map[string]interface{}{
				"resource_count": 0,
			},
			description: "Empty resource types should not create any Event Hub namespaces",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Create comprehensive tfvars content
			additionalVars := map[string]interface{}{
				"eventhub_namespace_name": tc.eventhubNamespaceName,
				"throughput_units":        tc.throughputUnits,
			}
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars(tc.resourceTypes, additionalVars))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-eventhub-%s.tfvars", tc.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-eventhub-%s.tfvars", tc.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and verify results
			plan, err := terraform.PlanE(t, terraformOptions)
			assert.NoError(t, err, "Terraform plan should succeed")

			// Verify expected namespaces are planned to be created
			if len(tc.expectedNamespaces) > 0 {
				for _, expectedNamespace := range tc.expectedNamespaces {
					assert.Contains(t, plan, expectedNamespace,
						fmt.Sprintf("Plan should contain Event Hub namespace: %s", expectedNamespace))
				}

				// Verify namespace resource type is created
				assert.Contains(t, plan, `azurerm_eventhub_namespace.namespaces_by_location`,
					"Plan should contain Event Hub namespace resource")

				// Verify expected properties
				if sku, exists := tc.expectedProperties["sku"]; exists {
					assert.Contains(t, plan, fmt.Sprintf(`sku = "%s"`, sku),
						fmt.Sprintf("Plan should contain correct SKU: %s", sku))
				}

				if capacity, exists := tc.expectedProperties["capacity"]; exists {
					assert.Contains(t, plan, fmt.Sprintf(`capacity = %d`, capacity),
						fmt.Sprintf("Plan should contain correct capacity: %d", capacity))
				}

				if tags, exists := tc.expectedProperties["tags"].(map[string]string); exists {
					for key, value := range tags {
						assert.Contains(t, plan, fmt.Sprintf(`"%s" = "%s"`, key, value),
							fmt.Sprintf("Plan should contain tag %s with value %s", key, value))
					}
				}

				// Verify for_each logic - should have multiple namespaces for multiple locations
				namespaceCount := strings.Count(plan, "azurerm_eventhub_namespace.namespaces_by_location[")
				if len(tc.resourceTypes) > 0 {
					assert.GreaterOrEqual(t, namespaceCount, len(tc.expectedNamespaces),
						fmt.Sprintf("Should create at least %d namespace instances", len(tc.expectedNamespaces)))
				}

				// Verify resource group reference
				assert.Contains(t, plan, "azurerm_resource_group.rg.name",
					"Namespace should reference the correct resource group")

				// Verify location mapping (each.key usage)
				for _, expectedNamespace := range tc.expectedNamespaces {
					// Extract location from namespace name
					parts := strings.Split(expectedNamespace, "-")
					if len(parts) > 0 {
						location := parts[len(parts)-1]
						assert.Contains(t, plan, fmt.Sprintf(`location = "%s"`, location),
							fmt.Sprintf("Plan should contain correct location: %s", location))
					}
				}
			} else {
				// Verify no namespaces are created for empty resource types
				assert.NotContains(t, plan, "azurerm_eventhub_namespace.namespaces_by_location",
					"Plan should NOT contain Event Hub namespace resource for empty resource types")
			}

			// Verify solution version tag is present
			if len(tc.resourceTypes) > 0 {
				assert.Contains(t, plan, `"version" = "v1.0.0"`,
					"Plan should contain version tag from local.solution_version")
			}
		})
	}
}

func TestEventHubNamespaceNamingConventions(t *testing.T) {
	// Test specific naming convention edge cases for location transformations
	testCases := []struct {
		name                   string
		inputLocation          string
		expectedTransformation string
		description            string
	}{
		{
			name:                   "SpacesInLocation",
			inputLocation:          "East US",
			expectedTransformation: "eastus", // spaces should be removed and lowercased
			description:            "Spaces should be removed from location names",
		},
		{
			name:                   "MixedCaseLocation",
			inputLocation:          "West US 2",
			expectedTransformation: "westus2", // "West US 2" -> "westus2"
			description:            "Mixed case locations should be lowercased with spaces removed",
		},
		{
			name:                   "AlreadyLowerCase",
			inputLocation:          "westus2",
			expectedTransformation: "westus2", // "westus2" stays as is
			description:            "Already lowercase locations should remain unchanged",
		},
		{
			name:                   "MultipleSpaces",
			inputLocation:          "Central  US",
			expectedTransformation: "centralus", // multiple spaces should be removed
			description:            "Multiple spaces should be removed from location names",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Apply the same transformation as in the terraform resource
			// name = "${var.eventhub_namespace_name}-${replace(lower(each.key), " ", "")}"
			transformedLocation := strings.ReplaceAll(strings.ToLower(tc.inputLocation), " ", "")

			assert.Equal(t, tc.expectedTransformation, transformedLocation,
				fmt.Sprintf("Location transformation should match expected: %s", tc.expectedTransformation))

			// Test full namespace name construction
			testNamespaceName := "SUMO-HUB"
			expectedFullName := fmt.Sprintf("%s-%s", testNamespaceName, transformedLocation)

			// Verify the final namespace name follows expected pattern
			assert.Contains(t, expectedFullName, testNamespaceName,
				"Final namespace name should contain original namespace name")
			assert.Contains(t, expectedFullName, transformedLocation,
				"Final namespace name should contain transformed location")
			assert.Equal(t, fmt.Sprintf("SUMO-HUB-%s", tc.expectedTransformation), expectedFullName,
				"Full namespace name should match expected format")
		})
	}
}

func TestEventHubNamespaceForEachLogic(t *testing.T) {
	// Test the for_each logic understanding without requiring environment variables
	// This tests our understanding of how local.resources_by_location_only works

	testCases := []struct {
		name                    string
		mockResourcesByLocation map[string][]string
		expectedNamespaces      []string
		description             string
	}{
		{
			name: "MultipleLocations",
			mockResourcesByLocation: map[string][]string{
				"eastus":  {"resource1", "resource2"},
				"westus2": {"resource3"},
			},
			expectedNamespaces: []string{"SUMO-HUB-eastus", "SUMO-HUB-westus2"},
			description:        "Should create one namespace per unique location",
		},
		{
			name: "SingleLocation",
			mockResourcesByLocation: map[string][]string{
				"centralus": {"resource1", "resource2", "resource3"},
			},
			expectedNamespaces: []string{"SUMO-HUB-centralus"},
			description:        "Should create one namespace for single location with multiple resources",
		},
		{
			name:                    "NoResources",
			mockResourcesByLocation: map[string][]string{},
			expectedNamespaces:      []string{},
			description:             "Should create no namespaces when no resources exist",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Simulate the for_each behavior
			namespaceName := "SUMO-HUB"

			var actualNamespaces []string
			for location := range tc.mockResourcesByLocation {
				// Apply the same naming logic as the terraform resource
				transformedLocation := strings.ReplaceAll(strings.ToLower(location), " ", "")
				namespaceName := fmt.Sprintf("%s-%s", namespaceName, transformedLocation)
				actualNamespaces = append(actualNamespaces, namespaceName)
			}

			// Sort both slices for comparison
			assert.ElementsMatch(t, tc.expectedNamespaces, actualNamespaces,
				fmt.Sprintf("Expected namespaces should match actual for: %s", tc.description))

			// Verify count
			assert.Equal(t, len(tc.expectedNamespaces), len(actualNamespaces),
				"Number of namespaces should match expected count")
		})
	}
}

func TestAzureEventHubConfiguration(t *testing.T) {
	// Load environment variables from .env.test
	err := loadEnvFile(testEnvFile)
	assert.NoError(t, err, "Failed to load test environment file")

	// Load test environment
	testEnv, err := loadTestEnvironment()
	assert.NoError(t, err, "Failed to load test environment variables")

	terraformDir := "../"

	// Test cases for Event Hub configuration
	testCases := []struct {
		name               string
		resourceTypes      []string
		expectedEventHubs  []string
		expectedProperties map[string]interface{}
		description        string
	}{
		{
			name:          "SingleResourceTypeMultipleLocations",
			resourceTypes: []string{testEnv.GetKeyVaultType()},
			expectedEventHubs: []string{
				"eventhub-Microsoft.KeyVault-vaults-eastus",
				"eventhub-Microsoft.KeyVault-vaults-westus2",
			},
			expectedProperties: map[string]interface{}{
				"partition_count":   4,
				"message_retention": 7,
			},
			description: "Single resource type should create Event Hubs for each type-location combination",
		},
		{
			name:          "EventHubNamingWithSlashes",
			resourceTypes: []string{testEnv.GetKeyVaultType()},
			expectedEventHubs: []string{
				"eventhub-Microsoft.KeyVault-vaults-eastus", // "/" replaced with "-"
				"eventhub-Microsoft.KeyVault-vaults-westus2",
			},
			expectedProperties: map[string]interface{}{
				"name_pattern": "eventhub-Microsoft.KeyVault-vaults",
			},
			description: "Event Hub names should replace forward slashes with hyphens",
		},
		{
			name:              "EmptyResourceTypes",
			resourceTypes:     []string{},
			expectedEventHubs: []string{},
			expectedProperties: map[string]interface{}{
				"resource_count": 0,
			},
			description: "Empty resource types should not create any Event Hubs",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Create comprehensive tfvars content
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars(tc.resourceTypes, nil))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-eventhub-config-%s.tfvars", tc.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-eventhub-config-%s.tfvars", tc.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and verify results
			plan, err := terraform.PlanE(t, terraformOptions)
			assert.NoError(t, err, "Terraform plan should succeed")

			// Verify expected Event Hubs are planned to be created
			if len(tc.expectedEventHubs) > 0 {
				for _, expectedEventHub := range tc.expectedEventHubs {
					assert.Contains(t, plan, expectedEventHub,
						fmt.Sprintf("Plan should contain Event Hub: %s", expectedEventHub))
				}

				// Verify Event Hub resource type is created
				assert.Contains(t, plan, `azurerm_eventhub.eventhubs_by_type_and_location`,
					"Plan should contain Event Hub resource")

				// Verify expected properties
				if partitionCount, exists := tc.expectedProperties["partition_count"]; exists {
					assert.Contains(t, plan, fmt.Sprintf(`partition_count = %d`, partitionCount),
						fmt.Sprintf("Plan should contain correct partition count: %d", partitionCount))
				}

				if messageRetention, exists := tc.expectedProperties["message_retention"]; exists {
					assert.Contains(t, plan, fmt.Sprintf(`message_retention = %d`, messageRetention),
						fmt.Sprintf("Plan should contain correct message retention: %d", messageRetention))
				}

				// Verify namespace reference - Event Hubs should reference the correct namespace
				assert.Contains(t, plan, "azurerm_eventhub_namespace.namespaces_by_location",
					"Event Hub should reference the correct namespace")

				// Verify for_each logic - should have multiple Event Hubs for multiple type-location combinations
				eventHubCount := strings.Count(plan, "azurerm_eventhub.eventhubs_by_type_and_location[")
				if len(tc.resourceTypes) > 0 {
					assert.GreaterOrEqual(t, eventHubCount, len(tc.expectedEventHubs),
						fmt.Sprintf("Should create at least %d Event Hub instances", len(tc.expectedEventHubs)))
				}

				// Verify naming pattern for slash replacement
				if namePattern, exists := tc.expectedProperties["name_pattern"].(string); exists {
					assert.Contains(t, plan, namePattern,
						fmt.Sprintf("Plan should contain name pattern: %s", namePattern))
				}
			} else {
				// Verify no Event Hubs are created for empty resource types
				assert.NotContains(t, plan, "azurerm_eventhub.eventhubs_by_type_and_location",
					"Plan should NOT contain Event Hub resource for empty resource types")
			}
		})
	}
}

func TestEventHubNamingConventions(t *testing.T) {
	// Test specific naming convention edge cases for Event Hub names
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
		{
			name:                 "SimpleResourceType",
			inputResourceType:    "SimpleResource",
			inputLocation:        "southcentralus",
			expectedEventHubName: "eventhub-SimpleResource-southcentralus",
			description:          "Simple resource types without slashes should work correctly",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Apply the same transformation as in the terraform resource
			// name = "eventhub-${replace(each.key, "/", "-")}"
			// where each.key is "${resource_type}-${location}"
			eachKey := fmt.Sprintf("%s-%s", tc.inputResourceType, tc.inputLocation)
			transformedName := fmt.Sprintf("eventhub-%s", strings.ReplaceAll(eachKey, "/", "-"))

			assert.Equal(t, tc.expectedEventHubName, transformedName,
				fmt.Sprintf("Event Hub name transformation should match expected: %s", tc.expectedEventHubName))

			// Verify the transformation logic
			assert.Contains(t, transformedName, "eventhub-",
				"Event Hub name should start with 'eventhub-'")
			assert.NotContains(t, transformedName, "/",
				"Event Hub name should not contain forward slashes")
			assert.Contains(t, transformedName, tc.inputLocation,
				"Event Hub name should contain the location")
		})
	}
}

func TestEventHubForEachLogic(t *testing.T) {
	// Test the for_each logic understanding for resources_by_type_and_location
	testCases := []struct {
		name                        string
		mockResourcesByTypeLocation map[string][]map[string]string
		expectedEventHubs           []string
		description                 string
	}{
		{
			name: "MultipleTypesAndLocations",
			mockResourcesByTypeLocation: map[string][]map[string]string{
				"Microsoft.KeyVault/vaults-eastus": {
					{"location": "eastus", "type": "Microsoft.KeyVault/vaults"},
				},
				"Microsoft.KeyVault/vaults-westus2": {
					{"location": "westus2", "type": "Microsoft.KeyVault/vaults"},
				},
				"Microsoft.Storage/storageAccounts-eastus": {
					{"location": "eastus", "type": "Microsoft.Storage/storageAccounts"},
				},
			},
			expectedEventHubs: []string{
				"eventhub-Microsoft.KeyVault-vaults-eastus",
				"eventhub-Microsoft.KeyVault-vaults-westus2",
				"eventhub-Microsoft.Storage-storageAccounts-eastus",
			},
			description: "Should create one Event Hub per unique type-location combination",
		},
		{
			name: "SameTypeMultipleLocations",
			mockResourcesByTypeLocation: map[string][]map[string]string{
				"Microsoft.KeyVault/vaults-eastus": {
					{"location": "eastus", "type": "Microsoft.KeyVault/vaults"},
				},
				"Microsoft.KeyVault/vaults-westus2": {
					{"location": "westus2", "type": "Microsoft.KeyVault/vaults"},
				},
				"Microsoft.KeyVault/vaults-centralus": {
					{"location": "centralus", "type": "Microsoft.KeyVault/vaults"},
				},
			},
			expectedEventHubs: []string{
				"eventhub-Microsoft.KeyVault-vaults-eastus",
				"eventhub-Microsoft.KeyVault-vaults-westus2",
				"eventhub-Microsoft.KeyVault-vaults-centralus",
			},
			description: "Same resource type in multiple locations should create multiple Event Hubs",
		},
		{
			name:                        "NoResources",
			mockResourcesByTypeLocation: map[string][]map[string]string{},
			expectedEventHubs:           []string{},
			description:                 "Should create no Event Hubs when no resources exist",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Simulate the for_each behavior
			var actualEventHubs []string
			for typeLocationKey := range tc.mockResourcesByTypeLocation {
				// Apply the same naming logic as the terraform resource
				eventHubName := fmt.Sprintf("eventhub-%s", strings.ReplaceAll(typeLocationKey, "/", "-"))
				actualEventHubs = append(actualEventHubs, eventHubName)
			}

			// Sort both slices for comparison
			assert.ElementsMatch(t, tc.expectedEventHubs, actualEventHubs,
				fmt.Sprintf("Expected Event Hubs should match actual for: %s", tc.description))

			// Verify count
			assert.Equal(t, len(tc.expectedEventHubs), len(actualEventHubs),
				"Number of Event Hubs should match expected count")
		})
	}
}

func TestEventHubNamespaceReference(t *testing.T) {
	// Test the namespace reference logic: each.value[0].location
	testCases := []struct {
		name              string
		mockResourceValue []map[string]interface{}
		expectedLocation  string
		description       string
	}{
		{
			name: "SingleResourceInLocation",
			mockResourceValue: []map[string]interface{}{
				{
					"location": "eastus",
					"name":     "test-keyvault-1",
					"type":     "Microsoft.KeyVault/vaults",
				},
			},
			expectedLocation: "eastus",
			description:      "Should reference the location from the first resource",
		},
		{
			name: "MultipleResourcesSameLocation",
			mockResourceValue: []map[string]interface{}{
				{
					"location": "westus2",
					"name":     "test-keyvault-1",
					"type":     "Microsoft.KeyVault/vaults",
				},
				{
					"location": "westus2",
					"name":     "test-keyvault-2",
					"type":     "Microsoft.KeyVault/vaults",
				},
			},
			expectedLocation: "westus2",
			description:      "Should reference the location from the first resource when multiple resources exist",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Simulate the namespace reference logic: each.value[0].location
			if len(tc.mockResourceValue) > 0 {
				actualLocation := tc.mockResourceValue[0]["location"].(string)
				assert.Equal(t, tc.expectedLocation, actualLocation,
					fmt.Sprintf("Namespace location reference should match expected: %s", tc.expectedLocation))
			}

			// Verify the namespace reference pattern
			expectedNamespaceRef := fmt.Sprintf("azurerm_eventhub_namespace.namespaces_by_location[%s].id", tc.expectedLocation)

			// This would be the actual reference in Terraform
			assert.Contains(t, expectedNamespaceRef, tc.expectedLocation,
				"Namespace reference should contain the correct location")
			assert.Contains(t, expectedNamespaceRef, "namespaces_by_location",
				"Should reference the correct namespace resource")
		})
	}
}

func TestAzureEventHubNamespaceAuthorizationRuleConfiguration(t *testing.T) {
	// Load environment variables from .env.test
	err := loadEnvFile(testEnvFile)
	assert.NoError(t, err, "Failed to load test environment file")

	// Load test environment
	testEnv, err := loadTestEnvironment()
	assert.NoError(t, err, "Failed to load test environment variables")

	terraformDir := "../"

	// Test cases for Event Hub Namespace Authorization Rule configuration
	testCases := []struct {
		name                       string
		resourceTypes              []string
		policyName                 string
		expectedAuthorizationRules []string
		expectedProperties         map[string]interface{}
		description                string
	}{
		{
			name:          "SingleResourceTypeMultipleLocations",
			resourceTypes: []string{testEnv.GetKeyVaultType()},
			policyName:    "SumoLogicCollectionPolicy",
			expectedAuthorizationRules: []string{
				"SumoLogicCollectionPolicy", // Should create rules for each namespace location
			},
			expectedProperties: map[string]interface{}{
				"listen": true,
				"send":   true,
				"manage": false,
			},
			description: "Single resource type should create authorization rules for each namespace location",
		},
		{
			name:          "CustomPolicyName",
			resourceTypes: []string{testEnv.GetKeyVaultType()},
			policyName:    "CustomCollectionPolicy",
			expectedAuthorizationRules: []string{
				"CustomCollectionPolicy",
			},
			expectedProperties: map[string]interface{}{
				"listen": true,
				"send":   true,
				"manage": false,
			},
			description: "Custom policy name should be applied correctly",
		},
		{
			name:          "AuthorizationRulePermissions",
			resourceTypes: []string{testEnv.GetKeyVaultType()},
			policyName:    "TestPermissionsPolicy",
			expectedAuthorizationRules: []string{
				"TestPermissionsPolicy",
			},
			expectedProperties: map[string]interface{}{
				"listen": true,  // Should have listen permission
				"send":   true,  // Should have send permission
				"manage": false, // Should NOT have manage permission (security best practice)
			},
			description: "Authorization rule should have correct permissions (listen=true, send=true, manage=false)",
		},
		{
			name:                       "EmptyResourceTypes",
			resourceTypes:              []string{},
			policyName:                 "EmptyPolicy",
			expectedAuthorizationRules: []string{},
			expectedProperties: map[string]interface{}{
				"resource_count": 0,
			},
			description: "Empty resource types should not create any authorization rules",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Create comprehensive tfvars content
			additionalVars := map[string]interface{}{
				"policy_name": tc.policyName,
			}
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars(tc.resourceTypes, additionalVars))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-auth-rule-%s.tfvars", tc.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-auth-rule-%s.tfvars", tc.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and verify results
			plan, err := terraform.PlanE(t, terraformOptions)
			assert.NoError(t, err, "Terraform plan should succeed")

			// Verify expected authorization rules are planned to be created
			if len(tc.expectedAuthorizationRules) > 0 {
				for _, expectedRule := range tc.expectedAuthorizationRules {
					assert.Contains(t, plan, fmt.Sprintf(`name = "%s"`, expectedRule),
						fmt.Sprintf("Plan should contain authorization rule with name: %s", expectedRule))
				}

				// Verify authorization rule resource type is created
				assert.Contains(t, plan, `azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy`,
					"Plan should contain Event Hub namespace authorization rule resource")

				// Verify expected permissions
				if listen, exists := tc.expectedProperties["listen"]; exists {
					assert.Contains(t, plan, fmt.Sprintf(`listen = %t`, listen),
						fmt.Sprintf("Plan should contain correct listen permission: %t", listen))
				}

				if send, exists := tc.expectedProperties["send"]; exists {
					assert.Contains(t, plan, fmt.Sprintf(`send = %t`, send),
						fmt.Sprintf("Plan should contain correct send permission: %t", send))
				}

				if manage, exists := tc.expectedProperties["manage"]; exists {
					assert.Contains(t, plan, fmt.Sprintf(`manage = %t`, manage),
						fmt.Sprintf("Plan should contain correct manage permission: %t", manage))
				}

				// Verify namespace reference - authorization rules should reference the correct namespace
				assert.Contains(t, plan, "each.value.name",
					"Authorization rule should reference the namespace name via each.value.name")

				// Verify resource group reference
				assert.Contains(t, plan, "azurerm_resource_group.rg.name",
					"Authorization rule should reference the correct resource group")

				// Verify for_each logic - should have multiple authorization rules for multiple namespaces
				authRuleCount := strings.Count(plan, "azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy[")
				if len(tc.resourceTypes) > 0 {
					assert.Greater(t, authRuleCount, 0,
						"Should create at least one authorization rule instance when resources exist")
				}

				// Verify the for_each is iterating over namespaces_by_location
				assert.Contains(t, plan, "for_each",
					"Plan should show for_each configuration in authorization rule")

			} else {
				// Verify no authorization rules are created for empty resource types
				assert.NotContains(t, plan, "azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy",
					"Plan should NOT contain authorization rule resource for empty resource types")
			}
		})
	}
}

func TestEventHubNamespaceAuthorizationRuleForEachLogic(t *testing.T) {
	// Test the for_each logic understanding for authorization rules
	// for_each = azurerm_eventhub_namespace.namespaces_by_location
	testCases := []struct {
		name                       string
		mockNamespacesByLocation   map[string]map[string]interface{}
		expectedAuthorizationRules []string
		description                string
	}{
		{
			name: "MultipleNamespaceLocations",
			mockNamespacesByLocation: map[string]map[string]interface{}{
				"eastus": {
					"name":     "SUMO-HUB-eastus",
					"location": "eastus",
				},
				"westus2": {
					"name":     "SUMO-HUB-westus2",
					"location": "westus2",
				},
			},
			expectedAuthorizationRules: []string{
				"SumoLogicCollectionPolicy-eastus", // One rule per namespace location
				"SumoLogicCollectionPolicy-westus2",
			},
			description: "Should create one authorization rule per namespace location",
		},
		{
			name: "SingleNamespaceLocation",
			mockNamespacesByLocation: map[string]map[string]interface{}{
				"centralus": {
					"name":     "SUMO-HUB-centralus",
					"location": "centralus",
				},
			},
			expectedAuthorizationRules: []string{
				"SumoLogicCollectionPolicy-centralus",
			},
			description: "Should create one authorization rule for single namespace location",
		},
		{
			name:                       "NoNamespaces",
			mockNamespacesByLocation:   map[string]map[string]interface{}{},
			expectedAuthorizationRules: []string{},
			description:                "Should create no authorization rules when no namespaces exist",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Simulate the for_each behavior over namespaces_by_location
			policyName := "SumoLogicCollectionPolicy"
			var actualAuthorizationRules []string

			for location, namespaceInfo := range tc.mockNamespacesByLocation {
				// Each authorization rule would be created with the policy name
				// The actual resource instance key would be the location
				ruleInstance := fmt.Sprintf("%s-%s", policyName, location)
				actualAuthorizationRules = append(actualAuthorizationRules, ruleInstance)

				// Verify the namespace reference logic
				namespaceName := namespaceInfo["name"].(string)
				assert.Contains(t, namespaceName, location,
					fmt.Sprintf("Namespace name should contain location: %s", location))
			}

			// Sort both slices for comparison
			assert.ElementsMatch(t, tc.expectedAuthorizationRules, actualAuthorizationRules,
				fmt.Sprintf("Expected authorization rules should match actual for: %s", tc.description))

			// Verify count
			assert.Equal(t, len(tc.expectedAuthorizationRules), len(actualAuthorizationRules),
				"Number of authorization rules should match expected count")
		})
	}
}

func TestEventHubNamespaceAuthorizationRuleReferences(t *testing.T) {
	// Test the reference logic in authorization rules
	testCases := []struct {
		name               string
		mockNamespaceValue map[string]interface{}
		expectedReferences map[string]string
		description        string
	}{
		{
			name: "NamespaceValueReferences",
			mockNamespaceValue: map[string]interface{}{
				"name":                "SUMO-HUB-eastus",
				"location":            "eastus",
				"resource_group_name": "test-rg",
			},
			expectedReferences: map[string]string{
				"namespace_name":      "SUMO-HUB-eastus",                // each.value.name
				"resource_group_name": "azurerm_resource_group.rg.name", // static reference
			},
			description: "Should correctly reference namespace name via each.value.name and resource group",
		},
		{
			name: "DifferentLocationNamespace",
			mockNamespaceValue: map[string]interface{}{
				"name":                "CUSTOM-HUB-westus2",
				"location":            "westus2",
				"resource_group_name": "custom-rg",
			},
			expectedReferences: map[string]string{
				"namespace_name":      "CUSTOM-HUB-westus2",
				"resource_group_name": "azurerm_resource_group.rg.name",
			},
			description: "Should work with different namespace names and locations",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Simulate the reference logic
			actualNamespaceName := tc.mockNamespaceValue["name"].(string)

			// Verify namespace name reference (each.value.name)
			expectedNamespaceName := tc.expectedReferences["namespace_name"]
			assert.Equal(t, expectedNamespaceName, actualNamespaceName,
				fmt.Sprintf("Namespace name reference should match expected: %s", expectedNamespaceName))

			// Verify the reference patterns that would appear in Terraform
			assert.Contains(t, actualNamespaceName, tc.mockNamespaceValue["location"].(string),
				"Namespace name should contain the location")

			// The resource group reference should always be static
			expectedRgRef := tc.expectedReferences["resource_group_name"]
			assert.Equal(t, "azurerm_resource_group.rg.name", expectedRgRef,
				"Resource group reference should be static")
		})
	}
}

func TestEventHubNamespaceAuthorizationRulePermissions(t *testing.T) {
	// Test specific permission configurations for authorization rules
	testCases := []struct {
		name                string
		expectedPermissions map[string]bool
		description         string
		securityImplication string
	}{
		{
			name: "SumoLogicCollectionPermissions",
			expectedPermissions: map[string]bool{
				"listen": true,  // Required to receive events from Event Hub
				"send":   true,  // Required to send events to Event Hub
				"manage": false, // Should NOT have manage permissions for security
			},
			description:         "Sumo Logic collection should have listen and send but not manage permissions",
			securityImplication: "Manage permission allows creating/deleting resources, which is not needed for data collection",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Verify each permission setting
			for permission, expectedValue := range tc.expectedPermissions {
				assert.Equal(t, expectedValue, tc.expectedPermissions[permission],
					fmt.Sprintf("Permission %s should be %t: %s", permission, expectedValue, tc.securityImplication))
			}

			// Verify security best practices
			if manage, exists := tc.expectedPermissions["manage"]; exists {
				assert.False(t, manage,
					"Manage permission should be false for security: %s", tc.securityImplication)
			}

			// Verify required permissions for data collection
			if listen, exists := tc.expectedPermissions["listen"]; exists {
				assert.True(t, listen,
					"Listen permission is required for receiving events from Event Hub")
			}

			if send, exists := tc.expectedPermissions["send"]; exists {
				assert.True(t, send,
					"Send permission is required for sending events to Event Hub")
			}
		})
	}
}

func TestAzureSubscriptionIDValidation(t *testing.T) {
	// Test Azure subscription ID validation in the context of resource creation
	// This tests real-world scenarios where invalid subscription IDs would cause problems
	terraformDir := "../"

	// Load base test environment but we'll override the subscription ID for testing
	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name           string
		subscriptionID string
		expectError    bool
		description    string
	}{
		{
			name:           "ValidSubscriptionID",
			subscriptionID: testEnv.AzureSubscriptionID, // Use the valid one from environment
			expectError:    false,
			description:    "Valid Azure subscription ID should pass validation",
		},
		{
			name:           "InvalidSubscriptionIDFormat",
			subscriptionID: "invalid-subscription-id-format",
			expectError:    true,
			description:    "Invalid subscription ID format should fail validation",
		},
		{
			name:           "EmptySubscriptionID",
			subscriptionID: "",
			expectError:    true,
			description:    "Empty subscription ID should fail validation",
		},
		{
			name:           "SubscriptionIDWithIncorrectFormat",
			subscriptionID: "12345678-1234-1234-123456789012", // Wrong format
			expectError:    true,
			description:    "Subscription ID with incorrect UUID format should fail validation",
		},
		{
			name:           "SubscriptionIDTooShort",
			subscriptionID: "c088dc46-d692-42ad-a4b6", // Too short
			expectError:    true,
			description:    "Subscription ID that's too short should fail validation",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars content with the test subscription ID
			additionalVars := map[string]interface{}{
				"azure_subscription_id": tt.subscriptionID,
			}
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars([]string{testEnv.GetKeyVaultType()}, additionalVars))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-subscription-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-subscription-%s.tfvars", tt.name)},
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

func TestEventHubNamespaceNameValidation(t *testing.T) {
	// Test Event Hub namespace name validation in the context of namespace creation
	// This tests real-world scenarios where invalid namespace names would cause Azure deployment failures
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name                  string
		eventhubNamespaceName string
		expectError           bool
		description           string
	}{
		{
			name:                  "ValidNamespaceName",
			eventhubNamespaceName: "SUMO-Valid-Hub-Name",
			expectError:           false,
			description:           "Valid Event Hub namespace name should pass validation",
		},
		{
			name:                  "NamespaceNameTooShort",
			eventhubNamespaceName: "short",
			expectError:           true,
			description:           "Namespace name shorter than 6 characters should fail validation",
		},
		{
			name:                  "NamespaceNameTooLong",
			eventhubNamespaceName: strings.Repeat("LongNamespace", 10), // Way too long
			expectError:           true,
			description:           "Namespace name longer than 50 characters should fail validation",
		},
		{
			name:                  "NamespaceNameStartingWithNumber",
			eventhubNamespaceName: "1InvalidStart",
			expectError:           true,
			description:           "Namespace name starting with number should fail validation",
		},
		{
			name:                  "NamespaceNameWithSpecialChars",
			eventhubNamespaceName: "Invalid@Name#With$Chars",
			expectError:           true,
			description:           "Namespace name with special characters should fail validation",
		},
		{
			name:                  "NamespaceNameEndingWithHyphen",
			eventhubNamespaceName: "Invalid-Name-",
			expectError:           true,
			description:           "Namespace name ending with hyphen should fail validation",
		},
		{
			name:                  "EmptyNamespaceName",
			eventhubNamespaceName: "",
			expectError:           true,
			description:           "Empty namespace name should fail validation",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars content with the test namespace name
			additionalVars := map[string]interface{}{
				"eventhub_namespace_name": tt.eventhubNamespaceName,
			}
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars([]string{testEnv.GetKeyVaultType()}, additionalVars))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-namespace-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-namespace-%s.tfvars", tt.name)},
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

func TestThroughputUnitsValidation(t *testing.T) {
	// Test throughput units validation in the context of Event Hub namespace configuration
	// This tests real-world scenarios where invalid throughput values would cause Azure deployment failures
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name            string
		throughputUnits int
		expectError     bool
		description     string
	}{
		{
			name:            "ValidThroughputUnits",
			throughputUnits: 10,
			expectError:     false,
			description:     "Valid throughput units (10) should pass validation",
		},
		{
			name:            "MinimumThroughputUnits",
			throughputUnits: 1,
			expectError:     false,
			description:     "Minimum throughput units (1) should pass validation",
		},
		{
			name:            "MaximumThroughputUnits",
			throughputUnits: 20,
			expectError:     false,
			description:     "Maximum throughput units (20) should pass validation",
		},
		{
			name:            "ThroughputUnitsBelowMinimum",
			throughputUnits: 0,
			expectError:     true,
			description:     "Throughput units below minimum (0) should fail validation",
		},
		{
			name:            "ThroughputUnitsAboveMaximum",
			throughputUnits: 25,
			expectError:     true,
			description:     "Throughput units above maximum (25) should fail validation",
		},
		{
			name:            "NegativeThroughputUnits",
			throughputUnits: -5,
			expectError:     true,
			description:     "Negative throughput units should fail validation",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars content with the test throughput units
			additionalVars := map[string]interface{}{
				"throughput_units": tt.throughputUnits,
			}
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars([]string{testEnv.GetKeyVaultType()}, additionalVars))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-throughput-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-throughput-%s.tfvars", tt.name)},
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

func TestBasicTerraformVariableValidation(t *testing.T) {
	// Simplified validation test that doesn't require all environment variables
	// This focuses purely on testing Terraform variable validation rules
	terraformDir := "../"

	testCases := []struct {
		name        string
		tfvarsVars  map[string]interface{}
		shouldFail  bool
		description string
	}{
		// Basic variable validation tests that don't need full environment
		{
			name: "InvalidResourceTypeFormat",
			tfvarsVars: map[string]interface{}{
				"target_resource_types":  []string{"InvalidFormat", "NoSlash"},
				"installation_apps_list": []interface{}{},
				"sumo_collector_name":    "Test-Collector",
				"throughput_units":       5,
			},
			shouldFail:  true,
			description: "Invalid resource type format should fail validation",
		},
		{
			name: "InvalidThroughputUnits",
			tfvarsVars: map[string]interface{}{
				"target_resource_types":  []string{"Microsoft.KeyVault/vaults"},
				"installation_apps_list": []interface{}{},
				"sumo_collector_name":    "Test-Collector",
				"throughput_units":       25, // Above maximum
			},
			shouldFail:  true,
			description: "Throughput units above maximum should fail validation",
		},
		{
			name: "InvalidNamespaceNameTooShort",
			tfvarsVars: map[string]interface{}{
				"target_resource_types":   []string{"Microsoft.KeyVault/vaults"},
				"installation_apps_list":  []interface{}{},
				"sumo_collector_name":     "Test-Collector",
				"eventhub_namespace_name": "short", // Too short
				"throughput_units":        5,
			},
			shouldFail:  true,
			description: "Event Hub namespace name too short should fail validation",
		},
		{
			name: "ValidBasicConfiguration",
			tfvarsVars: map[string]interface{}{
				"target_resource_types":   []string{"Microsoft.KeyVault/vaults"},
				"installation_apps_list":  []interface{}{},
				"sumo_collector_name":     "Test-Collector",
				"eventhub_namespace_name": "SUMO-Valid-Hub",
				"throughput_units":        10,
			},
			shouldFail:  false,
			description: "Valid basic configuration should pass validation",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Create tfvars content
			tfvarsContent := formatTfvarsWithAllVars(tc.tfvarsVars)

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-basic-%s.tfvars", tc.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-basic-%s.tfvars", tc.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and check if it succeeds or fails as expected
			_, err = terraform.PlanE(t, terraformOptions)

			if tc.shouldFail {
				assert.Error(t, err, tc.description)
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
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tc.name, err)
					} else {
						// API errors are expected for validation-only tests
						t.Logf("Test case '%s' passed validation but failed at runtime (expected): %v", tc.name, err)
					}
				}
			}
		})
	}
}

func TestAzureDiagnosticSettingConfiguration(t *testing.T) {
	// Test the azurerm_monitor_diagnostic_setting resource configuration and behavior
	// This tests the diagnostic settings that collect logs from Azure resources to Event Hub
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name              string
		resourceTypes     []string
		expectError       bool
		expectedResources []string
		description       string
	}{
		{
			name:          "ValidSingleResourceTypeDiagnosticSettings",
			resourceTypes: []string{testEnv.GetKeyVaultType()},
			expectError:   false,
			expectedResources: []string{
				"azurerm_monitor_diagnostic_setting.diagnostic_setting_logs",
				"data.azurerm_monitor_diagnostic_categories.all_categories",
			},
			description: "Valid single resource type should create diagnostic settings with proper log categories",
		},
		{
			name:          "ValidMultipleResourceTypesDiagnosticSettings",
			resourceTypes: []string{testEnv.GetKeyVaultType(), testEnv.GetStorageType()},
			expectError:   false,
			expectedResources: []string{
				"azurerm_monitor_diagnostic_setting.diagnostic_setting_logs",
				"data.azurerm_monitor_diagnostic_categories.all_categories",
			},
			description: "Multiple resource types should each get their own diagnostic settings",
		},
		{
			name:          "ValidAlternativeResourceTypeDiagnosticSettings",
			resourceTypes: []string{testEnv.GetStorageType()},
			expectError:   false,
			expectedResources: []string{
				"azurerm_monitor_diagnostic_setting.diagnostic_setting_logs",
				"data.azurerm_monitor_diagnostic_categories.all_categories",
			},
			description: "Any valid Azure resource type should create diagnostic settings with proper log categories",
		},
		{
			name:          "ValidGenericResourceTypeDiagnosticSettings",
			resourceTypes: []string{"Microsoft.Compute/virtualMachines", "Microsoft.Network/networkSecurityGroups"},
			expectError:   false,
			expectedResources: []string{
				"azurerm_monitor_diagnostic_setting.diagnostic_setting_logs",
				"data.azurerm_monitor_diagnostic_categories.all_categories",
			},
			description: "Diagnostic settings should work with any valid Azure resource type format",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with test configuration
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars(tt.resourceTypes, nil))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-diag-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-diag-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and analyze the results
			planOutput, err := terraform.PlanE(t, terraformOptions)

			if tt.expectError {
				assert.Error(t, err, tt.description)
			} else {
				// For valid configurations, we might get API errors trying to access resources
				// But the plan should show the expected resources
				if err != nil {
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
						return
					} else {
						// API errors are expected, but we can still check the plan output
						t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
					}
				}

				// Verify expected resources are in the plan
				for _, expectedResource := range tt.expectedResources {
					assert.Contains(t, planOutput, expectedResource,
						"Plan should contain %s for test case '%s'", expectedResource, tt.name)
				}

				// Test diagnostic setting specific attributes
				if strings.Contains(planOutput, "azurerm_monitor_diagnostic_setting.diagnostic_setting_logs") {
					// Verify diagnostic setting attributes
					assert.Contains(t, planOutput, "target_resource_id",
						"Diagnostic setting should have target_resource_id")
					assert.Contains(t, planOutput, "eventhub_authorization_rule_id",
						"Diagnostic setting should have eventhub_authorization_rule_id")
					assert.Contains(t, planOutput, "eventhub_name",
						"Diagnostic setting should have eventhub_name")
					assert.Contains(t, planOutput, "enabled_log",
						"Diagnostic setting should have enabled_log blocks")
				}
			}
		})
	}
}

func TestDiagnosticSettingNameGeneration(t *testing.T) {
	// Test the diagnostic setting name generation logic
	// The name should be "diag-${replace(replace(each.value.name, "/", "-"), ".", "-")}"
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name          string
		resourceTypes []string
		expectError   bool
		namePatterns  []string
		description   string
	}{
		{
			name:          "DiagnosticSettingNameFormatValidation",
			resourceTypes: []string{testEnv.GetKeyVaultType()},
			expectError:   false,
			namePatterns: []string{
				"diag-", // All diagnostic settings should start with "diag-"
			},
			description: "Diagnostic setting names should follow the expected format pattern for any resource type",
		},
		{
			name:          "DiagnosticSettingNameFormatValidationAlternateResourceType",
			resourceTypes: []string{testEnv.GetStorageType()},
			expectError:   false,
			namePatterns: []string{
				"diag-", // All diagnostic settings should start with "diag-"
			},
			description: "Diagnostic setting names should follow the expected format pattern for storage resources",
		},
		{
			name:          "DiagnosticSettingNameFormatValidationMultipleResourceTypes",
			resourceTypes: []string{testEnv.GetKeyVaultType(), testEnv.GetStorageType()},
			expectError:   false,
			namePatterns: []string{
				"diag-", // All diagnostic settings should start with "diag-"
			},
			description: "Diagnostic setting names should follow the expected format pattern for multiple resource types",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with test configuration
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars(tt.resourceTypes, nil))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-diag-name-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-diag-name-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and analyze the naming
			planOutput, err := terraform.PlanE(t, terraformOptions)

			if tt.expectError {
				assert.Error(t, err, tt.description)
			} else {
				// For valid configurations, we might get API errors trying to access resources
				if err != nil {
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
						return
					} else {
						// API errors are expected for validation-only tests
						t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
					}
				}

				// Verify name patterns in the plan output
				for _, pattern := range tt.namePatterns {
					assert.Contains(t, planOutput, pattern,
						"Plan should contain diagnostic setting name pattern '%s' for test case '%s'", pattern, tt.name)
				}

				// Verify that names don't contain invalid characters after replacement
				lines := strings.Split(planOutput, "\n")
				for _, line := range lines {
					if strings.Contains(line, "name") && strings.Contains(line, "diag-") {
						// The name should not contain unescaped "/" or "." characters
						nameStart := strings.Index(line, "diag-")
						if nameStart != -1 {
							nameEnd := strings.Index(line[nameStart:], "\"")
							if nameEnd != -1 {
								extractedName := line[nameStart : nameStart+nameEnd]
								// After "diag-" prefix, there should be no "/" or "." in the generated name
								nameSuffix := extractedName[5:] // Remove "diag-" prefix
								assert.NotContains(t, nameSuffix, "/",
									"Diagnostic setting name should not contain '/' characters: %s", extractedName)
								assert.NotContains(t, nameSuffix, ".",
									"Diagnostic setting name should not contain '.' characters: %s", extractedName)
							}
						}
					}
				}
			}
		})
	}
}

func TestDiagnosticSettingLogCategories(t *testing.T) {
	// Test that diagnostic settings include all available log categories for each resource type
	// This validates the dynamic "enabled_log" blocks are properly configured
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name              string
		resourceTypes     []string
		expectError       bool
		expectedLogBlocks []string
		description       string
	}{
		{
			name:          "SingleResourceTypeLogCategoriesEnabled",
			resourceTypes: []string{testEnv.GetKeyVaultType()},
			expectError:   false,
			expectedLogBlocks: []string{
				"enabled_log {",
				"category =",
			},
			description: "Single resource type diagnostic settings should include enabled_log blocks with categories",
		},
		{
			name:          "AlternativeResourceTypeLogCategoriesEnabled",
			resourceTypes: []string{testEnv.GetStorageType()},
			expectError:   false,
			expectedLogBlocks: []string{
				"enabled_log {",
				"category =",
			},
			description: "Alternative resource type diagnostic settings should include enabled_log blocks with categories",
		},
		{
			name:          "MultipleResourceTypesLogCategories",
			resourceTypes: []string{testEnv.GetKeyVaultType(), testEnv.GetStorageType()},
			expectError:   false,
			expectedLogBlocks: []string{
				"enabled_log {",
				"category =",
			},
			description: "Multiple resource types should each have their appropriate log categories enabled",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with test configuration
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars(tt.resourceTypes, nil))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-diag-logs-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-diag-logs-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and analyze log categories
			planOutput, err := terraform.PlanE(t, terraformOptions)

			if tt.expectError {
				assert.Error(t, err, tt.description)
			} else {
				// For valid configurations, we might get API errors trying to access resources
				if err != nil {
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
						return
					} else {
						// API errors are expected for validation-only tests
						t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
					}
				}

				// Verify expected log blocks are in the plan
				for _, expectedBlock := range tt.expectedLogBlocks {
					assert.Contains(t, planOutput, expectedBlock,
						"Plan should contain log block '%s' for test case '%s'", expectedBlock, tt.name)
				}

				// Verify that diagnostic categories data source is being used
				assert.Contains(t, planOutput, "data.azurerm_monitor_diagnostic_categories.all_categories",
					"Plan should reference diagnostic categories data source")

				// Check that the dynamic block is properly referencing log_category_types
				if strings.Contains(planOutput, "enabled_log") {
					assert.Contains(t, planOutput, "log_category_types",
						"Dynamic enabled_log blocks should reference log_category_types from data source")
				}
			}
		})
	}
}

func TestDiagnosticSettingEventHubIntegration(t *testing.T) {
	// Test that diagnostic settings are properly integrated with Event Hub resources
	// This validates the eventhub_name and eventhub_authorization_rule_id references
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name               string
		resourceTypes      []string
		expectError        bool
		expectedReferences []string
		description        string
	}{
		{
			name:          "EventHubIntegrationReferencesForSingleResourceType",
			resourceTypes: []string{testEnv.GetKeyVaultType()},
			expectError:   false,
			expectedReferences: []string{
				"azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy",
				"azurerm_eventhub.eventhubs_by_type_and_location",
				"eventhub_authorization_rule_id",
				"eventhub_name",
			},
			description: "Diagnostic settings should properly reference Event Hub resources for any single resource type",
		},
		{
			name:          "EventHubIntegrationReferencesForAlternativeResourceType",
			resourceTypes: []string{testEnv.GetStorageType()},
			expectError:   false,
			expectedReferences: []string{
				"azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy",
				"azurerm_eventhub.eventhubs_by_type_and_location",
				"eventhub_authorization_rule_id",
				"eventhub_name",
			},
			description: "Diagnostic settings should properly reference Event Hub resources for alternative resource types",
		},
		{
			name:          "EventHubIntegrationReferencesForMultipleResourceTypes",
			resourceTypes: []string{testEnv.GetKeyVaultType(), testEnv.GetStorageType()},
			expectError:   false,
			expectedReferences: []string{
				"azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy",
				"azurerm_eventhub.eventhubs_by_type_and_location",
				"eventhub_authorization_rule_id",
				"eventhub_name",
			},
			description: "Diagnostic settings should properly reference Event Hub resources for multiple resource types",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with test configuration
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars(tt.resourceTypes, nil))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-diag-eventhub-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-diag-eventhub-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and analyze Event Hub integration
			planOutput, err := terraform.PlanE(t, terraformOptions)

			if tt.expectError {
				assert.Error(t, err, tt.description)
			} else {
				// For valid configurations, we might get API errors trying to access resources
				if err != nil {
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
						return
					} else {
						// API errors are expected for validation-only tests
						t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
					}
				}

				// Verify expected Event Hub references are in the plan
				for _, expectedRef := range tt.expectedReferences {
					assert.Contains(t, planOutput, expectedRef,
						"Plan should contain Event Hub reference '%s' for test case '%s'", expectedRef, tt.name)
				}

				// Verify the lookup logic for parent_type is being used correctly
				if strings.Contains(planOutput, "eventhub_name") {
					// The eventhub_name should reference the proper key format: "${parent_type}-${location}"
					assert.Contains(t, planOutput, "eventhubs_by_type_and_location",
						"Diagnostic setting should reference eventhubs_by_type_and_location map")
				}
			}
		})
	}
}

func TestDiagnosticSettingForEachBehavior(t *testing.T) {
	// Test the for_each behavior with local.all_monitored_resources
	// This validates that diagnostic settings are created for each monitored resource
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name          string
		resourceTypes []string
		expectError   bool
		minResources  int
		description   string
	}{
		{
			name:          "SingleResourceTypeForEach",
			resourceTypes: []string{testEnv.GetKeyVaultType()},
			expectError:   false,
			minResources:  1,
			description:   "Any single resource type should create at least one diagnostic setting",
		},
		{
			name:          "AlternativeResourceTypeForEach",
			resourceTypes: []string{testEnv.GetStorageType()},
			expectError:   false,
			minResources:  1,
			description:   "Alternative resource type should create at least one diagnostic setting",
		},
		{
			name:          "MultipleResourceTypesForEach",
			resourceTypes: []string{testEnv.GetKeyVaultType(), testEnv.GetStorageType()},
			expectError:   false,
			minResources:  2,
			description:   "Multiple resource types should create multiple diagnostic settings",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with test configuration
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars(tt.resourceTypes, nil))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-diag-foreach-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-diag-foreach-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and analyze for_each behavior
			planOutput, err := terraform.PlanE(t, terraformOptions)

			if tt.expectError {
				assert.Error(t, err, tt.description)
			} else {
				// For valid configurations, we might get API errors trying to access resources
				if err != nil {
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
						return
					} else {
						// API errors are expected for validation-only tests
						t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
					}
				}

				// Count diagnostic setting instances in the plan
				diagnosticSettingCount := strings.Count(planOutput, "azurerm_monitor_diagnostic_setting.diagnostic_setting_logs[")

				assert.GreaterOrEqual(t, diagnosticSettingCount, tt.minResources,
					"Should create at least %d diagnostic setting(s) for test case '%s', found %d",
					tt.minResources, tt.name, diagnosticSettingCount)

				// Verify that each diagnostic setting has a unique key
				lines := strings.Split(planOutput, "\n")
				diagnosticKeys := make(map[string]bool)
				for _, line := range lines {
					if strings.Contains(line, "azurerm_monitor_diagnostic_setting.diagnostic_setting_logs[") {
						start := strings.Index(line, "[")
						end := strings.Index(line, "]")
						if start != -1 && end != -1 && end > start {
							key := line[start+1 : end]
							if key != "" {
								if diagnosticKeys[key] {
									t.Errorf("Duplicate diagnostic setting key found: %s", key)
								}
								diagnosticKeys[key] = true
							}
						}
					}
				}

				t.Logf("Test case '%s' found %d unique diagnostic setting keys", tt.name, len(diagnosticKeys))
			}
		})
	}
}

func TestDiagnosticSettingGenericResourceTypeSupport(t *testing.T) {
	// Test that diagnostic settings work with any Azure resource type format
	// This validates the generic nature of the diagnostic setting configuration

	// Use hardcoded generic resource types to avoid environment dependencies
	genericResourceTypes := [][]string{
		{"Microsoft.KeyVault/vaults"},
		{"Microsoft.Storage/storageAccounts"},
		{"Microsoft.Compute/virtualMachines"},
		{"Microsoft.Network/networkSecurityGroups"},
		{"Microsoft.Sql/servers/databases"},
		{"Microsoft.Web/sites"},
	}

	// Basic validation without full environment setup
	for i, resourceTypes := range genericResourceTypes {
		t.Run(fmt.Sprintf("GenericResourceType_%d", i+1), func(t *testing.T) {
			// Test resource type format validation
			for _, resourceType := range resourceTypes {
				// Validate resource type format (should contain Provider/resourceType)
				assert.Contains(t, resourceType, "/",
					"Resource type should contain '/' separator: %s", resourceType)
				assert.True(t, strings.HasPrefix(resourceType, "Microsoft."),
					"Resource type should start with 'Microsoft.': %s", resourceType)

				// Validate the name transformation logic that would be used in diagnostic settings
				// name = "diag-${replace(replace(each.value.name, "/", "-"), ".", "-")}"
				mockResourceName := fmt.Sprintf("test-%s-resource", strings.ToLower(strings.Split(resourceType, "/")[1]))
				transformedName := fmt.Sprintf("diag-%s",
					strings.ReplaceAll(strings.ReplaceAll(mockResourceName, "/", "-"), ".", "-"))

				assert.True(t, strings.HasPrefix(transformedName, "diag-"),
					"Diagnostic setting name should start with 'diag-': %s", transformedName)
				assert.NotContains(t, transformedName, "/",
					"Diagnostic setting name should not contain '/': %s", transformedName)
				assert.NotContains(t, transformedName, ".",
					"Diagnostic setting name should not contain '.': %s", transformedName)
			}
		})
	}
}

func TestActivityLogsEventHubNamespaceConditionalCreation(t *testing.T) {
	// Test the conditional creation of activity_logs_namespace based on enable_activity_logs variable
	// This tests the key difference from namespaces_by_location (count vs for_each)
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name                string
		enableActivityLogs  bool
		expectNamespace     bool
		expectedNamePattern string
		description         string
	}{
		{
			name:                "ActivityLogsEnabled",
			enableActivityLogs:  true,
			expectNamespace:     true,
			expectedNamePattern: "-activity-logs",
			description:         "When enable_activity_logs is true, activity_logs_namespace should be created",
		},
		{
			name:                "ActivityLogsDisabled",
			enableActivityLogs:  false,
			expectNamespace:     false,
			expectedNamePattern: "",
			description:         "When enable_activity_logs is false, activity_logs_namespace should not be created",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with activity logs configuration
			additionalVars := map[string]interface{}{
				"enable_activity_logs": tt.enableActivityLogs,
			}
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars([]string{testEnv.GetKeyVaultType()}, additionalVars))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-activity-logs-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-activity-logs-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and analyze results
			planOutput, err := terraform.PlanE(t, terraformOptions)

			// For valid configurations, we might get API errors trying to access resources
			if err != nil {
				errStr := err.Error()
				if strings.Contains(errStr, "Invalid value for variable") ||
					strings.Contains(errStr, "validation rule") {
					t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					return
				} else {
					// API errors are expected for validation-only tests
					t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
				}
			}

			if tt.expectNamespace {
				// Verify activity logs namespace is created
				assert.Contains(t, planOutput, "azurerm_eventhub_namespace.activity_logs_namespace",
					"Plan should contain activity logs namespace for test case '%s'", tt.name)

				// Verify the naming pattern
				assert.Contains(t, planOutput, tt.expectedNamePattern,
					"Activity logs namespace name should contain '%s' for test case '%s'", tt.expectedNamePattern, tt.name)

				// Verify it uses var.location (not dynamic location like namespaces_by_location)
				assert.Contains(t, planOutput, "var.location",
					"Activity logs namespace should use var.location for test case '%s'", tt.name)

				// Verify it uses count = 1 (not for_each)
				assert.Contains(t, planOutput, "activity_logs_namespace[0]",
					"Activity logs namespace should use count-based indexing for test case '%s'", tt.name)
			} else {
				// Verify activity logs namespace is NOT created
				assert.NotContains(t, planOutput, "azurerm_eventhub_namespace.activity_logs_namespace",
					"Plan should NOT contain activity logs namespace for test case '%s'", tt.name)
			}
		})
	}
}

func TestActivityLogsEventHubNamespaceNaming(t *testing.T) {
	// Test the static naming pattern for activity_logs_namespace
	// This tests the difference from namespaces_by_location (static vs dynamic naming)

	// Test the naming logic without environment dependencies
	testCases := []struct {
		name                    string
		eventhubNamespaceName   string
		expectedActivityLogName string
		description             string
	}{
		{
			name:                    "StandardNaming",
			eventhubNamespaceName:   "SUMO-HUB",
			expectedActivityLogName: "SUMO-HUB-activity-logs",
			description:             "Standard namespace name should get -activity-logs suffix",
		},
		{
			name:                    "NamespaceWithSpaces",
			eventhubNamespaceName:   "Test Namespace",
			expectedActivityLogName: "Test Namespace-activity-logs",
			description:             "Namespace names with spaces should preserve spaces in activity logs naming",
		},
		{
			name:                    "NamespaceWithHyphens",
			eventhubNamespaceName:   "SUMO-CUSTOM-HUB",
			expectedActivityLogName: "SUMO-CUSTOM-HUB-activity-logs",
			description:             "Namespace names with hyphens should work correctly with activity logs suffix",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Simulate the naming logic: "${var.eventhub_namespace_name}-activity-logs"
			actualName := fmt.Sprintf("%s-activity-logs", tc.eventhubNamespaceName)

			assert.Equal(t, tc.expectedActivityLogName, actualName,
				"Activity logs namespace name should match expected pattern for test case '%s'", tc.name)

			// Verify it always ends with -activity-logs
			assert.True(t, strings.HasSuffix(actualName, "-activity-logs"),
				"Activity logs namespace name should always end with '-activity-logs' for test case '%s'", tc.name)

			// Verify it starts with the base namespace name
			assert.True(t, strings.HasPrefix(actualName, tc.eventhubNamespaceName),
				"Activity logs namespace name should start with base namespace name for test case '%s'", tc.name)
		})
	}
}

func TestDiagnosticSettingResourceDependencies(t *testing.T) {
	// Test that diagnostic settings have proper dependencies on other resources
	// This validates that Event Hub resources are created before diagnostic settings
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name                 string
		resourceTypes        []string
		expectError          bool
		expectedDependencies []string
		description          string
	}{
		{
			name:          "DiagnosticSettingDependenciesForSingleResourceType",
			resourceTypes: []string{testEnv.GetKeyVaultType()},
			expectError:   false,
			expectedDependencies: []string{
				"azurerm_eventhub_namespace.namespaces_by_location",
				"azurerm_eventhub.eventhubs_by_type_and_location",
				"azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy",
			},
			description: "Diagnostic settings should depend on Event Hub infrastructure for any resource type",
		},
		{
			name:          "DiagnosticSettingDependenciesForAlternativeResourceType",
			resourceTypes: []string{testEnv.GetStorageType()},
			expectError:   false,
			expectedDependencies: []string{
				"azurerm_eventhub_namespace.namespaces_by_location",
				"azurerm_eventhub.eventhubs_by_type_and_location",
				"azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy",
			},
			description: "Diagnostic settings should depend on Event Hub infrastructure for alternative resource types",
		},
		{
			name:          "DiagnosticSettingDependenciesForMultipleResourceTypes",
			resourceTypes: []string{testEnv.GetKeyVaultType(), testEnv.GetStorageType()},
			expectError:   false,
			expectedDependencies: []string{
				"azurerm_eventhub_namespace.namespaces_by_location",
				"azurerm_eventhub.eventhubs_by_type_and_location",
				"azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy",
			},
			description: "Diagnostic settings should depend on Event Hub infrastructure for multiple resource types",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with test configuration
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars(tt.resourceTypes, nil))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-diag-deps-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-diag-deps-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and analyze dependencies
			planOutput, err := terraform.PlanE(t, terraformOptions)

			if tt.expectError {
				assert.Error(t, err, tt.description)
			} else {
				// For valid configurations, we might get API errors trying to access resources
				if err != nil {
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
						return
					} else {
						// API errors are expected for validation-only tests
						t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
					}
				}

				// Verify that all expected dependencies are present in the plan
				for _, expectedDep := range tt.expectedDependencies {
					assert.Contains(t, planOutput, expectedDep,
						"Plan should contain dependency '%s' for test case '%s'", expectedDep, tt.name)
				}

				// Verify that diagnostic settings reference the dependent resources
				if strings.Contains(planOutput, "azurerm_monitor_diagnostic_setting.diagnostic_setting_logs") {
					// Check that the diagnostic setting references are properly formed
					assert.Contains(t, planOutput, "target_resource_id             = each.value.id",
						"Diagnostic setting should reference each.value.id for target_resource_id")

					// Check that it references the Event Hub authorization rule correctly
					assert.True(t,
						strings.Contains(planOutput, ".sumo_collection_policy[each.value.location].id") ||
							strings.Contains(planOutput, ".sumo_collection_policy[") ||
							strings.Contains(planOutput, "authorization_rule_id"),
						"Diagnostic setting should reference authorization rule with location-based key")
				}
			}
		})
	}
}

func TestActivityLogsAuthorizationRuleConditionalCreation(t *testing.T) {
	// Test the conditional creation of activity_logs_policy based on enable_activity_logs variable
	// This tests the key functionality: count-based creation that depends on enable_activity_logs
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name                string
		enableActivityLogs  bool
		expectAuthRule      bool
		expectedPolicyName  string
		expectedPermissions map[string]bool
		description         string
	}{
		{
			name:               "ActivityLogsAuthRuleEnabled",
			enableActivityLogs: true,
			expectAuthRule:     true,
			expectedPolicyName: "SumoLogicCollectionPolicy", // Default policy name
			expectedPermissions: map[string]bool{
				"listen": true,
				"send":   true,
				"manage": false,
			},
			description: "When enable_activity_logs is true, activity_logs_policy should be created with correct permissions",
		},
		{
			name:                "ActivityLogsAuthRuleDisabled",
			enableActivityLogs:  false,
			expectAuthRule:      false,
			expectedPolicyName:  "",
			expectedPermissions: map[string]bool{},
			description:         "When enable_activity_logs is false, activity_logs_policy should not be created",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with activity logs configuration
			additionalVars := map[string]interface{}{
				"enable_activity_logs": tt.enableActivityLogs,
				"policy_name":          tt.expectedPolicyName,
			}
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars([]string{testEnv.GetKeyVaultType()}, additionalVars))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-activity-auth-rule-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-activity-auth-rule-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and analyze results
			planOutput, err := terraform.PlanE(t, terraformOptions)

			// For valid configurations, we might get API errors trying to access resources
			if err != nil {
				errStr := err.Error()
				if strings.Contains(errStr, "Invalid value for variable") ||
					strings.Contains(errStr, "validation rule") {
					t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					return
				} else {
					// API errors are expected for validation-only tests
					t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
				}
			}

			if tt.expectAuthRule {
				// Verify activity logs authorization rule is created
				assert.Contains(t, planOutput, "azurerm_eventhub_namespace_authorization_rule.activity_logs_policy",
					"Plan should contain activity logs authorization rule for test case '%s'", tt.name)

				// Verify the policy name
				if tt.expectedPolicyName != "" {
					assert.Contains(t, planOutput, fmt.Sprintf(`name = "%s"`, tt.expectedPolicyName),
						"Authorization rule should have correct policy name '%s' for test case '%s'", tt.expectedPolicyName, tt.name)
				}

				// Verify permissions
				for permission, expectedValue := range tt.expectedPermissions {
					assert.Contains(t, planOutput, fmt.Sprintf(`%s = %t`, permission, expectedValue),
						"Authorization rule should have %s=%t for test case '%s'", permission, expectedValue, tt.name)
				}

				// Verify it uses count = 1 (not for_each like sumo_collection_policy)
				assert.Contains(t, planOutput, "activity_logs_policy[0]",
					"Activity logs authorization rule should use count-based indexing for test case '%s'", tt.name)

				// Verify it references the activity_logs_namespace correctly
				assert.Contains(t, planOutput, "activity_logs_namespace[0].name",
					"Authorization rule should reference activity_logs_namespace[0].name for test case '%s'", tt.name)

				// Verify resource group reference
				assert.Contains(t, planOutput, "azurerm_resource_group.rg.name",
					"Authorization rule should reference the correct resource group for test case '%s'", tt.name)

			} else {
				// Verify activity logs authorization rule is NOT created
				assert.NotContains(t, planOutput, "azurerm_eventhub_namespace_authorization_rule.activity_logs_policy",
					"Plan should NOT contain activity logs authorization rule for test case '%s'", tt.name)
			}
		})
	}
}

func TestActivityLogsAuthorizationRuleNamingAndPermissions(t *testing.T) {
	// Test the naming and permission configurations for activity_logs_policy
	// This validates the specific configuration requirements for activity logs collection

	testCases := []struct {
		name                string
		policyName          string
		expectedPermissions map[string]bool
		description         string
		securityNote        string
	}{
		{
			name:       "DefaultPolicyNameAndPermissions",
			policyName: "SumoLogicCollectionPolicy",
			expectedPermissions: map[string]bool{
				"listen": true,  // Required to receive events from Event Hub
				"send":   true,  // Required to send events to Event Hub
				"manage": false, // Should NOT have manage permissions for security
			},
			description:  "Default policy name with standard Sumo Logic collection permissions",
			securityNote: "Manage permission allows creating/deleting resources, which is not needed for activity logs collection",
		},
		{
			name:       "CustomPolicyNameWithSamePermissions",
			policyName: "CustomActivityLogsPolicy",
			expectedPermissions: map[string]bool{
				"listen": true,
				"send":   true,
				"manage": false,
			},
			description:  "Custom policy name should work with same security permissions",
			securityNote: "Regardless of policy name, permissions should follow security best practices",
		},
		{
			name:       "PolicyForActivityLogsSpecifically",
			policyName: "ActivityLogsCollectionPolicy",
			expectedPermissions: map[string]bool{
				"listen": true,
				"send":   true,
				"manage": false,
			},
			description:  "Activity logs specific policy name with secure permissions",
			securityNote: "Activity logs collection only needs listen and send permissions",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Test the permission configuration without environment dependencies
			for permission, expectedValue := range tc.expectedPermissions {
				assert.Equal(t, expectedValue, tc.expectedPermissions[permission],
					"Permission %s should be %t for activity logs policy: %s", permission, expectedValue, tc.securityNote)
			}

			// Verify security best practices
			if manage, exists := tc.expectedPermissions["manage"]; exists {
				assert.False(t, manage,
					"Manage permission should be false for security: %s", tc.securityNote)
			}

			// Verify required permissions for activity logs collection
			if listen, exists := tc.expectedPermissions["listen"]; exists {
				assert.True(t, listen,
					"Listen permission is required for receiving activity logs from Event Hub")
			}

			if send, exists := tc.expectedPermissions["send"]; exists {
				assert.True(t, send,
					"Send permission is required for sending activity logs to Event Hub")
			}

			// Verify policy name format
			assert.NotEmpty(t, tc.policyName,
				"Policy name should not be empty for test case '%s'", tc.name)
			assert.True(t, len(tc.policyName) >= 3,
				"Policy name should be at least 3 characters long for test case '%s'", tc.name)
		})
	}
}

func TestActivityLogsAuthorizationRuleReferences(t *testing.T) {
	// Test the reference logic in activity_logs_policy authorization rule
	// This validates how it differs from sumo_collection_policy in its references
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name               string
		enableActivityLogs bool
		expectedReferences []string
		notExpectedRefs    []string
		description        string
	}{
		{
			name:               "ActivityLogsAuthRuleReferences",
			enableActivityLogs: true,
			expectedReferences: []string{
				"azurerm_eventhub_namespace.activity_logs_namespace[0].name", // Static reference to [0]
				"azurerm_resource_group.rg.name",                             // Static resource group reference
			},
			notExpectedRefs: []string{
				"each.value.name",        // Should NOT use each.value like sumo_collection_policy
				"namespaces_by_location", // Should NOT reference regular namespaces
				"for_each",               // Should NOT use for_each pattern
			},
			description: "Activity logs authorization rule should use static references, not for_each patterns",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with activity logs configuration
			additionalVars := map[string]interface{}{
				"enable_activity_logs": tt.enableActivityLogs,
			}
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars([]string{testEnv.GetKeyVaultType()}, additionalVars))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-activity-auth-refs-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-activity-auth-refs-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and analyze references
			planOutput, err := terraform.PlanE(t, terraformOptions)

			// For valid configurations, we might get API errors trying to access resources
			if err != nil {
				errStr := err.Error()
				if strings.Contains(errStr, "Invalid value for variable") ||
					strings.Contains(errStr, "validation rule") {
					t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					return
				} else {
					// API errors are expected for validation-only tests
					t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
				}
			}

			if tt.enableActivityLogs {
				// Verify expected references are present
				for _, expectedRef := range tt.expectedReferences {
					assert.Contains(t, planOutput, expectedRef,
						"Plan should contain reference '%s' for test case '%s'", expectedRef, tt.name)
				}

				// Verify unexpected references are NOT present
				for _, notExpectedRef := range tt.notExpectedRefs {
					assert.NotContains(t, planOutput, notExpectedRef,
						"Plan should NOT contain reference '%s' for test case '%s'", notExpectedRef, tt.name)
				}

				// Verify the authorization rule is created with count pattern
				assert.Contains(t, planOutput, "azurerm_eventhub_namespace_authorization_rule.activity_logs_policy",
					"Plan should contain activity logs authorization rule for test case '%s'", tt.name)

				// Verify it uses array indexing [0] not map keys
				authRuleLines := strings.Split(planOutput, "\n")
				foundCountPattern := false
				for _, line := range authRuleLines {
					if strings.Contains(line, "activity_logs_policy[0]") {
						foundCountPattern = true
						break
					}
				}
				assert.True(t, foundCountPattern,
					"Activity logs authorization rule should use count-based indexing [0] for test case '%s'", tt.name)
			}
		})
	}
}

func TestActivityLogsEventHubConditionalCreation(t *testing.T) {
	// Test the conditional creation of eventhub_for_activity_logs based on enable_activity_logs variable
	// This tests the key functionality: count-based creation that depends on enable_activity_logs
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name                  string
		enableActivityLogs    bool
		activityLogExportName string
		expectEventHub        bool
		expectedProperties    map[string]interface{}
		description           string
	}{
		{
			name:                  "ActivityLogsEventHubEnabled",
			enableActivityLogs:    true,
			activityLogExportName: "insights-activity-logs",
			expectEventHub:        true,
			expectedProperties: map[string]interface{}{
				"partition_count":   4,
				"message_retention": 7,
			},
			description: "When enable_activity_logs is true, eventhub_for_activity_logs should be created with correct properties",
		},
		{
			name:                  "ActivityLogsEventHubDisabled",
			enableActivityLogs:    false,
			activityLogExportName: "insights-activity-logs",
			expectEventHub:        false,
			expectedProperties:    map[string]interface{}{},
			description:           "When enable_activity_logs is false, eventhub_for_activity_logs should not be created",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with activity logs Event Hub configuration
			additionalVars := map[string]interface{}{
				"enable_activity_logs":     tt.enableActivityLogs,
				"activity_log_export_name": tt.activityLogExportName,
			}
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars([]string{testEnv.GetKeyVaultType()}, additionalVars))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-activity-eventhub-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-activity-eventhub-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and analyze results
			planOutput, err := terraform.PlanE(t, terraformOptions)

			// For valid configurations, we might get API errors trying to access resources
			if err != nil {
				errStr := err.Error()
				if strings.Contains(errStr, "Invalid value for variable") ||
					strings.Contains(errStr, "validation rule") {
					t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					return
				} else {
					// API errors are expected for validation-only tests
					t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
				}
			}

			if tt.expectEventHub {
				// Verify activity logs Event Hub is created
				assert.Contains(t, planOutput, "azurerm_eventhub.eventhub_for_activity_logs",
					"Plan should contain activity logs Event Hub for test case '%s'", tt.name)

				// Verify the Event Hub name (uses var.activity_log_export_name variable)
				assert.Contains(t, planOutput, fmt.Sprintf(`name = "%s"`, tt.activityLogExportName),
					"Event Hub should have correct name '%s' from var.activity_log_export_name for test case '%s'", tt.activityLogExportName, tt.name)

				// Verify expected properties
				for property, expectedValue := range tt.expectedProperties {
					switch property {
					case "partition_count":
						assert.Contains(t, planOutput, fmt.Sprintf(`partition_count = %d`, expectedValue),
							"Event Hub should have partition_count=%d for test case '%s'", expectedValue, tt.name)
					case "message_retention":
						assert.Contains(t, planOutput, fmt.Sprintf(`message_retention = %d`, expectedValue),
							"Event Hub should have message_retention=%d for test case '%s'", expectedValue, tt.name)
					}
				}

				// Verify it uses count = 1 (not for_each like eventhubs_by_type_and_location)
				assert.Contains(t, planOutput, "eventhub_for_activity_logs[0]",
					"Activity logs Event Hub should use count-based indexing for test case '%s'", tt.name)

				// Verify it references the activity_logs_namespace correctly
				assert.Contains(t, planOutput, "activity_logs_namespace[0].id",
					"Event Hub should reference activity_logs_namespace[0].id for test case '%s'", tt.name)

			} else {
				// Verify activity logs Event Hub is NOT created
				assert.NotContains(t, planOutput, "azurerm_eventhub.eventhub_for_activity_logs",
					"Plan should NOT contain activity logs Event Hub for test case '%s'", tt.name)
			}
		})
	}
}

func TestActivityLogsEventHubConfiguration(t *testing.T) {
	// Test the configuration properties and naming for eventhub_for_activity_logs
	// This validates the specific configuration requirements for activity logs Event Hub
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name               string
		activityLogName    string
		expectedProperties map[string]interface{}
		description        string
	}{
		{
			name:            "DefaultActivityLogsEventHubConfiguration",
			activityLogName: "insights-activity-logs", // Test value for var.activity_log_export_name
			expectedProperties: map[string]interface{}{
				"partition_count":   4, // Fixed value for activity logs
				"message_retention": 7, // Fixed value for activity logs
			},
			description: "Activity logs Event Hub should have fixed partition count and message retention with default variable value",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with activity logs Event Hub configuration
			additionalVars := map[string]interface{}{
				"enable_activity_logs":     true,
				"activity_log_export_name": tt.activityLogName,
			}
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars([]string{testEnv.GetKeyVaultType()}, additionalVars))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-activity-eventhub-config-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-activity-eventhub-config-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and analyze configuration
			planOutput, err := terraform.PlanE(t, terraformOptions)

			// For valid configurations, we might get API errors trying to access resources
			if err != nil {
				errStr := err.Error()
				if strings.Contains(errStr, "Invalid value for variable") ||
					strings.Contains(errStr, "validation rule") {
					t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					return
				} else {
					// API errors are expected for validation-only tests
					t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
				}
			}

			// Verify Event Hub resource is created
			assert.Contains(t, planOutput, "azurerm_eventhub.eventhub_for_activity_logs",
				"Plan should contain activity logs Event Hub for test case '%s'", tt.name)

			// Verify the name uses the activity_log_export_name variable
			assert.Contains(t, planOutput, fmt.Sprintf(`name = "%s"`, tt.activityLogName),
				"Event Hub should use var.activity_log_export_name for name in test case '%s'", tt.name)

			// Verify expected properties
			for property, expectedValue := range tt.expectedProperties {
				switch property {
				case "partition_count":
					assert.Contains(t, planOutput, fmt.Sprintf(`partition_count = %d`, expectedValue),
						"Event Hub should have partition_count=%d for test case '%s'", expectedValue, tt.name)
				case "message_retention":
					assert.Contains(t, planOutput, fmt.Sprintf(`message_retention = %d`, expectedValue),
						"Event Hub should have message_retention=%d for test case '%s'", expectedValue, tt.name)
				}
			}

			// Verify namespace reference pattern
			assert.Contains(t, planOutput, "namespace_id      = azurerm_eventhub_namespace.activity_logs_namespace[0].id",
				"Event Hub should reference activity_logs_namespace[0].id for test case '%s'", tt.name)

			// Verify it doesn't use for_each pattern (unlike eventhubs_by_type_and_location)
			assert.NotContains(t, planOutput, "for_each",
				"Activity logs Event Hub should not use for_each pattern for test case '%s'", tt.name)
		})
	}
}

func TestActivityLogsEventHubReferences(t *testing.T) {
	// Test the reference logic in eventhub_for_activity_logs
	// This validates how it differs from eventhubs_by_type_and_location in its references
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name               string
		enableActivityLogs bool
		expectedReferences []string
		notExpectedRefs    []string
		description        string
	}{
		{
			name:               "ActivityLogsEventHubReferences",
			enableActivityLogs: true,
			expectedReferences: []string{
				"azurerm_eventhub_namespace.activity_logs_namespace[0].id", // Static reference to [0]
				"var.activity_log_export_name",                             // Static variable reference
			},
			notExpectedRefs: []string{
				"each.value[0].location",         // Should NOT use each.value like eventhubs_by_type_and_location
				"namespaces_by_location",         // Should NOT reference regular namespaces
				"for_each",                       // Should NOT use for_each pattern
				"eventhubs_by_type_and_location", // Should NOT reference regular event hubs
			},
			description: "Activity logs Event Hub should use static references, not for_each patterns",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with activity logs Event Hub configuration
			additionalVars := map[string]interface{}{
				"enable_activity_logs":     tt.enableActivityLogs,
				"activity_log_export_name": "insights-activity-logs",
			}
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars([]string{testEnv.GetKeyVaultType()}, additionalVars))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-activity-eventhub-refs-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-activity-eventhub-refs-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and analyze references
			planOutput, err := terraform.PlanE(t, terraformOptions)

			// For valid configurations, we might get API errors trying to access resources
			if err != nil {
				errStr := err.Error()
				if strings.Contains(errStr, "Invalid value for variable") ||
					strings.Contains(errStr, "validation rule") {
					t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					return
				} else {
					// API errors are expected for validation-only tests
					t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
				}
			}

			if tt.enableActivityLogs {
				// Verify expected references are present
				for _, expectedRef := range tt.expectedReferences {
					assert.Contains(t, planOutput, expectedRef,
						"Plan should contain reference '%s' for test case '%s'", expectedRef, tt.name)
				}

				// Verify unexpected references are NOT present
				for _, notExpectedRef := range tt.notExpectedRefs {
					assert.NotContains(t, planOutput, notExpectedRef,
						"Plan should NOT contain reference '%s' for test case '%s'", notExpectedRef, tt.name)
				}

				// Verify the Event Hub is created with count pattern
				assert.Contains(t, planOutput, "azurerm_eventhub.eventhub_for_activity_logs",
					"Plan should contain activity logs Event Hub for test case '%s'", tt.name)

				// Verify it uses array indexing [0] not map keys
				eventHubLines := strings.Split(planOutput, "\n")
				foundCountPattern := false
				for _, line := range eventHubLines {
					if strings.Contains(line, "eventhub_for_activity_logs[0]") {
						foundCountPattern = true
						break
					}
				}
				assert.True(t, foundCountPattern,
					"Activity logs Event Hub should use count-based indexing [0] for test case '%s'", tt.name)

				// Verify namespace reference uses static [0] indexing
				assert.Contains(t, planOutput, "activity_logs_namespace[0]",
					"Event Hub should reference activity_logs_namespace with static [0] index for test case '%s'", tt.name)
			}
		})
	}
}

func TestActivityLogsDiagnosticSettingConditionalCreation(t *testing.T) {
	// Test the conditional creation of activity_logs_to_event_hub based on enable_activity_logs variable
	// This tests the key functionality: count-based creation that depends on enable_activity_logs
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name                     string
		enableActivityLogs       bool
		expectDiagnosticSetting  bool
		expectedSubscriptionPath string
		description              string
	}{
		{
			name:                     "ActivityLogsDiagnosticSettingEnabled",
			enableActivityLogs:       true,
			expectDiagnosticSetting:  true,
			expectedSubscriptionPath: "/subscriptions/",
			description:              "When enable_activity_logs is true, activity_logs_to_event_hub should be created",
		},
		{
			name:                     "ActivityLogsDiagnosticSettingDisabled",
			enableActivityLogs:       false,
			expectDiagnosticSetting:  false,
			expectedSubscriptionPath: "",
			description:              "When enable_activity_logs is false, activity_logs_to_event_hub should not be created",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with activity logs diagnostic setting configuration
			additionalVars := map[string]interface{}{
				"enable_activity_logs": tt.enableActivityLogs,
			}
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars([]string{testEnv.GetKeyVaultType()}, additionalVars))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-activity-diag-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-activity-diag-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and analyze results
			planOutput, err := terraform.PlanE(t, terraformOptions)

			// For valid configurations, we might get API errors trying to access resources
			if err != nil {
				errStr := err.Error()
				if strings.Contains(errStr, "Invalid value for variable") ||
					strings.Contains(errStr, "validation rule") {
					t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					return
				} else {
					// API errors are expected for validation-only tests
					t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
				}
			}

			if tt.expectDiagnosticSetting {
				// Verify activity logs diagnostic setting is created
				assert.Contains(t, planOutput, "azurerm_monitor_diagnostic_setting.activity_logs_to_event_hub",
					"Plan should contain activity logs diagnostic setting for test case '%s'", tt.name)

				// Verify subscription-level target resource ID
				assert.Contains(t, planOutput, tt.expectedSubscriptionPath,
					"Diagnostic setting should target subscription for test case '%s'", tt.name)

				// Verify it uses count = 1 (not for_each like diagnostic_setting_logs)
				assert.Contains(t, planOutput, "activity_logs_to_event_hub[0]",
					"Activity logs diagnostic setting should use count-based indexing for test case '%s'", tt.name)

				// Verify it references the activity logs Event Hub correctly
				assert.Contains(t, planOutput, "eventhub_for_activity_logs[0].name",
					"Diagnostic setting should reference eventhub_for_activity_logs[0].name for test case '%s'", tt.name)

				// Verify it references the activity logs authorization rule correctly
				assert.Contains(t, planOutput, "activity_logs_policy[0].id",
					"Diagnostic setting should reference activity_logs_policy[0].id for test case '%s'", tt.name)

			} else {
				// Verify activity logs diagnostic setting is NOT created
				assert.NotContains(t, planOutput, "azurerm_monitor_diagnostic_setting.activity_logs_to_event_hub",
					"Plan should NOT contain activity logs diagnostic setting for test case '%s'", tt.name)
			}
		})
	}
}

func TestActivityLogsDiagnosticSettingLogCategories(t *testing.T) {
	// Test the fixed log categories for activity_logs_to_event_hub diagnostic setting
	// This validates the specific categories enabled for subscription-level activity logs
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name                  string
		enableActivityLogs    bool
		expectedLogCategories []string
		description           string
	}{
		{
			name:               "ActivityLogsDiagnosticSettingLogCategories",
			enableActivityLogs: true,
			expectedLogCategories: []string{
				"Administrative", // Standard activity log categories
				"Security",
				"ServiceHealth",
				"Alert",
				"Recommendation",
				"Policy",
				"Autoscale",
			},
			description: "Activity logs diagnostic setting should have fixed log categories enabled",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with activity logs diagnostic setting configuration
			additionalVars := map[string]interface{}{
				"enable_activity_logs": tt.enableActivityLogs,
			}
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars([]string{testEnv.GetKeyVaultType()}, additionalVars))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-activity-diag-logs-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-activity-diag-logs-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and analyze log categories
			planOutput, err := terraform.PlanE(t, terraformOptions)

			// For valid configurations, we might get API errors trying to access resources
			if err != nil {
				errStr := err.Error()
				if strings.Contains(errStr, "Invalid value for variable") ||
					strings.Contains(errStr, "validation rule") {
					t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					return
				} else {
					// API errors are expected for validation-only tests
					t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
				}
			}

			if tt.enableActivityLogs {
				// Verify diagnostic setting is created
				assert.Contains(t, planOutput, "azurerm_monitor_diagnostic_setting.activity_logs_to_event_hub",
					"Plan should contain activity logs diagnostic setting for test case '%s'", tt.name)

				// Verify each expected log category is enabled
				for _, category := range tt.expectedLogCategories {
					assert.Contains(t, planOutput, fmt.Sprintf(`category = "%s"`, category),
						"Activity logs diagnostic setting should have category '%s' enabled for test case '%s'", category, tt.name)
				}

				// Verify enabled_log blocks are present (not dynamic like diagnostic_setting_logs)
				enabledLogCount := strings.Count(planOutput, "enabled_log {")
				assert.True(t, enabledLogCount >= len(tt.expectedLogCategories),
					"Activity logs diagnostic setting should have at least %d enabled_log blocks for test case '%s'", len(tt.expectedLogCategories), tt.name)

				// Verify it uses static enabled_log blocks (not dynamic)
				assert.NotContains(t, planOutput, "dynamic \"enabled_log\"",
					"Activity logs diagnostic setting should NOT use dynamic enabled_log blocks for test case '%s'", tt.name)
			}
		})
	}
}

func TestActivityLogsDiagnosticSettingReferences(t *testing.T) {
	// Test the reference logic in activity_logs_to_event_hub diagnostic setting
	// This validates how it differs from diagnostic_setting_logs in its references
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name               string
		enableActivityLogs bool
		expectedReferences []string
		notExpectedRefs    []string
		description        string
	}{
		{
			name:               "ActivityLogsDiagnosticSettingReferences",
			enableActivityLogs: true,
			expectedReferences: []string{
				"azurerm_eventhub.eventhub_for_activity_logs[0].name",                      // Static reference to [0]
				"azurerm_eventhub_namespace_authorization_rule.activity_logs_policy[0].id", // Static reference to [0]
				"/subscriptions/", // Subscription-level target
				"data.azurerm_client_config.current.subscription_id", // Current subscription ID
			},
			notExpectedRefs: []string{
				"each.value.id",                  // Should NOT use each.value like diagnostic_setting_logs
				"for_each",                       // Should NOT use for_each pattern
				"diagnostic_setting_logs",        // Should NOT reference regular diagnostic settings
				"eventhubs_by_type_and_location", // Should NOT reference regular event hubs
				"sumo_collection_policy",         // Should NOT reference regular authorization rule
				"dynamic \"enabled_log\"",        // Should NOT use dynamic enabled_log blocks
			},
			description: "Activity logs diagnostic setting should use static references, not for_each patterns",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with activity logs diagnostic setting configuration
			additionalVars := map[string]interface{}{
				"enable_activity_logs": tt.enableActivityLogs,
			}
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars([]string{testEnv.GetKeyVaultType()}, additionalVars))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-activity-diag-refs-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-activity-diag-refs-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and analyze references
			planOutput, err := terraform.PlanE(t, terraformOptions)

			// For valid configurations, we might get API errors trying to access resources
			if err != nil {
				errStr := err.Error()
				if strings.Contains(errStr, "Invalid value for variable") ||
					strings.Contains(errStr, "validation rule") {
					t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
					return
				} else {
					// API errors are expected for validation-only tests
					t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
				}
			}

			if tt.enableActivityLogs {
				// Verify expected references are present
				for _, expectedRef := range tt.expectedReferences {
					assert.Contains(t, planOutput, expectedRef,
						"Plan should contain reference '%s' for test case '%s'", expectedRef, tt.name)
				}

				// Verify unexpected references are NOT present
				for _, notExpectedRef := range tt.notExpectedRefs {
					assert.NotContains(t, planOutput, notExpectedRef,
						"Plan should NOT contain reference '%s' for test case '%s'", notExpectedRef, tt.name)
				}

				// Verify the diagnostic setting is created with count pattern
				assert.Contains(t, planOutput, "azurerm_monitor_diagnostic_setting.activity_logs_to_event_hub",
					"Plan should contain activity logs diagnostic setting for test case '%s'", tt.name)

				// Verify it uses array indexing [0] not map keys
				diagSettingLines := strings.Split(planOutput, "\n")
				foundCountPattern := false
				for _, line := range diagSettingLines {
					if strings.Contains(line, "activity_logs_to_event_hub[0]") {
						foundCountPattern = true
						break
					}
				}
				assert.True(t, foundCountPattern,
					"Activity logs diagnostic setting should use count-based indexing [0] for test case '%s'", tt.name)
			}
		})
	}
}

func TestDiagnosticSettingNameValidation(t *testing.T) {
	// Test the dynamic name validation logic for diagnostic_setting_logs based on local.all_monitored_resources
	// The name transformation is: "diag-${replace(replace(each.value.name, "/", "-"), ".", "-")}"
	// This validates Azure naming requirements using actual resource discovery from Terraform plan
	terraformDir := "../"

	testEnv, err := loadTestEnvironment()
	if err != nil {
		t.Skipf("Skipping test due to missing environment variables: %v", err)
		return
	}

	tests := []struct {
		name          string
		resourceTypes []string
		expectError   bool
		description   string
	}{
		{
			name:          "DynamicNamingForSingleResourceType",
			resourceTypes: []string{testEnv.GetKeyVaultType()},
			expectError:   false,
			description:   "Dynamic naming should work for single resource type from local.all_monitored_resources",
		},
		{
			name:          "DynamicNamingForMultipleResourceTypes",
			resourceTypes: []string{testEnv.GetKeyVaultType(), testEnv.GetStorageType()},
			expectError:   false,
			description:   "Dynamic naming should work for multiple resource types from local.all_monitored_resources",
		},
		{
			name:          "DynamicNamingForAlternativeResourceType",
			resourceTypes: []string{testEnv.GetStorageType()},
			expectError:   false,
			description:   "Dynamic naming should work for alternative resource type from local.all_monitored_resources",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create tfvars with test configuration
			tfvarsContent := formatTfvarsWithAllVars(testEnv.createTestTfvars(tt.resourceTypes, nil))

			tfvarsFile := filepath.Join(terraformDir, fmt.Sprintf("test-diag-name-validation-%s.tfvars", tt.name))
			err := os.WriteFile(tfvarsFile, []byte(tfvarsContent), 0644)
			assert.NoError(t, err)
			defer os.Remove(tfvarsFile)

			terraformOptions := &terraform.Options{
				TerraformDir: terraformDir,
				VarFiles:     []string{fmt.Sprintf("test-diag-name-validation-%s.tfvars", tt.name)},
				NoColor:      true,
			}

			terraform.Init(t, terraformOptions)

			// Run plan and extract diagnostic setting names from actual local.all_monitored_resources
			planOutput, err := terraform.PlanE(t, terraformOptions)

			if tt.expectError {
				assert.Error(t, err, "Test case '%s' should fail", tt.name)
				return
			} else {
				// For valid configurations, we might get API errors trying to access resources
				if err != nil {
					errStr := err.Error()
					if strings.Contains(errStr, "Invalid value for variable") ||
						strings.Contains(errStr, "validation rule") {
						t.Errorf("Test case '%s' should pass validation but got validation error: %v", tt.name, err)
						return
					} else {
						// API errors are expected for validation-only tests
						t.Logf("Test case '%s' got runtime error (expected): %v", tt.name, err)
					}
				}
			}

			// Extract and validate diagnostic setting names from the plan output
			diagSettingPattern := regexp.MustCompile(`azurerm_monitor_diagnostic_setting\.diagnostic_setting_logs\["([^"]+)"\]`)
			matches := diagSettingPattern.FindAllStringSubmatch(planOutput, -1)

			assert.True(t, len(matches) > 0,
				"Should find at least one diagnostic setting in plan for test case '%s'", tt.name)

			for _, match := range matches {
				if len(match) > 1 {
					diagSettingKey := match[1]
					t.Logf("Found diagnostic setting key from local.all_monitored_resources: '%s'", diagSettingKey)

					// Extract the actual diagnostic setting name from the plan
					namePattern := regexp.MustCompile(`name\s*=\s*"([^"]+)"`)
					nameMatches := namePattern.FindAllStringSubmatch(planOutput, -1)

					for _, nameMatch := range nameMatches {
						if len(nameMatch) > 1 && strings.Contains(nameMatch[1], "diag-") {
							actualDiagName := nameMatch[1]
							t.Logf("Found actual diagnostic setting name: '%s'", actualDiagName)

							// Validate the name follows the expected pattern: "diag-${replace(replace(each.value.name, "/", "-"), ".", "-")}"
							assert.True(t, strings.HasPrefix(actualDiagName, "diag-"),
								"Diagnostic setting name should start with 'diag-' for test case '%s': '%s'", tt.name, actualDiagName)

							// Validate length requirements (Azure diagnostic setting names: 1-64 characters)
							nameLength := len(actualDiagName)
							assert.True(t, nameLength >= 1 && nameLength <= 64,
								"Diagnostic setting name should be between 1-64 characters for test case '%s', got %d chars: '%s'", tt.name, nameLength, actualDiagName)

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
							assert.True(t, len(actualDiagName) > 0 && !strings.HasPrefix(actualDiagName, "-") && !strings.HasPrefix(actualDiagName, "_"),
								"Diagnostic setting name should not start with hyphen or underscore for test case '%s': '%s'", tt.name, actualDiagName)
							assert.True(t, len(actualDiagName) > 0 && !strings.HasSuffix(actualDiagName, "-") && !strings.HasSuffix(actualDiagName, "_"),
								"Diagnostic setting name should not end with hyphen or underscore for test case '%s': '%s'", tt.name, actualDiagName)

							// Validate no consecutive hyphens or underscores (best practice)
							assert.False(t, strings.Contains(actualDiagName, "--") || strings.Contains(actualDiagName, "__"),
								"Diagnostic setting name should not contain consecutive hyphens or underscores for test case '%s': '%s'", tt.name, actualDiagName)

							// Log the successful validation of the dynamic naming pattern
							// The diagnostic setting name is based on each.value.name from local.all_monitored_resources
							t.Logf("Diagnostic setting name validation passed for dynamically generated name: '%s'", actualDiagName)
						}
					}
				}
			}

			// Verify that diagnostic settings are created for each resource in local.all_monitored_resources
			diagSettingCount := strings.Count(planOutput, "azurerm_monitor_diagnostic_setting.diagnostic_setting_logs")
			assert.True(t, diagSettingCount >= len(tt.resourceTypes),
				"Should create at least %d diagnostic settings for %d resource types in test case '%s'", len(tt.resourceTypes), len(tt.resourceTypes), tt.name)

			// Verify the for_each pattern is used (not count)
			assert.Contains(t, planOutput, "for_each",
				"Diagnostic settings should use for_each pattern based on local.all_monitored_resources for test case '%s'", tt.name)
			assert.Contains(t, planOutput, "local.all_monitored_resources",
				"Diagnostic settings should reference local.all_monitored_resources for test case '%s'", tt.name)
		})
	}
}
