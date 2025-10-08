# Azure Collection Terraform Tests 🧪

This directory contains comprehensive tests for the Azure Collection Terraform module using a clean, tfvars-based approach.

## 🚀 Quick Start

### Prerequisites
- [Go 1.19+](https://golang.org/dl/) installed
- No additional setup required for validation tests!

### Run Tests
```bash
# List all available tests
go test -list .

# Run all tests (validates Terraform configurations)
go test -v -timeout 15m

# Run specific test categories
go test -v -run TestAzure -timeout 15m      # Azure infrastructure tests
go test -v -run TestSumoLogic -timeout 15m  # SumoLogic configuration tests
go test -v -run TestEventHub -timeout 15m   # EventHub configuration tests

# Run a specific test
go test -v -run TestAzureCredentialsFormatValidation -timeout 5m
```

**Note:** Tests can run in two modes:
- **Validation Mode:** Tests Terraform configuration validation without real credentials (default)
- **Integration Mode:** Tests against real Azure resources when `test.tfvars` contains actual credentials

## 📋 Test Suite Overview

Our test suite includes **69 comprehensive test scenarios** across **20 test functions** covering:

### 🔵 Azure Infrastructure Tests (`azure_test.go`)
- **TestAzureSubscriptionIDValidation** - Azure subscription ID format validation
- **TestEventHubNamespaceNameValidation** - EventHub namespace naming rules
- **TestThroughputUnitsValidation** - Throughput units range validation (1-20)
- **TestAzureResourceTypeFormatValidation** - Azure resource type format validation
- **TestEventHubNamespaceAuthorizationRulePermissions** - Authorization rule permissions
- **TestBasicTerraformConfiguration** - Basic Terraform configuration validation
- **TestEventHubNamespaceNamingConventions** - Location name transformations
- **TestEventHubNamingConventions** - Event Hub naming conventions
- **TestAzureCredentialsValidation** - Azure credentials validation
- **TestAzureCredentialsFormatValidation** - Azure credentials format validation ✨
- **TestResourceGroupNameValidation** - Resource group naming validation

### 🟢 SumoLogic Configuration Tests (`sumologic_test.go`)
- **TestSumoLogicResourceTypesValidation** - Resource types validation
- **TestSumoLogicCollectorResourceConfiguration** - Collector configuration
- **TestSumoLogicEventHubLogSourceConfiguration** - Event Hub log source setup
- **TestSumoLogicActivityLogSourceConfiguration** - Activity log source setup
- **TestSumoLogicAzureMetricsSourceConfiguration** - Azure metrics source setup
- **TestSumoLogicSourceNamingConventions** - Source naming conventions
- **TestSumoLogicAppValidationPatterns** - App validation patterns
- **TestSumoLogicAppsInstallationPlanValidation** - App installation validation ✨
- **TestSumoLogicCollectorNameValidation** - Collector name validation ✨

✨ = Recently integrated validation tests

## 📁 Test Structure

### Configuration Files
- `test.tfvars.example` - Template showing all required variables  
- `test.tfvars` - Working test configuration (copy from example and customize)

### Base+Override Architecture
Our tests use a **base+override pattern** for maximum efficiency:
- **Base Configuration:** `test.tfvars` contains all common variables with working values
- **Override Fixtures:** Individual fixture files override only specific variables being tested
- **Terraform Command:** `terraform plan -var-file test/test.tfvars -var-file test/fixtures/specific-test.tfvars`
- **Benefits:** DRY principles, easy maintenance, isolated test scenarios

### Test Fixtures (`fixtures/` directory)
**31 specialized tfvars files** for testing specific validation scenarios:

#### Baseline Configuration
- `valid-config.tfvars` - Uses all base configuration values (no overrides)

#### Azure Credential Validation  
- `invalid-subscription.tfvars` - Invalid Azure subscription ID format
- `invalid-client-id.tfvars` - Invalid Azure client ID format
- `invalid-tenant-id.tfvars` - Invalid Azure tenant ID format
- `empty-client-id.tfvars` - Empty Azure client ID
- `empty-tenant-id.tfvars` - Empty Azure tenant ID

#### Azure Infrastructure Validation
- `invalid-namespace.tfvars` - Event Hub namespace name validation
- `invalid-throughput.tfvars` - Throughput units above maximum
- `below-min-throughput.tfvars` - Throughput units below minimum  
- `min-throughput.tfvars` - Minimum valid throughput units (1)
- `max-throughput.tfvars` - Maximum valid throughput units (20)
- `invalid-resource-types.tfvars` - Invalid Azure resource type formats
- `invalid-resource-group-*.tfvars` - Resource group naming validation (6 scenarios)
- `activity-logs-enabled.tfvars` - Activity logs configuration testing
- `activity-logs-disabled.tfvars` - Activity logs disabled testing
- `eventhub-test-config.tfvars` - Event Hub configuration testing

#### SumoLogic Configuration Validation
- `sumo-valid-apps.tfvars` - Valid SumoLogic app configuration
- `sumo-invalid-*.tfvars` - Invalid app configurations (UUID, version, empty fields)
- `sumo-collector-*.tfvars` - Collector naming validation scenarios
- `sumo-*-collector-*.tfvars` - Various collector configuration tests

### Test Files
- `azure_test.go` - Azure infrastructure and credentials validation tests
- `sumologic_test.go` - SumoLogic configuration and validation tests

## 🎯 Test Approach

### Validation Testing
- Uses actual Terraform `plan` commands to test variable validation
- Distinguishes between validation errors (expected) and API errors (acceptable for testing)
- Each test case uses a specific tfvars file to isolate the test scenario

### Advantages of tfvars-based Testing
1. **Simple and Clean** - No complex environment variable setup
2. **Standard Practice** - Follows Terraform testing conventions
3. **Easy Maintenance** - Single source of truth for variable values
4. **Type Safety** - Terraform handles type validation natively
5. **Isolated Test Cases** - Each scenario has its own tfvars file
6. **No Dependencies** - Works without Azure/SumoLogic credentials for validation tests

## ✅ Key Features Tested

- **Unified Resource Type Parsing**: Multiple input formats supported
- **Azure Diagnostic Settings**: Naming compliance and validation  
- **Terraform Variable Validation**: Input validation rules testing
- **Azure Resource Discovery**: Dynamic resource detection
- **SumoLogic Integration**: Collector and source configuration
- **Terraform Configuration Validation**: Syntax and configuration validation

## 🧪 Manual Testing Steps

### For Real Azure/SumoLogic Environment Testing

If you want to test against actual resources (optional - validation tests work without credentials):

1. **Prepare test configuration**:
   ```bash
   # Copy the example tfvars file
   cp test.tfvars.example test.tfvars
   ```

2. **Configure Azure credentials** in `test.tfvars`:
   ```hcl
   # Azure Configuration
   azure_subscription_id = "your-subscription-id"
   azure_tenant_id       = "your-tenant-id" 
   azure_client_id       = "your-client-id"
   azure_client_secret   = "your-client-secret"
   location              = "East US"
   resource_group_name   = "test-resource-group"
   ```

3. **Configure SumoLogic credentials** in `test.tfvars`:
   ```hcl
   # SumoLogic Configuration
   sumo_access_id    = "your-access-id"
   sumo_access_key   = "your-access-key"
   sumo_environment  = "us2"  # or your environment
   ```

4. **Set target resources** in `test.tfvars`:
   ```hcl
   # Resources to collect from
   target_resource_types = [
     "Microsoft.KeyVault/vaults",
     "Microsoft.Storage/storageAccounts"
   ]
   ```

5. **Run manual terraform commands** to test:
   ```bash
   # Initialize terraform
   terraform init
   
   # Validate configuration
   terraform validate
   
   # Plan with your test config
   terraform plan -var-file="test.tfvars"
   
   # Apply if you want to create real resources (optional)
   terraform apply -var-file="test.tfvars"
   ```

### Getting Azure Credentials

1. **Azure Portal** → **App Registrations** → **New registration**
2. Note the **Application (client) ID** and **Directory (tenant) ID**
3. **Certificates & secrets** → **New client secret** → Copy the value
4. **Subscriptions** → Select your subscription → **Access control (IAM)** → **Add role assignment**
5. Assign **Contributor** role to your app registration

### Getting SumoLogic Credentials

1. **SumoLogic Console** → **Administration** → **Security** → **Access Keys**
2. **Add Access Key** → Note the **Access ID** and **Access Key**

## 🐛 Troubleshooting

### "go: command not found"
Install Go from https://golang.org/dl/ or use a package manager:
- macOS: `brew install go`
- Ubuntu: `sudo apt install golang-go`

### "terraform: command not found"
Install Terraform from https://terraform.io/downloads or:
- macOS: `brew install terraform`
- Ubuntu: `sudo apt install terraform`

### Test failures with "validation failed"
This is expected behavior for validation tests - they're designed to fail with invalid configurations to verify validation rules work correctly.

### Authentication errors during manual testing
- Verify your Azure credentials in `test.tfvars`
- Ensure your Azure app has proper permissions on the subscription
- Check that your SumoLogic access key is active and has proper permissions
