# Azure Collection Terraform Tests

Comprehensive test suite for Azure Collection Terraform module with 20 test functions covering 69 scenarios.

## Prerequisites

- Go 1.21+
- Terraform
- Azure CLI (for integration tests)

## Quick Start

```bash
# Run all validation tests
go test -v -timeout 15m

# Run specific test categories
go test -v -run TestAzure -timeout 15m      
go test -v -run TestSumoLogic -timeout 15m  

# Run integration tests (requires credentials)
go test -v -run TestAzureCollectionIntegration -timeout 60m
```

```

## Test Categories

### Azure Infrastructure Tests (`azure_test.go`)

**Purpose:** Validate Azure resource configuration, naming conventions, and credential formats.

| Test | Purpose |
|------|---------|
| `TestAzureSubscriptionIDValidation` | Validates Azure subscription ID format (UUID) |
| `TestEventHubNamespaceNameValidation` | Tests EventHub namespace naming rules (6-50 chars, alphanumeric) |
| `TestThroughputUnitsValidation` | Validates throughput units range (1-20) |
| `TestAzureResourceTypeFormatValidation` | Tests Azure resource type format (Microsoft.Service/Type) |
| `TestEventHubNamespaceAuthorizationRulePermissions` | Verifies authorization rule permissions (listen, send) |
| `TestBasicTerraformConfiguration` | Validates basic Terraform configuration structure |
| `TestEventHubNamespaceNamingConventions` | Tests location name transformations (e.g., "East US" → "eastus") |
| `TestEventHubNamingConventions` | Validates Event Hub naming based on resource types |
| `TestAzureCredentialsValidation` | Tests Azure API authentication with credentials |
| `TestAzureCredentialsFormatValidation` | Validates Azure credential format validation rules |
| `TestResourceGroupNameValidation` | Tests resource group naming rules (1-90 chars, no special chars) |

### SumoLogic Configuration Tests (`sumologic_test.go`)

**Purpose:** Validate SumoLogic resource configuration, app installation, and collector setup.

| Test | Purpose |
|------|---------|
| `TestSumoLogicResourceTypesValidation` | Validates resource type configurations and namespace mappings |
| `TestSumoLogicCollectorResourceConfiguration` | Tests collector resource creation and field assignments |
| `TestSumoLogicEventHubLogSourceConfiguration` | Validates Event Hub log source authentication and path configuration |
| `TestSumoLogicActivityLogSourceConfiguration` | Tests activity log source setup (enabled/disabled scenarios) |
| `TestSumoLogicAzureMetricsSourceConfiguration` | Validates Azure metrics source with authentication and tag filters |
| `TestSumoLogicSourceNamingConventions` | Tests source naming transformations (slashes to hyphens) |
| `TestSumoLogicAppValidationPatterns` | Validates app installation parameters (UUID, version, name) |
| `TestSumoLogicAppsInstallationPlanValidation` | Tests app installation configuration validation |
| `TestSumoLogicCollectorNameValidation` | Validates collector naming rules (alphanumeric, hyphens, underscores) |

### Integration Test (`integration_test.go`)

**Purpose:** End-to-end validation with actual resource creation in Azure and Sumo Logic.

| Test | Purpose |
|------|---------|
| `TestAzureCollectionIntegration` | Creates real resources, validates deployment, verifies app installation, and cleans up |

**Phases:**
1. **Terraform Apply** - Creates Azure EventHubs, diagnostic settings, and Sumo Logic collector/sources
2. **Azure Verification** - Validates resource groups, EventHub namespaces, and EventHubs using Azure CLI
3. **SumoLogic Verification** - Validates collector, log sources, metrics sources, and installed apps
4. **Cleanup** - Destroys all created resources and handles app uninstallation scenarios

4. **Cleanup** - Destroys all created resources and handles app uninstallation scenarios

## Running Tests

### Validation Tests (No Credentials Required)

```bash
cd test

# Run all validation tests
go test -v -timeout 15m

# Run Azure-specific tests
go test -v -run TestAzure -timeout 15m

# Run SumoLogic-specific tests
go test -v -run TestSumoLogic -timeout 15m

# Run a single test
go test -v -run TestResourceGroupNameValidation
```

### Integration Tests (Requires Credentials)

**1. Configure test.tfvars:**

```hcl
# Azure credentials
azure_subscription_id = "your-subscription-id"
azure_client_id       = "your-client-id"
azure_client_secret   = "your-client-secret"
azure_tenant_id       = "your-tenant-id"

# SumoLogic credentials
sumologic_access_id   = "your-access-id"
sumologic_access_key  = "your-access-key"
sumologic_environment = "us1"

# IMPORTANT: Must be false for integration tests
enable_activity_logs = false

# IMPORTANT (tests only): To allow automated cleanup of Resource Groups that
# may still contain nested resources, set the provider safety toggle to false
# in your test tfvars. This sets the azurerm provider feature
# `resource_group.prevent_deletion_if_contains_resources = false` and allows
# tests to remove test resource groups during teardown.
prevent_deletion_if_contains_resources = false

# Resources to test
target_resource_types = [
  {
    log_namespace    = "Microsoft.KeyVault/vaults"
    metric_namespace = "Microsoft.KeyVault/vaults"
  },
  {
    log_namespace    = "Microsoft.Storage/storageAccounts"
    metric_namespace = "Microsoft.Storage/storageAccounts"
  }
]
```

**2. Run integration test:**

```bash
go test -v -run TestAzureCollectionIntegration -timeout 60m
```

**Expected Duration:** 4-6 minutes
- Terraform apply: ~90 seconds
- Resource verification: ~15 seconds
- Resource cleanup: ~2-4 minutes

## Test Architecture

### Base + Override Pattern

Tests use a two-layer configuration approach:

1. **Base Config** (`test.tfvars`) - Contains all common variables with working values
2. **Override Fixtures** (`fixtures/*.tfvars`) - Override specific variables for each test scenario

**Example:**
```bash
terraform plan -var-file test/test.tfvars -var-file test/fixtures/invalid-namespace.tfvars
```

### Test Fixtures

31 fixture files in `fixtures/` directory for testing specific scenarios:

- **Azure Credentials:** `invalid-subscription.tfvars`, `invalid-client-id.tfvars`, `invalid-tenant-id.tfvars`
- **EventHub:** `invalid-namespace.tfvars`, `invalid-throughput.tfvars`, `min-throughput.tfvars`
- **Resource Groups:** `invalid-resource-group-*.tfvars` (6 scenarios)
- **SumoLogic:** `sumo-valid-apps.tfvars`, `sumo-invalid-*.tfvars`, `sumo-collector-*.tfvars`
- **Activity Logs:** `activity-logs-enabled.tfvars`, `activity-logs-disabled.tfvars`

## Troubleshooting

### Validation Test Failures
Expected behavior - validation tests intentionally fail with invalid configurations to verify validation rules.

### Integration Test Issues

**"terraform apply failed with non-app errors"**
- Verify Azure credentials have Contributor access
- Check Azure subscription ID is correct
- Ensure resource quotas not exceeded

**"Could not verify diagnostic settings"**
- This is informational - test continues and passes
- Common due to limited Azure permissions
- Focus on Phases 1-3 verification

**App Installation Errors**
- "App Already Installed" - Normal, handled gracefully
- "App Not Found" during cleanup - Normal, handled gracefully

### Prerequisites Missing

```bash
# Install Go
brew install go  # macOS
sudo apt install golang-go  # Ubuntu

# Install Terraform
brew install terraform  # macOS
sudo apt install terraform  # Ubuntu

# Install Azure CLI (for integration tests)
brew install azure-cli  # macOS
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash  # Ubuntu
```

## Key Features

- **69 test scenarios** across 20 test functions
- **No credentials required** for validation tests
- **Isolated test cases** using fixture overrides
- **End-to-end integration** testing with real resources
- **Automatic cleanup** prevents resource drift
- **App installation** error handling for realistic scenarios

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

## � Integration Tests

### What Integration Tests Do

The **Integration Tests** provide comprehensive end-to-end validation by:

1. **Real Resource Creation**: Creates actual Azure and Sumo Logic resources
2. **Infrastructure Verification**: Verifies all Azure resources are properly created (Resource Groups, EventHubs, Diagnostic Settings)
3. **Sumo Logic Validation**: Confirms Sumo Logic collectors, sources, and apps are successfully installed
4. **App Installation Testing**: Tests Sumo Logic app installation with graceful error handling for common scenarios
5. **Resource Cleanup**: Automatically destroys all resources after testing to prevent resource drift

### How Integration Tests Work

The integration test follows a **4-phase verification approach**:

#### Phase 1: Terraform Apply with App Scenario Handling
- Applies the complete Terraform configuration
- Handles app installation scenarios gracefully:
  - **"App Already Installed"** scenario: Logs as informational, continues test
  - **"App Not Found"** during destroy: Treated as successful cleanup
- Uses unique resource names to avoid conflicts

#### Phase 2: Azure Resource Verification
- **Resource Group Validation**: Uses `az group show` to verify resource group creation
- **EventHub Namespace Validation**: Confirms EventHub namespace exists and is properly configured
- **EventHub Validation**: Verifies individual EventHubs for each target service (KeyVault, Storage)
- **JSON Parsing**: Parses Azure CLI JSON responses for detailed resource validation

#### Phase 3: Sumo Logic Resource Verification
- **Collector Validation**: Verifies Sumo Logic collector ID format and existence
- **Log Sources Validation**: Confirms log sources for each Azure service type
- **Metrics Source Validation**: Validates metrics source configuration
- **App Installation Status**: Verifies installed apps and their metadata (ID, UUID, version)

#### Phase 4: Diagnostic Settings Validation
- **Diagnostic Settings Check**: Validates Azure diagnostic settings configuration
- **Graceful Error Handling**: Handles permission issues without failing the test
- **Resource-Specific Validation**: Checks diagnostic settings for each target resource type

### How to Run Integration Tests

#### Prerequisites
- **Go 1.19+** installed
- **Azure CLI** installed and authenticated (`az login`)
- **Valid Azure credentials** with sufficient permissions
- **Valid Sumo Logic credentials** (Access ID/Key)
- **Terraform** installed

#### Running Integration Tests

```bash
# Navigate to the test directory
cd azure-collection-terraform/test

# Compile test to verify code correctness
go test -c -o /dev/null .

# Run the full integration test (60-minute timeout)
go test -v -run TestAzureCollectionIntegration -timeout 60m

# Run with extended timeout for slow environments
go test -v -run TestAzureCollectionIntegration -timeout 120m

# Run in background and capture output
go test -v -run TestAzureCollectionIntegration -timeout 60m > integration_test.log 2>&1 &
```

#### Configuration Requirements

**Essential Configuration in `test.tfvars`:**

```hcl
# Azure Authentication (REQUIRED)
azure_subscription_id = "your-azure-subscription-id"
azure_client_id       = "your-azure-client-id"  
azure_client_secret   = "your-azure-client-secret"
azure_tenant_id       = "your-azure-tenant-id"

# Sumo Logic Authentication (REQUIRED)
sumologic_access_id   = "your-sumologic-access-id"
sumologic_access_key  = "your-sumologic-access-key"
sumologic_environment = "us1"  # or your environment

# Activity Logs (MUST BE FALSE for integration tests) 
enable_activity_logs = false

# Resource Configuration
resource_group_name     = "SUMO-267667-INTEGRATION-TEST"          
location               = "East US"
eventhub_namespace_name = "SUMO-267667-EventHub-test"

# Target Resources (customize as needed)
target_resource_types = [
  "Microsoft.KeyVault/vaults", 
  "Microsoft.Storage/storageAccounts"
]

# App Installation (optional - tests app installation scenarios)
installation_apps_list = [{
  uuid       = "53376d23-2687-4500-b61e-4a2e2a119658"
  name       = "Azure Storage"
  version    = "1.0.3"
  parameters = {
    "index_value" = "sumologic_default"
  }
},{
  uuid       = "449c796e-5da2-47ea-a304-e9299dd7435d"
  name       = "Azure Key Vault"
  version    = "1.0.2"
  parameters = {
    "index_value" = "sumologic_default"
  }
}]
```

### Important Configuration Notes

#### ⚠️ Activity Logs Must Be Disabled
```hcl
# CRITICAL: Always keep this FALSE for integration tests
enable_activity_logs = false
```
**Why?** Activity logs require subscription-level permissions and can cause permission issues during testing. Integration tests focus on resource-level collection which provides comprehensive coverage without subscription-level complexity.

#### 🔧 Resource Naming Strategy
The integration test uses **unique timestamps** to avoid resource conflicts:
- Base resource names from `test.tfvars`
- Unique suffix: `SumoTestActivityLogExport-{timestamp}`
- Example: `SumoTestActivityLogExport-1760117955765`

#### 🧹 Automatic Cleanup
- **Deferred Cleanup**: Resources are automatically destroyed even if test fails
- **App Uninstallation**: Handles app removal gracefully
- **Diagnostic Settings**: Cleans up diagnostic settings (may take 30+ seconds)
- **Resource Group**: Final resource group deletion (may take 60+ seconds)

### Expected Test Output

```bash
=== RUN   TestAzureCollectionIntegration
🚀 Starting Comprehensive Azure Collection Integration Test...
📦 Applying Terraform configuration...
📋 Retrieving Terraform outputs...
📊 Terraform Outputs Retrieved:
  - Resource Group: SUMO-267667-INTEGRATION-TEST
  - EventHub Namespace: SUMO-267667-EventHub-test-eastus
  - Collector ID: 315439296
  - Metrics Source ID: 1926325955
🔍 Phase 1: Verifying Azure Resources...
✅ Resource Group 'SUMO-267667-INTEGRATION-TEST' verified
✅ EventHub Namespace 'SUMO-267667-EventHub-test-eastus' verified
✅ All 2 EventHubs verified: [eventhub-Microsoft.KeyVault-vaults-eastus eventhub-Microsoft.Storage-storageAccounts-eastus]
🔍 Phase 2: Verifying Sumo Logic Resources...
✅ Sumo Logic Collector ID '315439296' format verified
✅ Log Source 'Microsoft.KeyVault/vaults-eastus' ID '1926326432' verified
✅ Log Source 'Microsoft.Storage/storageAccounts-eastus' ID '1926326431' verified
✅ Sumo Logic Metrics Source ID '1926325955' verified
🔍 Phase 3: Verifying App Installation Status...
📱 App Output 'installed_apps': map[Azure Key Vault:map[id:CCE79A73F589535D name:Azure Key Vault uuid:449c796e-5da2-47ea-a304-e9299dd7435d] Azure Storage:map[id:CCE79A7397895258 name:Azure Storage uuid:53376d23-2687-4500-b61e-4a2e2a119658]]
✅ App installation status verified
🔍 Phase 4: Verifying Diagnostic Settings...
⚠️  Could not verify diagnostic settings: exit status 2
✅ All integration tests passed successfully!
🧹 Starting resource cleanup...
✅ Terraform resources destroyed successfully
✅ Resource cleanup completed
--- PASS: TestAzureCollectionIntegration (278.94s)
PASS
```

### App Installation Scenario Handling

The integration test includes sophisticated **app installation error handling**:

#### Scenario 1: App Already Installed
```
📱 App Installation Scenarios Detected:
  - App Already Installed: App is already installed manually or via another process
ℹ️  All errors are valid app installation scenarios, continuing with infrastructure validation
```

#### Scenario 2: App Not Found During Cleanup
```
📱 App Uninstallation Scenarios Detected:
  - App Already Uninstalled: App was already uninstalled manually (not found in Sumo Logic)
ℹ️  All errors are valid app uninstallation scenarios (apps already removed manually)
```

### Performance Expectations

- **Total Test Time**: 4-6 minutes
- **Terraform Apply**: 60-90 seconds
- **Resource Verification**: 10-15 seconds
- **App Installation**: 30-45 seconds per app
- **Resource Cleanup**: 2-4 minutes (diagnostic settings cleanup is slow)

### Integration Test Benefits

1. **Real Environment Validation**: Tests against actual Azure and Sumo Logic APIs
2. **End-to-End Coverage**: Validates the complete infrastructure deployment workflow
3. **App Installation Testing**: Verifies Sumo Logic app installation with realistic error handling
4. **Automated Cleanup**: Prevents resource drift and cost accumulation
5. **CI/CD Ready**: Designed for automated pipeline integration
6. **Comprehensive Logging**: Detailed output for troubleshooting and verification

## �🐛 Troubleshooting

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

### Integration Test Troubleshooting

#### "terraform apply failed with non-app errors"
- **Check Azure Permissions**: Ensure your Azure service principal has Contributor access
- **Verify Subscription**: Confirm the subscription ID is correct and accessible
- **Check Resource Quotas**: Ensure you haven't exceeded Azure resource limits

#### "Failed to find Azure Resource Group" 
- **Permission Issue**: Your Azure service principal may lack access to the resource group
- **Region Issue**: Ensure the location matches your Azure subscription's available regions
- **Timing Issue**: Rarely, Azure resources may need a few seconds to become available

#### "Could not verify diagnostic settings"
This is **expected behavior** in many environments due to:
- Limited Azure permissions for diagnostic settings queries
- The test continues and passes - this is informational only
- Focus on resource creation verification (Phases 1-3)

#### Integration Test Hanging
- **Azure API Throttling**: Azure may throttle API calls during resource creation
- **Network Issues**: Check your internet connection and Azure service health
- **Increase Timeout**: Use `-timeout 120m` for slower environments

#### App Installation Failures
```bash
# If you see app-related errors, check:
📱 App Installation Scenarios Detected:
  - App Already Installed: This is NORMAL and expected
  - App Not Found: This is NORMAL during cleanup
```
These scenarios are **handled gracefully** and should not cause test failures.

````
