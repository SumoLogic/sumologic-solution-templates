# Azure Collection Terraform Module

Terraform module for automated log and metrics collection from Azure resources to Sumo Logic using EventHubs.

## Overview

This module creates a complete data pipeline to collect logs and metrics from Azure resources and send them to Sumo Logic for monitoring and analysis. It automatically:

- Discovers Azure resources based on tags
- Creates EventHub infrastructure per location
- Configures diagnostic settings for log collection
- Sets up Sumo Logic collecto| <a name="output_sumo_metrics_sources"></a> [sumo\_metrics\_sources](#output\_sumo\_metrics\_sources) | A map of Sumo Logic metrics source IDs by namespace. |

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

**Warning**: This will:
- Delete all EventHub namespaces and hubs
- Remove diagnostic settings from Azure resources
- Delete Sumo Logic collector and all sources
- Remove installed Sumo Logic apps

Data in Sumo Logic will be retained based on your retention policy.

## Architecture

```
## Architecture

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
- **Scope**: Subscription-level (not resource-level)
- **Condition**: Created when `enable_activity_logs = true`
- **Categories**: Administrative, Security, ServiceHealth, Alert, Recommendation, Policy, Autoscale

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
- **Authentication**: Uses Azure service principal credentials
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
   - Service Principal with permissions:
     - `Reader` on target resources
     - `Contributor` on resource group for EventHub creation
     - `Monitoring Contributor` for diagnostic settings
   - Azure CLI configured

2. **Sumo Logic**:
   - Active Sumo Logic account
   - Access ID and Access Key with permissions to create collectors and sources
   - Admin role recommended for app installation

3. **Terraform**:
   - Terraform >= 1.5.7 installed
   - Azure provider >= 4.19.0
   - Sumo Logic provider >= 3.0.2

### Key Variables

#### Required Variables

```hcl
# Azure Authentication
azure_subscription_id = "your-subscription-id"
azure_client_id       = "your-client-id"
azure_client_secret   = "your-client-secret"
azure_tenant_id       = "your-tenant-id"

# Sumo Logic Authentication
sumologic_access_id      = "your-access-id"
sumologic_access_key     = "your-access-key"
sumologic_environment    = "us2"  # or your deployment region

# Resource Configuration
resource_group_name        = "rg-sumologic-eventhub"
location                   = "eastus"
collector_name             = "Azure Collection"
eventhub_namespace         = "sumo-logs"
```

#### Target Resources Configuration

Define which Azure resources to collect from using `target_resource_types`:

```hcl
target_resource_types = [
  {
    log_namespace    = "Microsoft.Sql/servers/databases"
    metric_namespace = "Microsoft.Sql/servers/databases"
  },
  {
    log_namespace    = "Microsoft.Storage/storageAccounts"
    metric_namespace = "Microsoft.Storage/storageAccounts"
  }
]
```

**Fields:**
- `resource_type`: Azure resource type to discover
- `log_namespace`: Namespace for log collection (creates EventHub log source)
- `metric_namespace`: Namespace for metrics collection (creates metrics source)

**Nested Resources**: For parent-child resources (e.g., Storage sub-services), use `nested_namespace_configs`:

```hcl
nested_namespace_configs = {
  "Microsoft.Storage/storageAccounts" = [
    "Microsoft.Storage/storageAccounts/blobServices",
    "Microsoft.Storage/storageAccounts/fileServices"
  ]
}
```

#### App Installation

Install Sumo Logic apps for pre-built dashboards:

```hcl
installation_apps_list = [
  {
    uuid    = "0f2af8dd-447f-460f-95f7-3c7898a1eb25"
    name    = "Azure SQL"
    version = "1.0.0"
  },
  {
    uuid    = "c039e808-b5f4-4179-aba9-876c7eb01f94"
    name    = "Azure Storage"
    version = "1.0.0"
  }
]
```

#### Optional: Activity Logs

Enable subscription-level activity log collection:

```hcl
enable_activity_logs = true
```

## How to Run This Project

### Step 1: Clone and Navigate

```bash
cd azure-collection-terraform
```

### Step 2: Create Configuration File

Create `terraform.tfvars` with your configuration:

```hcl
# Azure Configuration
azure_subscription_id = "your-subscription-id"
azure_client_id       = "your-service-principal-client-id"
azure_client_secret   = "your-service-principal-secret"
azure_tenant_id       = "your-tenant-id"

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

### Step 7: Access Dashboards

Navigate to Sumo Logic dashboards for installed apps to view logs and metrics.

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

Comprehensive test suite available in [`test/`](test/) directory. See [`test/README.md`](test/README.md) for:
- 20 validation tests covering Azure and Sumo Logic resources
- Integration test with 4-phase validation (infrastructure → configuration → data flow → cleanup)
- Test fixtures for various Azure resource types

**Quick Test:**
```bash
cd test
go test -v -run TestAzureCollectionValidation -timeout 30m
```

## Variable Reference (Auto-Generated)

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_activity_log_export_category"></a> [activity\_log\_export\_category](#input\_activity\_log\_export\_category) | Activity Log Export Category | `string` | `"azure/activity-logs"` | no |
| <a name="input_activity_log_export_name"></a> [activity\_log\_export\_name](#input\_activity\_log\_export\_name) | Activity Log Export Name | `string` | `"activity_logs_export"` | no |
| <a name="input_apps_names_to_install"></a> [apps\_names\_to\_install](#input\_apps\_names\_to\_install) | Provide comma separated list of applications for which sumologic resources (collection and apps) needs to be created. Allowed values are "Azure Web Apps,Azure Service Bus,Azure Storage,Azure Load Balancer,Azure CosmosDB". | `string` | `"Azure Service Bus,Azure Key Vault,Azure Storage"` | no |
| <a name="input_azure_client_id"></a> [azure\_client\_id](#input\_azure\_client\_id) | The client id | `string` | `""` | no |
| <a name="input_azure_client_secret"></a> [azure\_client\_secret](#input\_azure\_client\_secret) | The client secret | `string` | `""` | no |
| <a name="input_azure_subscription_id"></a> [azure\_subscription\_id](#input\_azure\_subscription\_id) | The subscription id where your azure resources are present | `string` | `""` | no |
| <a name="input_azure_tenant_id"></a> [azure\_tenant\_id](#input\_azure\_tenant\_id) | The Tenant Id | `string` | `""` | no |
| <a name="input_enable_activity_logs"></a> [enable\_activity\_logs](#input\_enable\_activity\_logs) | Set to true to enable subscription-level activity log export. | `bool` | n/a | yes |
| <a name="input_eventhub_name"></a> [eventhub\_name](#input\_eventhub\_name) | The name of the Event Hub. | `string` | `"SUMO-267667-Hub-Logs-Collector"` | no |
| <a name="input_eventhub_namespace_name"></a> [eventhub\_namespace\_name](#input\_eventhub\_namespace\_name) | The name of the Event Hub Namespace. | `string` | `"SUMO-267667-Hub"` | no |
| <a name="input_index_value"></a> [index\_value](#input\_index\_value) | The \_index if the collection is configured with custom partition. | `string` | `"sumologic_default"` | no |
| <a name="input_location"></a> [location](#input\_location) | The location for the resources. | `string` | `"East US"` | no |
| <a name="input_policy_name"></a> [policy\_name](#input\_policy\_name) | The name of the Shared Access Policy. | `string` | `"SumoCollectionPolicy"` | no |
| <a name="input_required_resource_tags"></a> [required\_resource\_tags](#input\_required\_resource\_tags) | A map of tags to filter Azure resources by. | `map(string)` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the Resource Group. | `string` | `"SUMO-267667"` | no |
| <a name="input_sumo_collector_name"></a> [sumo\_collector\_name](#input\_sumo\_collector\_name) | Sumologic collector name | `string` | `"SUMO-267667-Collector"` | no |
| <a name="input_sumologic_access_id"></a> [sumologic\_access\_id](#input\_sumologic\_access\_id) | Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | `""` | no |
| <a name="input_sumologic_access_key"></a> [sumologic\_access\_key](#input\_sumologic\_access\_key) | Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | `""` | no |
| <a name="input_sumologic_environment"></a> [sumologic\_environment](#input\_sumologic\_environment) | Enter au, ca, de, eu, jp, us2, in, kr, fed or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security | `string` | `"us1"` | no |
| <a name="input_target_resource_types"></a> [target\_resource\_types](#input\_target\_resource\_types) | List of Azure resource types whose logs and metrics you want to collect. | `list(string)` | n/a | yes |
| <a name="input_throughput_units"></a> [throughput\_units](#input\_throughput\_units) | The number of throughput units for the Event Hub Namespace. | `number` | `5` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_activity_logs_policy_key"></a> [activity\_logs\_policy\_key](#output\_activity\_logs\_policy\_key) | The primary key for the activity logs authorization rule. |
| <a name="output_eventhub_for_activity_logs_id"></a> [eventhub\_for\_activity\_logs\_id](#output\_eventhub\_for\_activity\_logs\_id) | The ID of the Event Hub for activity logs. |
| <a name="output_eventhub_namespaces"></a> [eventhub\_namespaces](#output\_eventhub\_namespaces) | A map of Event Hub namespace names by location. |
| <a name="output_eventhub_namespaces_ids"></a> [eventhub\_namespaces\_ids](#output\_eventhub\_namespaces\_ids) | A map of Event Hub namespace IDs by location. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | The name of the main resource group. |
| <a name="output_sumo_activity_log_source_id"></a> [sumo\_activity\_log\_source\_id](#output\_sumo\_activity\_log\_source\_id) | The ID of the Sumo Logic activity log source. |
| <a name="output_sumo_collection_policy_keys"></a> [sumo\_collection\_policy\_keys](#output\_sumo\_collection\_policy\_keys) | A map of shared access policy primary keys by location. |
| <a name="output_sumo_collector_id"></a> [sumo\_collector\_id](#output\_sumo\_collector\_id) | The ID of the Sumo Logic Hosted Collector. |
| <a name="output_sumo_eventhub_log_sources"></a> [sumo\_eventhub\_log\_sources](#output\_sumo\_eventhub\_log\_sources) | A map of Sumo Logic Event Hub log source IDs by resource type and location. |
| <a name="output_sumo_metrics_sources"></a> [sumo\_metrics\_sources](#output\_sumo\_metrics\_sources) | A map of Sumo Logic metrics source IDs by namespace. |

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