# Azure Collection Terraform Module

Terraform module for automated log and metrics collection from Azure resources to Sumo Logic.

## 📑 Table of Contents

> **Click on any section below to expand and view detailed contents**

<details>
<summary><strong>Overview & Architecture</strong></summary>
<br>

- [Overview](#overview)
- [Architecture](#architecture)

</details>

<details>
<summary><strong>Terraform Resources</strong></summary>
<br>

**Azure Resources**
- [azurerm_resource_group.rg](#azurerm_resource_grouprg)
- [azurerm_eventhub_namespace.namespaces_by_location](#azurerm_eventhub_namespacenamespaces_by_location)
- [azurerm_eventhub.eventhubs_by_type_and_location](#azurerm_eventhubeventhubs_by_type_and_location)
- [azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy](#azurerm_eventhub_namespace_authorization_rulesumo_collection_policy)
- [azurerm_monitor_diagnostic_setting.diagnostic_setting_logs](#azurerm_monitor_diagnostic_settingdiagnostic_setting_logs)
- [Activity Logs Resources (Conditional)](#azurerm_eventhub_namespaceactivity_logs_namespace-conditional)

**SumoLogic Resources**
- [sumologic_collector.sumo_collector](#sumologic_collectorsumo_collector)
- [sumologic_azure_event_hub_log_source](#sumologic_azure_event_hub_log_sourcesumo_azure_event_hub_log_source)
- [sumologic_azure_metrics_source](#sumologic_azure_metrics_sourceterraform_azure_metrics_source)
- [sumologic_app.apps](#sumologic_appapps)

**Data Sources**
- [azurerm_client_config.current](#azurerm_client_configcurrent)
- [azurerm_resources.all_target_resources](#azurerm_resourcesall_target_resources)
- [azurerm_monitor_diagnostic_categories.all_categories](#azurerm_monitor_diagnostic_categoriesall_categories)

</details>

<details>
<summary><strong>Requirements & Compatibility</strong></summary>
<br>

- [Configuration Files](#-configuration-files)
- [Supported Versions](#supported-versions)
- [Providers](#providers)
- [Terraform Resource Reference](#terraform-resource-reference-provider-resources)

</details>

<details>
<summary><strong>Configuration</strong></summary>
<br>

- [Prerequisites](#prerequisites)
- [Azure RBAC Requirements](#azure-rbac-requirements)
  - Required Azure Roles
  - Verify Your Permissions
  - Authentication
- [Configuration Variables](#configuration-variables)
- [Provider Deletion Safety](#provider-deletion-safety)
- [Important Notes](#important-notes)

</details>

<details>
<summary><strong>How to Run This Project</strong></summary>
<br>

- [Step 1: Clone and Navigate](#step-1-clone-and-navigate)
- [Step 2: Create Configuration File](#step-2-create-configuration-file)
  - Required Variables (Must Configure)
  - Optional Variables (Configure If Needed)
  - Default Variables (Customize or Keep Defaults)
- [Step 3: Initialize Terraform](#step-3-initialize-terraform)
- [Step 4: Review Plan](#step-4-review-plan)
- [Step 5: Deploy](#step-5-deploy)
- [Step 6: Verify](#step-6-verify)
- [Step 7: Access Dashboards and Monitors](#step-7-access-dashboards-and-monitors)

</details>

<details>
<summary><strong>Outputs</strong></summary>
<br>

- [Terraform Outputs](#outputs)

</details>

<details>
<summary><strong>Testing</strong></summary>
<br>

- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
  - Quick Unit Tests
  - Full Integration Tests
  - Specific Test Categories
- [Test Configuration](#test-configuration)
- [Test Features](#test-features)

</details>

<details>
<summary><strong>Troubleshooting</strong></summary>
<br>

- [Azure Event Hub Regional Support](#azure-event-hub-regional-support)
  - Regional Support Tables by Geography
  - Quick Summary
- [Common Issues](#common-issues)
- [Debugging](#debugging)

</details>

<details>
<summary><strong>Cleanup</strong></summary>
<br>

- [Destroying Resources](#cleanup)
- [Safe Cleanup Steps](#-to-safely-remove-activity-logs-before-destroying)

</details>

---

## Overview

This module creates a complete data pipeline to collect logs and metrics from Azure resources and send them to Sumo Logic for monitoring and analysis. It automatically:

- Discovers Azure resources based on tags
- Creates EventHub infrastructure per location
- Configures diagnostic settings for log collection
- Sets up Sumo Logic sources and collectors

## Architecture

This module implements a dual-pipeline architecture for comprehensive Azure monitoring.

### 📊 Log Collection Data Flow

The following sequence outlines how Azure resource logs are collected and sent to Sumo Logic:

1. **Azure Resources** generate diagnostic logs (access logs, audit logs, error logs) → View in: [Azure Portal](https://portal.azure.com) → Resource Groups → Resources

2. **→ Diagnostic Settings** automatically route logs from all categories of each resource to Event Hubs → View in: Azure Portal → Resource → Monitoring → Diagnostic settings

3. **→ Event Hub Namespaces & Hubs** receive and buffer logs organized by region and resource type → View in: Azure Portal → Resource Groups → Event Hub Namespaces

4. **→ Sumo Logic Log Sources** consume logs from Event Hubs in real-time and parse JSON format → View in: [Sumo Logic](https://service.sumologic.com) → Manage Data → Collection → Collectors

5. **→ Sumo Logic Apps & Dashboards** provide pre-built visualizations, searches, and alerts → Access in: Sumo Logic → App Catalog → Installed Apps

### 📈 Metrics Collection Data Flow

The following sequence outlines how Azure resource metrics are collected and sent to Sumo Logic:

1. **Azure Resources** emit performance metrics (CPU, memory, throughput) automatically collected by Azure Monitor

2. **→ Azure Monitor Metrics API** provides centralized access to all resource metrics via REST API → [Documentation](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-platform-metrics)

3. **→ Sumo Logic Metrics Sources** poll Azure Monitor API at regular intervals for metrics data → View in: Sumo Logic → Manage Data → Collection → Metrics Sources

4. **→ Sumo Logic Apps & Dashboards** visualize time-series data and provide metric-based alerts → Access in: Sumo Logic → App Catalog → Installed Apps

### 🔑 Key Components Summary

| Component | Purpose | Where to View |
|-----------|---------|---------------|
| **Resource Discovery** | Queries Azure for resources matching specified tags and types | Azure Portal → Resources |
| **EventHub Infrastructure** | Regional log streaming backbone for efficient routing | Azure Portal → Event Hub Namespaces |
| **Diagnostic Settings** | Configures each resource to stream logs to EventHubs | Azure Portal → Resource → Monitoring → Diagnostic settings |
| **Sumo Logic Collectors** | Hosted collectors that receive logs and metrics | Sumo Logic → Manage Data → Collection |
| **Sumo Logic Sources** | Log sources (EventHub) and Metrics sources (API polling) | Sumo Logic → Collectors → Sources |
| **Sumo Logic Apps** | Pre-built dashboards, searches, and monitors | Sumo Logic → App Catalog |

## Terraform Resources

### Azure Resources
Following are the list of Azure Terraform Resources managed by this module.
#### azurerm_resource_group.rg
Creates a resource group to contain all EventHub infrastructure.
- **Purpose**: Logical container for EventHub namespaces and hubs
- **Configuration**: Set via `resource_group_name` and `location` variables
- **Lifecycle**: Managed by Terraform; deletion removes all contained resources

#### azurerm_eventhub_namespace.namespaces_by_location
Creates EventHub namespaces, one per unique Azure region where target resources exist.
- **Purpose**: Regional EventHub service for high-performance log streaming
- **Naming**: `{eventhub_namespace}-{location}` (e.g., `sumo-logs-eastus`)
- **SKU**: Configurable via `eventhub_namespace_sku` (default: Standard)
- **Scaling**: Capacity units set via `eventhub_namespace_capacity`

#### azurerm_eventhub.eventhubs_by_type_and_location
Creates individual EventHubs for each resource type and location combination.
- **Purpose**: Separate data streams per resource type for organized log collection
- **Naming**: `insights-logs-{resource_type}` per namespace
- **Configuration**: Partition count and message retention configurable
- **Cardinality**: One EventHub per (`resource_type` × `location`) combination

#### azurerm_eventhub_namespace_authorization_rule.sumo_collection_policy
Creates authorization rules for Sumo Logic to access EventHub namespaces.
- **Purpose**: Secure authentication for Sumo Logic log sources
- **Permissions**: Listen only (read access)
- **Scope**: One per namespace (location-based)
- **Usage**: Connection strings used by Sumo Logic sources

#### azurerm_monitor_diagnostic_setting.diagnostic_setting_logs
Attaches diagnostic settings to each target Azure resource for log streaming.
- **Purpose**: Routes resource logs to appropriate EventHub
- **Configuration**: Automatically maps resources to EventHubs based on type and location
- **Log Categories**: Streams all available diagnostic log categories
- **Metrics**: Can optionally include metrics data

#### azurerm_eventhub_namespace.activity_logs_namespace (Conditional)
Creates a dedicated namespace for Azure subscription-level activity logs.
- **Purpose**: Separate infrastructure for subscription audit logs
- **Condition**: Created when `enable_activity_logs = true`
- **Isolation**: Keeps subscription logs separate from resource logs
- **Location**: Uses primary subscription region

#### azurerm_eventhub.eventhub_for_activity_logs (Conditional)
Creates the EventHub within activity logs namespace.
- **Purpose**: Receives subscription-level activity and audit logs
- **Naming**: `insights-activity-logs`
- **Condition**: Created when `enable_activity_logs = true`
- **Special Use**: Captures subscription-wide operations and changes

#### azurerm_eventhub_namespace_authorization_rule.activity_logs_policy (Conditional)
Creates authorization rule for Sumo Logic to access activity logs.
- **Purpose**: Secure authentication for activity log collection
- **Permissions**: Listen only
- **Condition**: Created when `enable_activity_logs = true`

#### azurerm_monitor_diagnostic_setting.activity_logs_to_event_hub (Conditional)
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

Following are the list of Sumologic Terraform Resources managed by this module.

#### sumologic_collector.sumo_collector
Creates a hosted collector in Sumo Logic for receiving logs and metrics.
- **Purpose**: Central collection point for all Azure data
- **Type**: Hosted (cloud-based, no agent required)
- **Configuration**: Named via `collector_name` variable
- **Capacity**: Single collector handles all sources

####  sumologic_azure_event_hub_log_source.sumo_azure_event_hub_log_source
Creates log sources that consume from EventHubs.
- **Purpose**. Reads logs from EventHubs and ingests into Sumo Logic.
- **Cardinality**. One source per EventHub (filtered by `log_namespace`).
- **Authentication**. Uses connection strings from authorization rules.
- **Processing**. Parses Azure diagnostic log JSON format.
- **Filtering**. Only created for resources with `log_namespace` defined.

#### sumologic_azure_metrics_source.terraform_azure_metrics_source
Creates metrics sources for Azure metrics collection via API.
- **Purpose**: Collects metrics directly from Azure Monitor API
- **Cardinality**: One source per unique metric_namespace group
- **Authentication**: Uses configured Azure credentials
- **Polling**: Periodic collection (configurable interval)
- **Filtering**: Only created for resources with `metric_namespace` defined

#### sumologic_azure_event_hub_log_source.sumo_activity_log_source (Conditional)
Creates a dedicated source for subscription activity logs.
- **Purpose**: Ingests subscription-level audit and activity logs
- **Condition**: Created when `enable_activity_logs = true`
- **Isolation**: Separate from resource log sources
- **Usage**: Security auditing, compliance, change tracking

#### sumologic_app.apps
Installs pre-built Sumo Logic apps for visualization and analysis.
- **Purpose**: Provides dashboards, searches, and alerts for Azure services
- **Configuration**: Specified via `installation_apps_list` variable
- **Examples**: Azure SQL, Azure Storage, Azure Kubernetes Service apps
- **Requirement**: Each app requires specific log/metric sources to be configured

### Data Sources

Following are the list of Data Sources managed by this module.

#### azurerm_client_config.current
Retrieves current Azure authentication context.
- **Usage**: Gets subscription ID and tenant ID for resource tagging
- **Read-Only**: Does not create resources

#### azurerm_resources.all_target_resources
Queries Azure for resources matching specified tags.
- **Purpose**: Discovers target resources for log collection
- **Filter**: Uses `resource_group_name_filter` and `resource_tags` variables
- **Output**: List of resource IDs, types, and locations
- **Dynamic**: Results determine EventHub and diagnostic setting creation

#### azurerm_monitor_diagnostic_categories.all_categories
Retrieves available diagnostic categories for each discovered resource.
- **Purpose**: Determines what logs and metrics each resource can export
- **Dynamic**: Queries per discovered resource
- **Usage**: Ensures diagnostic settings enable all available log categories

## Requirements & compatibility

This section documents the module's runtime requirements and compatibility expectations. It highlights which Terraform and provider versions the module is tested against, and which runtime tools are required for integration tests. Use supported versions to avoid unexpected provider schema or feature mismatches.

### 📁 Configuration Files

- `terraform.tfvars.example` - Template with all variables and detailed documentation
- `terraform.tfvars` - Your actual configuration (customize and keep secure)
- `test/` - Comprehensive test suite with 69 test scenarios

### Supported versions

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.19.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |
| <a name="requirement_sumologic"></a> [sumologic](#requirement\_sumologic) | >= 3.0.2 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.7.1 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.43.0 |
| <a name="provider_sumologic"></a> [sumologic](#provider\_sumologic) | 3.1.4 |


### Terraform resource reference (provider resources)

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

| Name | Description | Type | Sample | Required |
|------|-------------|------|---------|:--------:|
| **Azure Authentication** |||||
| `azure_subscription_id` | Azure Subscription ID where resources will be created. If not provided, uses current Azure CLI context. | `string` | `"your-azure-subscription-id"` | Yes |
| `azure_client_id` | Service Principal Application (client) ID. If not provided, uses Azure CLI context. | `string` | `"your-azure-client-id"` | Yes |
| `azure_client_secret` | Service Principal client secret value. If not provided, uses Azure CLI context. | `string` (sensitive) | `"your-azure-client-secret"` | Yes |
| `azure_tenant_id` | Azure Active Directory Tenant ID. If not provided, uses current Azure CLI context. | `string` | `"your-azure-tenant-id"` | Yes |
| **Azure Infrastructure** |||||
| `resource_group_name` | Name for the new resource group where all Event Hub namespaces will be created. These Event Hubs are used to configure resource logs and activity logs collection sources in Sumo Logic. | `string` | `"sumologic-azure-collection-rg"` | **Yes** |
| `eventhub_namespace_name` | Name for the Event Hub namespace (must be globally unique across Azure, 6-50 characters, starts with letter). | `string` | `"sumologic-azure-collection-EventHub"` | Yes |
| `eventhub_namespace_sku` | Event Hub SKU tier. Options: `Standard` or `Premium`. | `string` | `"Premium"` | **Yes** |
| `location` | Azure region for resources (must match subscription location). Example: `East US`, `West US 2`, `North Europe`. | `string` | `"East US"` | **Yes** |
| `policy_name` | Name for the Event Hub authorization policy (1-64 characters, alphanumeric and hyphens only). | `string` | `"SumoLogicAzureCollectionPolicy"` | **Yes** |
| `throughput_units` | Number of throughput units (processing capacity) for Event Hub Premium tier. Options: `1`, `2`, `4`, `8`, or `16`. | `number` | `2` | **Yes** |
| **Activity Logs** |||||
| `enable_activity_logs` | Enable/disable subscription-level activity log collection. **Warning**: Affects entire subscription, not just this Terraform workspace. | `bool` | `false` | **Yes** |
| `activity_log_export_name` | Name for the activity log diagnostic setting (1-128 characters, alphanumeric with underscores, periods, hyphens). | `string` | `"SumoLogicAzureActivityLogExport"` | **Yes** |
| `activity_log_export_category` | Source category for activity logs in Sumo Logic. | `string` | `"azure/activity-logs"` | **Yes** |
| **Resource Targeting** |||||
| `target_resource_types` | List of Azure resource types to monitor. Each object specifies `log_namespace` (for log collection via EventHub) and/or `metric_namespace` (for metrics collection via Azure Monitor API). At least one must be specified per resource type. | `list(object)` | Refer to [terraform.tfvars.example](/azure-collection-terraform/terraform.tfvars.example#L72) | **Yes** |
| `required_resource_tags` | Map of tags to filter Azure resources. Only resources with these tags will be monitored. Use empty `{}` to monitor all resources without tag filtering. | `map(string)` | `{"tag-name": "tag-value"}` | **Yes** |
| `nested_namespace_configs` | Map of parent resource types to their child resource types for nested resources (e.g., Storage Accounts → blobServices/fileServices). Use empty `{}` if not monitoring nested resources. | `map(list(string))` | Refer to [terraform.tfvars.example](/azure-collection-terraform/terraform.tfvars.example#L226) | **Yes** |
| **Sumo Logic Configuration** |||||
| `sumologic_access_id` | Sumo Logic Access ID from your account preferences. Used for API authentication. | `string` | `"your-sumologic-access-id"` | **Yes** |
| `sumologic_access_key` | Sumo Logic Access Key from your account preferences. Used for API authentication. | `string` (sensitive) | `"your-sumologic-access-key"` | **Yes** |
| `sumologic_environment` | Sumo Logic deployment region. Options: `us1`, `us2`, `eu`, `au`, `ca`, `de`, `jp`, `in`, `kr`, `fed`. | `string` | `"us1"` | **Yes** |
| `sumo_collector_name` | Name for the Sumo Logic hosted collector (alphanumeric, hyphens, underscores, max 128 characters). | `string` | `"sumologic-azure-collection"` | **Yes** |
| `installation_apps_list` | List of Sumo Logic apps to install automatically. Each app requires `uuid`, `name`, `version`, and optionally `parameters` (map of key-value pairs for app configuration). Use empty `[]` to skip app installation. | `list(object)` | Refer to [terraform.tfvars.example](/azure-collection-terraform/terraform.tfvars.example#L253) | No |

To obtain these values follow [these steps](https://www.sumologic.com/help/docs/send-data/hosted-collectors/microsoft-source/azure-metrics-source/#vendor-configuration)

#### Provider deletion safety

This module exposes a boolean variable named `prevent_deletion_if_contains_resources` which controls the azurerm provider feature `resource_group.prevent_deletion_if_contains_resources`.

- Default: `true` (safe for production) — the provider will prevent deletion of a Resource Group if it still contains nested resources.
- For automated integration tests you may set this to `false` so the tests can clean up Resource Groups that still contain nested Azure resources (test-only usage).

Example (override via CLI):

```
terraform apply -var 'prevent_deletion_if_contains_resources=false'
```

Or in a tfvars file:

```hcl
prevent_deletion_if_contains_resources = false
```


#### Important Notes

**Activity Logs - Subscription-Level Warning:**

Activity logs operate at the **Azure subscription level**, not at the resource level. This has important implications:

- **Scope**. Activity logs capture ALL operations across the ENTIRE subscription (all resource groups, all resources).
- **Single Configuration**. Azure only allows **ONE** diagnostic setting for activity logs per subscription.
- **Shared Resource**. If multiple Terraform configurations or users enable activity logs on the same subscription, **only the last one applied will be active**.
- **Deletion Impact**. Running `terraform destroy` on ANY Terraform configuration that manages activity logs will **delete the subscription-level diagnostic setting**, affecting **ALL** other configurations that depend on it.

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

Copy the `terraform.tfvars.example` file to `terraform.tfvars` and configure the variables as described below:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and configure variables according to these groups:

#### 🔴 **Required - Must Configure** (Set these values for your environment)

```hcl
# ============================================================================
# Azure Authentication - Get these from Azure Portal
# ============================================================================
azure_subscription_id = "your-azure-subscription-id"  # Your Azure subscription ID
azure_client_id       = "your-azure-client-id"        # Service principal client ID
azure_client_secret   = "your-azure-client-secret"    # Service principal secret
azure_tenant_id       = "your-azure-tenant-id"        # Your Azure AD tenant ID

# ============================================================================
# Event Hub Configuration - Choose SKU and throughput based on your needs
# ============================================================================
eventhub_namespace_sku    = "Standard"  # Options: "Standard" or "Premium"
standard_throughput_units = 2           # For Standard SKU: 1, 2, 4, 8, or 16
premium_throughput_units  = 4           # For Premium SKU: 1, 2, 4, 8, or 16

# ============================================================================
# Azure Region - Where to deploy Event Hub infrastructure for Activity Logs
# ============================================================================
location = "East US"  # Example: "East US", "West Europe", "Southeast Asia"

# ============================================================================
# Activity Logs - Enable/disable subscription-level activity log collection
# ============================================================================
enable_activity_logs = false  # Set to true to collect Azure activity logs

# ============================================================================
# Target Resources - Define which Azure resources to monitor
# ============================================================================
target_resource_types = [
  {
    log_namespace    = "Microsoft.Storage/storageAccounts"
    metric_namespace = "Microsoft.Storage/storageAccounts"
  }
  # Add more resource types as needed
]

# ============================================================================
# Sumo Logic Configuration - Get these from your Sumo Logic account
# ============================================================================
sumologic_access_id   = "your-sumologic-access-id"   # From Sumo Logic → Preferences → My Access Keys
sumologic_access_key  = "your-sumologic-access-key"  # From Sumo Logic → Preferences → My Access Keys
sumologic_environment = "us1"                        # Options: us1, us2, eu, au, ca, de, jp, in, kr, fed

# ============================================================================
# Sumo Logic Apps - Specify apps to install automatically
# ============================================================================
installation_apps_list = [
  {
    uuid       = "azure-storage-app-uuid"
    name       = "Azure Storage"
    version    = "1.0.3"
    parameters = {
      "index_value" = "sumologic_default"
    }
  }
  # Add more apps as needed
]
```

#### 🟡 **Optional - Configure If Needed** (Leave empty or customize)

```hcl
# ============================================================================
# Resource Filtering - Filter Azure resources by tags (optional)
# ============================================================================
required_resource_tags = {
  # Example: Only monitor resources with these tags
  # "Environment" = "Production"
  # "Monitoring"  = "Enabled"
}
# Leave as {} to monitor all resources without tag filtering

# ============================================================================
# Nested Resources - Configure child resources for monitoring (optional)
# ============================================================================
nested_namespace_configs = {
  # Example: Monitor blob services within storage accounts
  # "Microsoft.Storage/storageAccounts" = [
  #   "Microsoft.Storage/storageAccounts/blobServices",
  #   "Microsoft.Storage/storageAccounts/fileServices"
  # ]
}
# Leave as {} if not monitoring nested resources
```

#### 🟢 **Optional - Customize or Keep Defaults** (Pre-configured with sensible defaults)

These variables have default values and typically don't need changes:

```hcl
# ============================================================================
# Resource Naming - Customize if you want different names
# ============================================================================
resource_group_name                          = "sumologic-azure-collection-rg"
eventhub_namespace_name                      = "sumologic-azure-collection-EventHub"
policy_name                                  = "SumoLogicAzureCollectionPolicy"
activity_log_export_name                     = "SumoLogicAzureActivityLogExport"
activity_log_export_category                 = "azure/activity-logs"
sumo_collector_name                          = "sumologic-azure-collection"

# ============================================================================
# Regional Support - Pre-configured with known limitations
# ============================================================================
eventhub_namespace_unsupported_locations     = [ /* 19 unsupported regions */ ]
eventhub_namespace_limited_sku_locations     = ["West India", "Mexico Central"]

# ============================================================================
# Provider Safety - Keep default for production
# ============================================================================
prevent_deletion_if_contains_resources       = true  # Safety feature - don't change
```

**💡 Quick Start Example:**

For a minimal configuration to get started quickly:

```hcl
# Azure (Required)
azure_subscription_id = "your-azure-subscription-id"
azure_client_id       = "your-azure-client-id"
azure_client_secret   = "your-azure-client-secret"
azure_tenant_id       = "your-azure-tenant-id"

# Event Hub (Required)
eventhub_namespace_sku    = "Standard"
standard_throughput_units = 2
premium_throughput_units  = 4
location                  = "East US"

# Monitoring (Required)
enable_activity_logs = false
target_resource_types = [
  {
    log_namespace    = "Microsoft.Storage/storageAccounts"
    metric_namespace = "Microsoft.Storage/storageAccounts"
  }
]

# Sumo Logic (Required)
sumologic_access_id   = "your-access-id"
sumologic_access_key  = "your-access-key"
sumologic_environment = "us1"
installation_apps_list = []  # Start with no apps, add later

# Optional - Leave as default
required_resource_tags   = {}
nested_namespace_configs = {}
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

### Azure Event Hub Limitation
Please visit [here](https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-quotas) to find out more details about Azure Event Hub Limitations

### Azure Event Hub Regional Support

The table below shows Event Hub namespace availability across Azure regions by SKU tier. This module automatically handles region-specific SKU limitations.

**Legend:**
- ✅ = **Fully Supported** - Event Hub namespace available for this SKU tier
- ❌ = **Not Supported** - Event Hub namespace not available
- ⚠️ = **Limited Support** - Only Basic/Standard SKUs available (Premium not supported)

---

#### 🌍 Africa

| Region Name | Basic | Standard | Premium | Notes |
|-------------|:-----:|:--------:|:-------:|-------|
| South Africa North | ✅ | ✅ | ✅ | Fully supported |
| South Africa West | ❌ | ❌ | ❌ | No Event Hub support |

#### 🌏 Asia Pacific

| Region Name | Basic | Standard | Premium | Notes |
|-------------|:-----:|:--------:|:-------:|-------|
| East Asia | ✅ | ✅ | ✅ | Fully supported |
| Southeast Asia | ✅ | ✅ | ✅ | Fully supported |
| Australia Central | ✅ | ✅ | ✅ | Fully supported |
| Australia Central 2 | ❌ | ❌ | ❌ | No Event Hub support |
| Australia East | ✅ | ✅ | ✅ | Fully supported |
| Australia Southeast | ✅ | ✅ | ✅ | Fully supported |
| Indonesia Central | ✅ | ✅ | ✅ | Fully supported |
| Malaysia West | ✅ | ✅ | ✅ | Fully supported |
| New Zealand North | ✅ | ✅ | ✅ | Fully supported |

#### 🇨🇳 China

| Region Name | Basic | Standard | Premium | Notes |
|-------------|:-----:|:--------:|:-------:|-------|
| China East | ❌ | ❌ | ❌ | No Event Hub support |
| China East 2 | ❌ | ❌ | ❌ | No Event Hub support |
| China East 3 | ❌ | ❌ | ❌ | No Event Hub support |
| China North | ❌ | ❌ | ❌ | No Event Hub support |
| China North 2 | ❌ | ❌ | ❌ | No Event Hub support |
| China North 3 | ❌ | ❌ | ❌ | No Event Hub support |

#### 🇪🇺 Europe

| Region Name | Basic | Standard | Premium | Notes |
|-------------|:-----:|:--------:|:-------:|-------|
| North Europe | ✅ | ✅ | ✅ | Fully supported |
| West Europe | ✅ | ✅ | ✅ | Fully supported |
| Austria East | ✅ | ✅ | ✅ | Fully supported |
| France Central | ✅ | ✅ | ✅ | Fully supported |
| France South | ❌ | ❌ | ❌ | No Event Hub support |
| Germany North | ❌ | ❌ | ❌ | No Event Hub support |
| Germany West Central | ✅ | ✅ | ✅ | Fully supported |
| Italy North | ✅ | ✅ | ✅ | Fully supported |
| Norway East | ✅ | ✅ | ✅ | Fully supported |
| Norway West | ❌ | ❌ | ❌ | No Event Hub support |
| Poland Central | ✅ | ✅ | ✅ | Fully supported |
| Spain Central | ✅ | ✅ | ✅ | Fully supported |
| Sweden Central | ✅ | ✅ | ✅ | Fully supported |
| Sweden South | ❌ | ❌ | ❌ | No Event Hub support |
| Switzerland North | ✅ | ✅ | ✅ | Fully supported |
| Switzerland West | ❌ | ❌ | ❌ | No Event Hub support |
| UK South | ✅ | ✅ | ✅ | Fully supported |
| UK West | ✅ | ✅ | ✅ | Fully supported |

#### 🇮🇳 India

| Region Name | Basic | Standard | Premium | Notes |
|-------------|:-----:|:--------:|:-------:|-------|
| Central India | ✅ | ✅ | ✅ | Fully supported |
| South India | ✅ | ✅ | ✅ | Fully supported |
| West India | ✅ | ✅ | ⚠️ | **Premium SKU not available** - Module auto-downgrades to Standard |

#### 🇯🇵 Japan

| Region Name | Basic | Standard | Premium | Notes |
|-------------|:-----:|:--------:|:-------:|-------|
| Japan East | ✅ | ✅ | ✅ | Fully supported |
| Japan West | ✅ | ✅ | ✅ | Fully supported |

#### 🇰🇷 Korea

| Region Name | Basic | Standard | Premium | Notes |
|-------------|:-----:|:--------:|:-------:|-------|
| Korea Central | ✅ | ✅ | ✅ | Fully supported |
| Korea South | ✅ | ✅ | ✅ | Fully supported |

#### 🌎 Americas

| Region Name | Basic | Standard | Premium | Notes |
|-------------|:-----:|:--------:|:-------:|-------|
| Brazil South | ✅ | ✅ | ✅ | Fully supported |
| Brazil Southeast | ❌ | ❌ | ❌ | No Event Hub support |
| Canada Central | ✅ | ✅ | ✅ | Fully supported |
| Canada East | ✅ | ✅ | ✅ | Fully supported |
| Chile Central | ✅ | ✅ | ✅ | Fully supported |
| Mexico Central | ✅ | ✅ | ⚠️ | **Premium SKU not available** - Module auto-downgrades to Standard |

#### 🇺🇸 United States

| Region Name | Basic | Standard | Premium | Notes |
|-------------|:-----:|:--------:|:-------:|-------|
| Central US | ✅ | ✅ | ✅ | Fully supported |
| East US | ✅ | ✅ | ✅ | Fully supported |
| East US 2 | ✅ | ✅ | ✅ | Fully supported |
| North Central US | ✅ | ✅ | ✅ | Fully supported |
| South Central US | ✅ | ✅ | ✅ | Fully supported |
| West Central US | ✅ | ✅ | ✅ | Fully supported |
| West US | ✅ | ✅ | ✅ | Fully supported |
| West US 2 | ✅ | ✅ | ✅ | Fully supported |
| West US 3 | ✅ | ✅ | ✅ | Fully supported |

#### 🏛️ US Government

| Region Name | Basic | Standard | Premium | Notes |
|-------------|:-----:|:--------:|:-------:|-------|
| USGov Arizona | ❌ | ❌ | ❌ | No Event Hub support |
| USGov Texas | ❌ | ❌ | ❌ | No Event Hub support |
| USGov Virginia | ❌ | ❌ | ❌ | No Event Hub support |

#### 🌐 Middle East

| Region Name | Basic | Standard | Premium | Notes |
|-------------|:-----:|:--------:|:-------:|-------|
| Israel Central | ✅ | ✅ | ✅ | Fully supported |
| Qatar Central | ✅ | ✅ | ✅ | Fully supported |
| Taiwan North | ❌ | ❌ | ❌ | No Event Hub support |
| UAE Central | ❌ | ❌ | ❌ | No Event Hub support |
| UAE North | ✅ | ✅ | ✅ | Fully supported |

---

### Common Issues

| Issue | Solution |
|-------|----------|
| **Error creating diagnostic settings - resource already has a diagnostic setting** | Each Azure resource can have a limited number of diagnostic settings. Check existing settings in Azure Portal or use `terraform import` to manage existing configurations. |
| **EventHub throughput exceeded** | Increase `standard_throughput_units` or `premium_throughput_units` based on your SKU tier, or upgrade to Premium SKU for higher throughput capacity. Valid values: `1`, `2`, `4`, `8`, or `16`. |
| **Sumo Logic sources show "Not Receiving Data"** | 1. Verify diagnostic settings are active in Azure Portal<br>2. Check EventHub is receiving messages (Monitor → Metrics → Incoming Messages)<br>3. Confirm authorization rules have Listen permission<br>4. Verify Sumo Logic connection string is correct<br>5. Check collector is online in Sumo Logic |
| **Event Hub namespace creation failed in specific region** | Check the [regional support table](#azure-event-hub-regional-support) above. The region may not support Event Hub namespaces or may have SKU restrictions. The module automatically handles unsupported regions, but you can manually configure `eventhub_namespace_unsupported_locations` if needed. |
| **Premium SKU forced to Standard in certain regions** | West India and Mexico Central only support Basic and Standard SKUs. The module automatically downgrades to Standard SKU in these regions. No action required unless you need Premium features (use a different region). |
| **App installation fails with "app already installed" error** | The app is already installed in your Sumo Logic account. Either:<br>• Remove the app from `installation_apps_list` to skip installation<br>• Manually uninstall the existing app in Sumo Logic UI<br>• Use `terraform import` to manage the existing app installation |
| **Authentication failures with Azure provider** | 1. Ensure you've run `az login` and are authenticated<br>2. Verify your Azure credentials have sufficient permissions (Contributor + Monitoring Contributor roles)<br>3. Check subscription ID matches your target subscription<br>4. Run `az account show` to verify current context |
| **Variables validation errors** | 1. Check `eventhub_namespace_name` is 6-50 characters, starts with letter, globally unique<br>2. Verify `throughput_units` is one of: `1`, `2`, `4`, `8`, `16`<br>3. Ensure `location` matches a valid Azure region name<br>4. Validate `resource_group_name` doesn't contain special characters or spaces |

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

**⚠️ Warning**

This will:
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