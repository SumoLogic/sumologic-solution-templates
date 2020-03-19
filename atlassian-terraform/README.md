# sumologic-atlassian-terraform

Terraform Script to deploy Sumo Logic - Atlassian Solution.

## Getting Started

#### Requirements

* Terraform 0.12.20+
* Required Terraform providers (Tested on mentioned versions), these providers are automatically installed on `terraform init`:
1. [Template](https://www.terraform.io/docs/providers/template/index.html) "~> 2.1"
2. [Null](https://www.terraform.io/docs/providers/null/index.html) "~> 2.1"
3. [BitBucket Terraform Provider](https://www.terraform.io/docs/providers/bitbucket/index.html) "~> 1.2"

* Required Third Party Terraform providers (Tested on mentioned versions), these providers need explicit installation as explained [here](https://www.terraform.io/docs/configuration/providers.html#third-party-plugins):
1. [Sumo Logic Terraform Provider](https://github.com/SumoLogic/sumologic-terraform-provider) "~> 2.0"
2. [Jira Terraform Provider](https://github.com/fourplusone/terraform-provider-jira) "~> 0.1.11"
3. [Rest API Terraform Provider](https://github.com/Mastercard/terraform-provider-restapi) "~> 1.12"

#### Setup working directory

1. Install required third party terraform providers.
2. Initialize Terraform working directory and download plugins by running `terraform init`.
3. Update placeholder values in `terraform.tfvars` to correspond to your Sumo Logic and Atlassian environments. See [list of input parameters](#configurable-parameters) below.

#### Deploy Sumo Logic - Atlassian Solution

```shell
$ terraform plan
$ terraform apply
```
#### Uninstall Sumo Logic - Atlassian Solution

To uninstall the solution simply run `terraform destroy` though there are times where you may want to plan a destroy first. To do so, add the -destroy flag to terraform plan and then apply the destroy plan.

## Configurable Parameters

Configure below mentioned parameters in `terraform.tfvars`.

### Sumo Logic

[Sumo Logic Terraform Provider](https://github.com/SumoLogic/sumologic-terraform-provider)

| Parameter |Description |Default Value  | URL|
| --- | --- | --- | --- |
| sumo_access_id            | Sumo Logic Access ID                                                  |       |https://help.sumologic.com/Manage/Security/Access-Keys|
| sumo_access_key           | Sumo Logic Access Key                                                 |       |https://help.sumologic.com/Manage/Security/Access-Keys|
| environment               | Sumo Logic Deployment                                                 | us1   |https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security|
| sumo_api_endpoint         | Sumo Logic API Endpoint. Make sure the trailing "/" is present.       |   https://api.sumologic.com/api/v1/    |https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security|
| app_installation_folder   | The Sumo Logic apps will be installed in a folder under your personal folder in Sumo Logic.| Atlassian|   |
| install_jira_cloud        | Install Sumo Logic Application and WebHooks for Jira Cloud            | true  |       |
| install_jira_on_prem      | Install Sumo Logic Application and WebHooks for Jira Server (On Prem) | true  |   https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jira    |
| install_bitbucket_cloud   | Install Sumo Logic Application and WebHooks for BitBucket Cloud       | true  |       |
| install_opsgenie          | Install Sumo Logic Application and WebHooks for OpsGenie              | true  |   https://help.sumologic.com/07Sumo-Logic-Apps/18SAAS_and_Cloud_Apps/Opsgenie    |
| install_sumo_to_opsgenie_webhook | Install Sumo Logic to OpsGenie WebHook. Install_opsgenie should be true for this option to be true. |  true  | https://help.sumologic.com/Manage/Connections-and-Integrations/Webhook-Connections/Webhook_Connection_for_Opsgenie |

## Jira Cloud

[Jira Terraform Provider](https://github.com/fourplusone/terraform-provider-jira)

| Parameter | Description | URL|
| --- | --- | --- |
| jira_cloud_url        | Jira Cloud URL                |   |
| jira_cloud_user       | Jira Cloud Username           |   |
| jira_cloud_password   | Jira Cloud Password or API Key           |https://confluence.atlassian.com/cloud/api-tokens-938839638.html|
| jira_cloud_jql        | Jira Cloud Query Language Example: "project = Sumo"|https://support.atlassian.com/jira-software-cloud/docs/what-is-advanced-searching-in-jira-cloud/|
| jira_cloud_events     | Jira Cloud Events |https://developer.atlassian.com/cloud/jira/platform/webhooks/|

## Jira Server (On Prem)

[Jira Terraform Provider](https://github.com/fourplusone/terraform-provider-jira)

### Note: Terraform configures Jira Server WebHooks. Jira Server Logs collection needs to be configured as explained in Step 1 [here](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jira/Collect_Logs_for_Jira#step-1-set-up-local-file-sources-on-an-installed-collector).

| Parameter | Description | URL|
| --- | --- | --- |
| jira_on_prem_url        | Jira Server URL                |   |
| jira_on_prem_user       | Jira Server Username           |   |
| jira_on_prem_password   | Needs to be the password. API Key is not supported on Jira Server yet.           |  |
| jira_on_prem_jql        | Jira Server Query Language Example: "project = Sumo"|https://support.atlassian.com/jira-software-cloud/docs/what-is-advanced-searching-in-jira-cloud/|
| jira_on_prem_events     | Jira Server Events |https://developer.atlassian.com/server/jira/platform/webhooks/|

## BitBucket

[BitBucket Terraform Provider](https://github.com/terraform-providers/terraform-provider-bitbucket)

| Parameter | Description | URL|
| --- | --- | --- |
| bitbucket_cloud_user          | BitBucket Username           |   |
| bitbucket_cloud_password      | BitBucket password or App Password          | https://confluence.atlassian.com/bitbucket/app-passwords-828781300.html |
| bitbucket_cloud_owner         | The owner of the repositories. Can be you or any team you have write access to|       |
| bitbucket_cloud_repos         | Specify the repositories for which WebHooks should be created. Format: ["repo1","repo2"]           |   |
| bitbucket_cloud_desc          | The name / description to show in the UI          |  |
| bitbucket_cloud_events        | BitBucket Events to track           |https://confluence.atlassian.com/bitbucket/event-payloads-740262817.html|

## OpsGenie

[Rest API Terraform Provider](https://github.com/Mastercard/terraform-provider-restapi)

| Parameter | Description | URL|
| --- | --- | --- |
| opsgenie_api_url        | OpsGenie API URL. Do not add the trailing "/". If using the EU instance of Opsgenie, the URL needs to be https://api.eu.opsgenie.com for requests to be executed.                 | https://docs.opsgenie.com/docs/api-overview
| opsgenie_key            | OpsGenie API Key            | https://docs.opsgenie.com/docs/api-integration
