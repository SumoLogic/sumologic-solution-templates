# Azure Collection Terraform Module

Terraform module for automated log and metrics collection from Azure resources to Sumo Logic using EventHubs.

## Overview

This module creates a complete data pipeline to collect logs and metrics from Azure resources and send them to Sumo Logic for monitoring and analysis. It automatically:

- Discovers Azure resources based on tags
- Creates EventHub infrastructure per location
- Configures diagnostic settings for log collection
- Sets up Sumo Logic collector

## Architecture

The following diagram illustrates the data flow architecture:

```
Azure Resources → Diagnostic Settings → EventHubs → Sumo Logic Sources → Sumo Logic Apps
```

**Key Components:**
1. **Resource Discovery**: Queries Azure for resources matching specified tags
2. **EventHub Infrastructure**: Creates namespaces and hubs per location
3. **Diagnostic Settings**: Configures log streaming from resources to EventHubs
4. **Sumo Logic Integration**: Sets up collector, log/metric sources, and installs apps

## Terraform Resources

### Azure Resources

#### 1. **azurerm_resource_group.rg**
Creates a resource group to contain all EventHub infrastructure.
- **Purpose**: Logical container for EventHub namespaces and hubs
- **Configuration**: Set via `resource_group_name` and `location` variables
- **Lifecycle**: Managed by Terraform; deletion removes all contained resources

#### 2. **azurerm_eventhub_namespace.namespaces_by_location**
Creates EventHub namespaces, one per unique Azure region where target resources exist.
- **Purpose**: Regional EventHub service for high-performance log streaming
- **Naming**: `{eventhub_namespace}-{location}` (e.g., `sumo-logs-eastus`)
- **SKU**: Configurable via `eventhub_namespace_sku` (default: Standard)
- **Scaling**: Capacity units set via `eventhub_namespace_capacity`

#### 3. **azurerm_eventhub.eventhubs_by_type_and_location**
Creates individual EventHubs for each resource type and location combination.
- **Purpose**: Separate data streams per resource type for organized log collection
- **Naming**: `insights-logs-{resource_type}` per namespace
- **Configuration**: Partition count and message retention configurable
- **Cardinality**: One EventHub per (resource_type × location) combination

#### 4. **azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy**
Creates authorization rules for Sumo Logic to access EventHub namespaces.
- **Purpose**: Secure authentication for Sumo Logic log sources
- **Permissions**: Listen only (read access)
- **Scope**: One per namespace (location-based)
- **Usage**: Connection strings used by Sumo Logic sources

#### 5. **azurerm_monitor_diagnostic_setting.diagnostic_setting_logs**
Attaches diagnostic settings to each target Azure resource for log streaming.
- **Purpose**: Routes resource logs to appropriate EventHub
- **Configuration**: Automatically maps resources to EventHubs based on type and location
- **Log Categories**: Streams all available diagnostic log categories
- **Metrics**: Can optionally include metrics data

#### 6. **azurerm_eventhub_namespace.activity_logs_namespace** (Conditional)
Creates a dedicated namespace for Azure subscription-level activity logs.
- **Purpose**: Separate infrastructure for subscription audit logs
- **Condition**: Created when `enable_activity_logs = true`
- **Isolation**: Keeps subscription logs separate from resource logs
- **Location**: Uses primary subscription region

#### 7. **azurerm_eventhub.eventhub_for_activity_logs** (Conditional)
Creates the EventHub within activity logs namespace.
- **Purpose**: Receives subscription-level activity and audit logs
- **Naming**: `insights-activity-logs`
- **Condition**: Created when `enable_activity_logs = true`
- **Special Use**: Captures subscription-wide operations and changes

#### 8. **azurerm_eventhub_namespace_authorization_rule.activity_logs_policy** (Conditional)
Creates authorization rule for Sumo Logic to access activity logs.
- **Purpose**: Secure authentication for activity log collection
- **Permissions**: Listen only
- **Condition**: Created when `enable_activity_logs = true`

#### 9. **azurerm_monitor_diagnostic_setting.activity_logs_to_event_hub** (Conditional)
Configures subscription-level diagnostic settings to stream activity logs.
- **Purpose**: Routes subscription audit logs to dedicated EventHub
- **Scope**: **Subscription-level** (not resource-level)
- **Condition**: Created when `enable_activity_logs = true`
- **Categories**: Administrative, Security, ServiceHealth, Alert, Recommendation, Policy, Autoscale
- **⚠️ Important**: Azure allows only **ONE** activity log diagnostic setting per subscription
  - Creating this setting will **replace** any existing activity log diagnostic setting
  - Deleting this (via `terraform destroy`) will **remove** activity logs for the **entire subscription**
  - Coordinate with your team to avoid conflicts on shared subscriptions

### SumoLogic Resources

#### 1. **sumologic_collector.sumo_collector**
Creates a hosted collector in Sumo Logic for receiving logs and metrics.
- **Purpose**: Central collection point for all Azure data
- **Type**: Hosted (cloud-based, no agent required)
- **Configuration**: Named via `collector_name` variable
- **Capacity**: Single collector handles all sources

#### 2. **sumologic_azure_event_hub_log_source.sumo_azure_event_hub_log_source**
Creates log sources that consume from EventHubs.
- **Purpose**: Reads logs from EventHubs and ingests into Sumo Logic
- **Cardinality**: One source per EventHub (filtered by log_namespace)
- **Authentication**: Uses connection strings from authorization rules
- **Processing**: Parses Azure diagnostic log JSON format
- **Filtering**: Only created for resources with `log_namespace` defined

#### 3. **sumologic_azure_metrics_source.terraform_azure_metrics_source**
Creates metrics sources for Azure metrics collection via API.
- **Purpose**: Collects metrics directly from Azure Monitor API
- **Cardinality**: One source per unique metric_namespace group
- **Authentication**: Uses configured Azure credentials
- **Polling**: Periodic collection (configurable interval)
- **Filtering**: Only created for resources with `metric_namespace` defined

#### 4. **sumologic_azure_event_hub_log_source.sumo_activity_log_source** (Conditional)
Creates a dedicated source for subscription activity logs.
- **Purpose**: Ingests subscription-level audit and activity logs
- **Condition**: Created when `enable_activity_logs = true`
- **Isolation**: Separate from resource log sources
- **Usage**: Security auditing, compliance, change tracking

#### 5. **sumologic_app.apps** (Optional)
Installs pre-built Sumo Logic apps for visualization and analysis.
- **Purpose**: Provides dashboards, searches, and alerts for Azure services
- **Configuration**: Specified via `installation_apps_list` variable
- **Examples**: Azure SQL, Azure Storage, Azure Kubernetes Service apps
- **Requirement**: Each app requires specific log/metric sources to be configured

### Data Sources

#### 1. **azurerm_client_config.current**
Retrieves current Azure authentication context.
- **Usage**: Gets subscription ID and tenant ID for resource tagging
- **Read-Only**: Does not create resources

#### 2. **azurerm_resources.all_target_resources**
Queries Azure for resources matching specified tags.
- **Purpose**: Discovers target resources for log collection
- **Filter**: Uses `resource_group_name_filter` and `resource_tags` variables
- **Output**: List of resource IDs, types, and locations
- **Dynamic**: Results determine EventHub and diagnostic setting creation

#### 3. **azurerm_monitor_diagnostic_categories.all_categories**
Retrieves available diagnostic categories for each discovered resource.
- **Purpose**: Determines what logs and metrics each resource can export
- **Dynamic**: Queries per discovered resource
- **Usage**: Ensures diagnostic settings enable all available log categories

## Requirements
```

**Key Components:**
1. **Resource Discovery**: Queries Azure for resources matching specified tags
2. **EventHub Infrastructure**: Creates namespaces and hubs per location
3. **Diagnostic Settings**: Configures log streaming from resources to EventHubs
4. **Sumo Logic Integration**: Sets up collector, log/metric sources, and installs apps

## 📁 Configuration Files

- `terraform.tfvars.example` - Template with all variables and detailed documentation
- `terraform.tfvars` - Your actual configuration (customize and keep secure)
- `test/` - Comprehensive test suite with 69 test scenarios

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.19.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |
| <a name="requirement_sumologic"></a> [sumologic](#requirement\_sumologic) | >= 3.0.2 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.7.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.43.0 |
| <a name="provider_sumologic"></a> [sumologic](#provider\_sumologic) | 3.1.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_eventhub.eventhub_for_activity_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) | resource |
| [azurerm_eventhub.eventhubs_by_type_and_location](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) | resource |
| [azurerm_eventhub_namespace.activity_logs_namespace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) | resource |
| [azurerm_eventhub_namespace.namespaces_by_location](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) | resource |
| [azurerm_eventhub_namespace_authorization_rule.activity_logs_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace_authorization_rule) | resource |
| [azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace_authorization_rule) | resource |
| [azurerm_monitor_diagnostic_setting.activity_logs_to_event_hub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.diagnostic_setting_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [sumologic_azure_event_hub_log_source.sumo_activity_log_source](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/azure_event_hub_log_source) | resource |
| [sumologic_azure_event_hub_log_source.sumo_azure_event_hub_log_source](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/azure_event_hub_log_source) | resource |
| [sumologic_azure_metrics_source.terraform_azure_metrics_source](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/azure_metrics_source) | resource |
| [sumologic_collector.sumo_collector](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/collector) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_monitor_diagnostic_categories.all_categories](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/monitor_diagnostic_categories) | data source |
| [azurerm_resources.all_target_resources](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resources) | data source |

## Configuration

### Prerequisites

Before running this module, ensure you have:

1. **Azure**:
   - Active Azure subscription
   - Azure CLI configured and authenticated (`az login`)
   - Required Azure RBAC roles (see [Azure RBAC Requirements](#azure-rbac-requirements) below)

2. **Sumo Logic**:
   - Active Sumo Logic account
   - Access ID and Access Key with permissions to create collectors and sources
   - Admin role recommended for app installation

3. **Terraform**:
   - Terraform >= 1.5.7 installed
   - Azure provider >= 4.19.0
   - Sumo Logic provider >= 3.0.2

### Azure RBAC Requirements

This module uses **Azure CLI authentication** for Terraform operations. The Azure CLI user needs appropriate roles assigned.

#### 🔵 **Required Azure Roles**

**Option A: Single Role (Recommended for Simplicity)** ⭐
```bash
# Assign Contributor role at subscription level
az role assignment create \
  --assignee <user-email> \
  --role "Contributor" \
  --scope "/subscriptions/<subscription-id>"
```

**Option B: Principle of Least Privilege (More Secure)**
```bash
# 1. Reader - For resource discovery
az role assignment create \
  --assignee <user-email> \
  --role "Reader" \
  --scope "/subscriptions/<subscription-id>"

# 2. Contributor - For EventHub infrastructure (specific resource group)
az role assignment create \
  --assignee <user-email> \
  --role "Contributor" \
  --scope "/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>"

# 3. Monitoring Contributor - For diagnostic settings and metrics access
az role assignment create \
  --assignee <user-email> \
  --role "Monitoring Contributor" \
  --scope "/subscriptions/<subscription-id>"
```

**Required Permissions:**
| Operation | Required Permission | Role |
|-----------|-------------------|------|
| Query resources by type/tags | `*/read` | Reader |
| Read diagnostic categories | `Microsoft.Insights/DiagnosticSettings/Read` | Reader |
| Create resource groups | `Microsoft.Resources/subscriptions/resourcegroups/write` | Contributor |
| Create EventHub namespaces | `Microsoft.EventHub/namespaces/*` | Contributor |
| Create EventHubs | `Microsoft.EventHub/namespaces/eventhubs/*` | Contributor |
| Create authorization rules | `Microsoft.EventHub/namespaces/authorizationRules/*` | Contributor |
| Create diagnostic settings | `Microsoft.Insights/DiagnosticSettings/Write` | Monitoring Contributor |
| Activity logs (subscription) | `Microsoft.Insights/DiagnosticSettings/Write` | Monitoring Contributor |
| Read Azure Monitor metrics | `Microsoft.Insights/Metrics/Read` | Monitoring Contributor |

#### ✅ **Verify Your Permissions**

Check your current role assignments:
```bash
# For current CLI user
az role assignment list \
  --assignee $(az account show --query user.name -o tsv) \
  --output table
```

#### 📋 **Authentication**

This module uses **Azure CLI Authentication**:
- Setup: Run `az login` before executing Terraform
- Terraform will use your Azure CLI session for all operations
- Best for: Local development and manual deployments

### Configuration Variables

The following table describes all available configuration variables. For a complete example, see `terraform.tfvars.example`.

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **Azure Authentication** |||||
| `azure_subscription_id` | Azure Subscription ID where resources will be created. If not provided, uses current Azure CLI context. | `string` | `null` | Yes |
| `azure_client_id` | Service Principal Application (client) ID. If not provided, uses Azure CLI context. | `string` | `null` | Yes |
| `azure_client_secret` | Service Principal client secret value. If not provided, uses Azure CLI context. | `string` (sensitive) | `null` | Yes |
| `azure_tenant_id` | Azure Active Directory Tenant ID. If not provided, uses current Azure CLI context. | `string` | `null` | Yes |
| **Azure Infrastructure** |||||
| `resource_group_name` | Name for the new resource group where all Event Hub namespaces will be created. These Event Hubs are used to configure resource logs and activity logs collection sources in Sumo Logic. | `string` | - | **Yes** |
| `eventhub_namespace_name` | Name for the Event Hub namespace (must be globally unique across Azure, 6-50 characters, starts with letter). | `string` | `"SUMO-267667-Hub"` | Yes |
| `eventhub_namespace_sku` | Event Hub SKU tier. Options: `Standard` or `Premium`. | `string` | - | **Yes** |
| `location` | Azure region for resources (must match subscription location). Example: `East US`, `West US 2`, `North Europe`. | `string` | - | **Yes** |
| `policy_name` | Name for the Event Hub authorization policy (1-64 characters, alphanumeric and hyphens only). | `string` | - | **Yes** |
| `throughput_units` | Number of throughput units (processing capacity) for Event Hub Premium tier. Options: `1`, `2`, `4`, `8`, or `16`. | `number` | - | **Yes** |
| **Activity Logs** |||||
| `enable_activity_logs` | Enable/disable subscription-level activity log collection. **Warning**: Affects entire subscription, not just this Terraform workspace. | `bool` | - | **Yes** |
| `activity_log_export_name` | Name for the activity log diagnostic setting (1-128 characters, alphanumeric with underscores, periods, hyphens). | `string` | - | **Yes** |
| `activity_log_export_category` | Source category for activity logs in Sumo Logic. | `string` | - | **Yes** |
| **Resource Targeting** |||||
| `target_resource_types` | List of Azure resource types to monitor. Each object specifies `log_namespace` (for log collection via EventHub) and/or `metric_namespace` (for metrics collection via Azure Monitor API). At least one must be specified per resource type. | `list(object)` | - | **Yes** |
| `required_resource_tags` | Map of tags to filter Azure resources. Only resources with these tags will be monitored. Use empty `{}` to monitor all resources without tag filtering. | `map(string)` | - | **Yes** |
| `nested_namespace_configs` | Map of parent resource types to their child resource types for nested resources (e.g., Storage Accounts → blobServices/fileServices). Use empty `{}` if not monitoring nested resources. | `map(list(string))` | - | **Yes** |
| **Sumo Logic Configuration** |||||
| `sumologic_access_id` | Sumo Logic Access ID from your account preferences. Used for API authentication. | `string` | - | **Yes** |
| `sumologic_access_key` | Sumo Logic Access Key from your account preferences. Used for API authentication. | `string` (sensitive) | - | **Yes** |
| `sumologic_environment` | Sumo Logic deployment region. Options: `us1`, `us2`, `eu`, `au`, `ca`, `de`, `jp`, `in`, `kr`, `fed`. | `string` | - | **Yes** |
| `sumo_collector_name` | Name for the Sumo Logic hosted collector (alphanumeric, hyphens, underscores, max 128 characters). | `string` | - | **Yes** |
| `installation_apps_list` | List of Sumo Logic apps to install automatically. Each app requires `uuid`, `name`, `version`, and optionally `sumologic_partition`. Use empty `[]` to skip app installation. | `list(object)` | - | **Yes** |

#### Variable Examples

**target_resource_types structure:**
```hcl
target_resource_types = [
  {
    log_namespace    = "Microsoft.Sql/servers/databases"       # For logs via EventHub
    metric_namespace = "Microsoft.Sql/servers/databases"       # For metrics via Azure Monitor API
  },
  {
    metric_namespace = "Microsoft.Compute/virtualMachines"     # Metrics only (no logs)
  }
]
```

**nested_namespace_configs structure:**
```hcl
nested_namespace_configs = {
  "Microsoft.Storage/storageAccounts" = [
    "Microsoft.Storage/storageAccounts/blobServices",
    "Microsoft.Storage/storageAccounts/fileServices"
  ]
}
```

**installation_apps_list structure:**
```hcl
installation_apps_list = [
  {
    uuid                = "0f2af8dd-447f-460f-95f7-3c7898a1eb25"
    name                = "Azure SQL"
    version             = "1.0.0"
    sumologic_partition = "sumologic_default"  # Optional, defaults to "sumologic_default"
  }
]
```

#### Important Notes

**Activity Logs - Subscription-Level Warning:**

Activity logs operate at the **Azure subscription level**, not at the resource level. This has important implications:

- **Scope**: Activity logs capture ALL operations across the ENTIRE subscription (all resource groups, all resources)
- **Single Configuration**: Azure only allows **ONE** diagnostic setting for activity logs per subscription
- **Shared Resource**: If multiple Terraform configurations or users enable activity logs on the same subscription, **only the last one applied will be active**
- **Deletion Impact**: Running `terraform destroy` on ANY Terraform configuration that manages activity logs will **delete the subscription-level diagnostic setting**, affecting **ALL** other configurations that depend on it

**Best Practices:**
1. ✅ Enable activity logs in **only ONE** Terraform workspace per subscription
2. ✅ Coordinate with your team to avoid conflicts
3. ✅ Consider managing activity logs separately from resource-level monitoring
4. ⚠️ Be cautious when running `terraform destroy` - it will remove activity log collection for the entire subscription

**Alternative Approach:**
If multiple teams need activity logs, consider:
- Creating a dedicated Terraform configuration for subscription-level resources (activity logs, policies, etc.)
- Using `terraform import` to manage existing activity log settings
- Documenting ownership and avoiding duplicate configurations

## How to Run This Project

### Step 1: Clone and Navigate

```bash
cd azure-collection-terraform
```

### Step 2: Create Configuration File

Create `terraform.tfvars` with your configuration:

```hcl
# Azure Configuration (uses Azure CLI authentication - run 'az login' first)
azure_subscription_id = "your-subscription-id"  # Optional: defaults to current context

# Sumo Logic Configuration
sumologic_access_id      = "your-sumo-access-id"
sumologic_access_key     = "your-sumo-access-key"
sumologic_environment    = "us2"

# Infrastructure Configuration
resource_group_name        = "rg-sumologic-collection"
location                   = "eastus"
collector_name             = "Azure Production Collector"
eventhub_namespace         = "sumo-logs"
eventhub_namespace_sku     = "Standard"

# Resource Discovery
resource_group_name_filter = "rg-production-*"
resource_tags = {
  Environment = "Production"
  Monitoring  = "Enabled"
}

# Target Resources
target_resource_types = [
  {
    log_namespace    = "Microsoft.Sql/servers/databases"
    metric_namespace = "Microsoft.Sql/servers/databases"
  }
]

# Apps to Install
installation_apps_list = [
  {
    uuid    = "0f2af8dd-447f-460f-95f7-3c7898a1eb25"
    name    = "Azure SQL"
    version = "1.0.0"
  }
]

# Activity Logs
enable_activity_logs = true
```

### Step 3: Initialize Terraform

```bash
terraform init
```

This downloads required providers (Azure, Sumo Logic, Random, Time).

### Step 4: Review Plan

```bash
terraform plan
```

Review the resources to be created:
- Resource group for EventHub infrastructure
- EventHub namespaces (one per region)
- EventHubs (one per resource type and location)
- Diagnostic settings for each target resource
- Sumo Logic collector, sources, and apps

### Step 5: Deploy

```bash
terraform apply
```

Type `yes` when prompted. Deployment typically takes 5-10 minutes.

### Step 6: Verify

1. **Azure Portal**:
   - Check resource group contains EventHub namespaces
   - Verify diagnostic settings on target resources
   - Confirm EventHubs are receiving data

2. **Sumo Logic**:
   - Navigate to Manage Data → Collection
   - Verify collector is online
   - Check sources show "Receiving Data"
   - View installed apps in App Catalog

### Step 7: Access Dashboards and Monitors

Access your installed Sumo Logic content:

1. **Dashboards**:
   - Navigate to **Sumo Logic** → **App Catalog**
   - Find your installed apps (e.g., "Azure Application Gateway", "Azure Key Vault")
   - Click on the app name to view pre-built dashboards

2. **Monitors** (Alerts):
   - Navigate to **Sumo Logic** → **Manage Data** → **Monitoring** → **Monitors**
   - Installed apps include monitor templates that you can configure
   - Click **"+ Add"** → **"From Monitor Template"** to create monitors from installed app templates
   - Configure thresholds, notification channels, and alert conditions
   - Example monitors: High error rate, Resource unavailability, Performance degradation

3. **Content Location**:
   - All app content (dashboards, searches, monitors) is installed in your **Personal** folder by default
   - You can move content to **Admin Recommended** folder for team-wide access
   - Path: **Personal** → **[App Name]** (e.g., Personal → Azure Application Gateway)

**💡 Tip**: Monitor templates provide pre-configured alerting for common issues. Customize thresholds based on your environment.

## Outputs

After deployment, Terraform outputs:

| Output | Description |
|--------|-------------|
| `collector_id` | Sumo Logic collector ID |
| `eventhub_namespace_ids` | Map of EventHub namespace IDs by location |
| `eventhub_ids` | List of created EventHub IDs |
| `log_source_ids` | List of Sumo Logic log source IDs |
| `metrics_source_ids` | List of Sumo Logic metrics source IDs |
| `resource_group_id` | Azure resource group ID |
| `diagnostic_setting_ids` | Map of diagnostic setting IDs by resource |

## Testing

This module includes comprehensive tests to validate both the Terraform configuration and the Azure/SumoLogic integration.

### Test Structure

- **`test/azure_test.go`**: Integration tests that validate Azure resource creation and configuration
- **`test/sumologic_test.go`**: Integration tests that validate SumoLogic resource configuration  
- **`test/basic_test.go`**: Basic Terraform syntax validation tests
- **`test/diagnostic_setting_naming_test.go`**: Unit tests for Azure diagnostic setting naming logic
- **`test/resource_type_parsing_test.go`**: Unit tests for resource type parsing and environment variable handling

### Running Tests

#### Quick Unit Tests (Fast - ~2 seconds)
```bash
cd test
go test -v -run "TestResourceTypesParsing|TestTestEnvironmentHelperMethods|TestDiagnosticSettingNaming|TestBasicSyntax" -timeout 30s
```

#### Full Integration Tests (Requires Azure credentials - ~10-30 minutes)
```bash
cd test
go test -v -timeout 30m
```

#### Specific Test Categories
```bash
# Unit tests only
go test -v -run "TestResourceTypesParsing|TestDiagnosticSettingNaming"

# Basic validation tests
go test -v -run "TestBasicSyntax|TestBasicTerraformVariableValidation"

# Azure integration tests
go test -v -run "TestAzure.*"

# SumoLogic integration tests  
go test -v -run "TestSumoLogic.*"
```

### Test Configuration

Tests use environment variables from `.env.test` file. Copy `.env.test.example` to `.env.test` and configure:

#### Required Azure Configuration
```bash
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_CLIENT_ID=your-client-id
AZURE_CLIENT_SECRET=your-client-secret
AZURE_TENANT_ID=your-tenant-id
```

#### Required SumoLogic Configuration
```bash
SUMOLOGIC_ENVIRONMENT=us1
SUMOLOGIC_ACCESS_ID=your-access-id
SUMOLOGIC_ACCESS_KEY=your-access-key
```

#### Target Resource Types (Unified Format)
The `TARGET_RESOURCE_TYPES` variable supports multiple formats:

```bash
# JSON Array Format (Recommended)
TARGET_RESOURCE_TYPES=["Microsoft.KeyVault/vaults","Microsoft.Storage/storageAccounts"]

# Comma-separated Format
TARGET_RESOURCE_TYPES=Microsoft.KeyVault/vaults,Microsoft.Storage/storageAccounts

# Single Resource Type
TARGET_RESOURCE_TYPES=["Microsoft.KeyVault/vaults"]
```

#### Test Control Flags
```bash
RUN_INTEGRATION_TESTS=true    # Enable integration tests
CLEANUP_RESOURCES=true        # Auto-cleanup test resources
```

### Test Features

- **✅ Unified Resource Type Parsing**: Tests validate flexible parsing of `TARGET_RESOURCE_TYPES`
- **✅ Diagnostic Setting Naming**: Tests ensure Azure naming compliance with SumoLogic conventions
- **✅ Backward Compatibility**: Tests verify helper methods maintain compatibility with legacy variable names
- **✅ Environment Validation**: Tests validate all required environment variables and configurations
- **✅ Azure Resource Discovery**: Tests validate dynamic discovery of Azure resources
- **✅ SumoLogic Integration**: Tests validate proper SumoLogic collector and source configuration

## Troubleshooting

### Common Issues

**Issue**: `Error creating diagnostic settings - resource already has a diagnostic setting`
- **Solution**: Each Azure resource can have a limited number of diagnostic settings. Check existing settings or use `terraform import` for existing configurations.

**Issue**: `EventHub throughput exceeded`
- **Solution**: Increase `eventhub_namespace_capacity` or upgrade to Premium SKU for higher throughput.

**Issue**: `Sumo Logic sources show "Not Receiving Data"`
- **Solution**: 
  1. Verify diagnostic settings are active in Azure Portal
  2. Check EventHub is receiving messages
  3. Confirm authorization rules have Listen permission
  4. Verify Sumo Logic connection string is correct

### Debugging

Enable detailed logs:
```bash
# Terraform debugging
export TF_LOG=DEBUG
terraform apply

# Azure CLI debugging
az account show --debug
```

Check EventHub metrics in Azure Portal:
- Monitor → Metrics → Select EventHub namespace
- View "Incoming Messages" and "Outgoing Messages"

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**⚠️ Warning**: This will:
- Delete all EventHub namespaces and hubs
- Remove diagnostic settings from Azure resources
- Delete Sumo Logic collector and all sources
- Remove installed Sumo Logic apps
- **Remove subscription-level activity log diagnostic settings** (if `enable_activity_logs = true`)
  - This affects the **ENTIRE subscription**, not just resources managed by this Terraform configuration
  - Other monitoring solutions or Terraform workspaces relying on activity logs will be impacted

**💡 To safely remove activity logs before destroying:**
```bash
# Step 1: Disable activity logs in your terraform.tfvars
# Change: enable_activity_logs = true
# To:     enable_activity_logs = false

# Step 2: Apply the change (this removes only activity logs, keeps everything else)
terraform apply

# Step 3: Now safely destroy the rest
terraform destroy
```

Data in Sumo Logic will be retained based on your retention policy.