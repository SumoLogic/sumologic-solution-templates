# sumologic-atlassian-terraform

The Terraform script installs the Sumo Logic Atlassian Solution collection and Atlassian Applications in the Personal Folder of the Sumo Logic user whose access keys have been used. If you need additional copies of the Atlassian Applications within Sumo Logic, install the respective Atlassian Apps from the Sumo Logic App catalog.


## Getting Started

#### Requirements

* [Terraform 0.12.20+](https://www.terraform.io/downloads.html)
* Required Terraform providers (tested on mentioned versions), these providers are automatically installed on `terraform init`:
  * [Template](https://www.terraform.io/docs/providers/template/index.html) "~> 2.1"
  * [Null](https://www.terraform.io/docs/providers/null/index.html) "~> 2.1"
  * [BitBucket Terraform Provider](https://www.terraform.io/docs/providers/bitbucket/index.html) "~> 1.2"


* Required Third Party Terraform providers (tested on mentioned versions), these providers need explicit installation as explained [here](https://www.terraform.io/docs/configuration/providers.html#third-party-plugins):
  * [Sumo Logic Terraform Provider](https://github.com/SumoLogic/sumologic-terraform-provider) "~> 2.0"
  * [Jira Terraform Provider](https://github.com/fourplusone/terraform-provider-jira) "~> 0.1.11"
  * [Rest API Terraform Provider](https://github.com/Mastercard/terraform-provider-restapi) "~> 1.12"

#### Setup working directory

1. Clone the repository:

```shell
$ git clone https://github.com/SumoLogic/sumologic-solution-templates.git
```
2. Install the required third party terraform providers ([Sumo Logic Terraform Provider](https://github.com/SumoLogic/sumologic-terraform-provider), [Jira Terraform Provider](https://github.com/fourplusone/terraform-provider-jira), [Rest API Terraform Provider](https://github.com/Mastercard/terraform-provider-restapi) ) as explained [here](https://www.terraform.io/docs/configuration/providers.html#third-party-plugins) and on respective provider documentation.
3. Initialize the Terraform working directory and download the official providers by navigating to the directory `sumologic-solution-templates/atlassian-terraform` and running `terraform init`. This will install the required Terraform providers i.e. [Template](https://www.terraform.io/docs/providers/template/index.html), [Null](https://www.terraform.io/docs/providers/null/index.html) and [BitBucket Terraform Provider](https://www.terraform.io/docs/providers/bitbucket/index.html).
4. You can choose which applications and Webhooks to install by updating the flags `install_jira_cloud`, `install_jira_on_prem`, `install_bitbucket_cloud`,`install_opsgenie`,`install_atlassian_app`,`install_sumo_to_opsgenie_webhook` and `install_sumo_to_jiracloud_webhook` in `terraform.tfvars`. By default, all components except `Sumologic to Opsgenie Webhook` and `Sumologic to Jira Webhook` are installed.
`Sumologic to Opsgenie Webhook` and `Sumologic to Jira Webhook` are in Beta. To participate contact your Sumo account executive.
5. Update the placeholder values in `terraform.tfvars` so they correspond with your Sumo Logic and Atlassian environments. See the [list of input parameters](#configurable-parameters) below.

#### Deploy Sumo Logic - Atlassian Solution

To deploy Sumo Logic - Atlassian Solution, navigate to the directory `sumologic-solution-templates/atlassian-terraform` and execute the below commands:

```shell
$ terraform plan
$ terraform apply
```
#### Uninstall Sumo Logic - Atlassian Solution

To uninstall the solution, navigate to the directory `sumologic-solution-templates/atlassian-terraform` and execute the below command:

```shell
$ terraform destroy
```
There are times when you want to plan the destroy prior to executing the command. To do so, add the -destroy flag to the terraform plan command and then apply the destroy command, for example:

```shell
$ terraform plan -destroy
$ terraform destroy
```


## Configurable Parameters

Configure the following parameters in `terraform.tfvars`.

### Sumo Logic

[Sumo Logic Terraform Provider](https://github.com/SumoLogic/sumologic-terraform-provider)

Note: `Sumologic to Opsgenie Webhook` and `Sumologic to Jira Webhook` are in Beta. To participate contact your Sumo account executive.

| Parameter |Description |Default Value
| --- | --- | --- |
| sumo_access_id            | [Sumo Logic Access ID](https://help.sumologic.com/Manage/Security/Access-Keys)  |       |
| sumo_access_key           | [Sumo Logic Access Key](https://help.sumologic.com/Manage/Security/Access-Keys) |       |
| environment               | [Sumo Logic Deployment](https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security)                                                                   | us1   |
| sumo_api_endpoint         | [Sumo Logic API Endpoint](https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security). Make sure the trailing "/" is present.                    | https://api.sumologic.com/api/v1/  |
| app_installation_folder   | The Sumo Logic apps will be installed in a folder under your personal folder in Sumo Logic.| Atlassian|
| install_jira_cloud        | Install [Sumo Logic Application and WebHooks for Jira Cloud](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jira_Cloud)            | true  |
| install_jira_on_prem      | Install [Sumo Logic Application and WebHooks for Jira Server](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jira) (On Prem) | true  |
| install_bitbucket_cloud   | Install [Sumo Logic Application and WebHooks for BitBucket Cloud](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Bitbucket)       | true  |       |
| install_opsgenie          | Install [Sumo Logic Application and WebHooks for OpsGenie](https://help.sumologic.com/07Sumo-Logic-Apps/18SAAS_and_Cloud_Apps/Opsgenie)      | true  |
| install_sumo_to_opsgenie_webhook | Install [Sumo Logic to OpsGenie WebHook](https://help.sumologic.com/Beta/Webhook_Connection_for_Opsgenie). `install_opsgenie` should be true for this option to be true. |  false  |
| install_atlassian_app     | Install [Sumo Logic Atlassian Application](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Atlassian)                              | true  |
| install_sumo_to_jiracloud_webhook| Install [Sumo Logic to Jira Cloud WebHook](https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Cloud) | false |

## Jira Cloud

[Jira Terraform Provider](https://github.com/fourplusone/terraform-provider-jira)

| Parameter | Description |
| --- | --- |
| jira_cloud_url        | Jira Cloud URL                |
| jira_cloud_user       | Jira Cloud Username           |
| jira_cloud_password   | Jira Cloud Password or [API Key](https://confluence.atlassian.com/cloud/api-tokens-938839638.html)|
| jira_cloud_jql        | Jira Cloud [Query Language](https://support.atlassian.com/jira-software-cloud/docs/what-is-advanced-searching-in-jira-cloud/) Example: "project = Sumo"|
| jira_cloud_events     | Jira Cloud [Events](https://developer.atlassian.com/cloud/jira/platform/webhooks/)|

## Sumologic to Jira Cloud Webhook

| Parameter | Description |
| --- | --- |
| jira_cloud_auth             | [Basic Authorization Header](https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Cloud#prerequisite)|
| jira_cloud_projectkey       | Jira Cloud Project Key                   |
| jira_cloud_issuetype        | Jira Cloud Issue Type, for example 'Bug' |
| jira_cloud_priority         | Issue Priority, for example 3            |

## Jira Server (On-Prem)

[Jira Terraform Provider](https://github.com/fourplusone/terraform-provider-jira)

#### Note: This script configures Jira Server WebHooks. Jira Server Logs collection needs to be configured as explained in Step 1 [here](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jira/Collect_Logs_for_Jira#step-1-set-up-local-file-sources-on-an-installed-collector). Configure the log collection and update the variable `jira_on_prem_access_logs_sourcecategory` in `terraform.tfvars` with the selected source category.

| Parameter | Description |
| --- | --- |
| jira_on_prem_access_logs_sourcecategory| Jira Server Access Logs Source Category, default "Atlassian/Jira/Server*", refer [this](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jira/Collect_Logs_for_Jira#step-1-set-up-local-file-sources-on-an-installed-collector) link.|
| jira_on_prem_url        | Jira Server URL                |
| jira_on_prem_user       | Jira Server Username           |
| jira_on_prem_password   | Needs to be the password. API Key is not supported on Jira Server yet.           |
| jira_on_prem_jql        | Jira Server [Query](https://support.atlassian.com/jira-software-cloud/docs/what-is-advanced-searching-in-jira-cloud/) Language Example: "project = Sumo" |
| jira_on_prem_events     | Jira Server [Events](https://developer.atlassian.com/server/jira/platform/webhooks/) |

## Bitbucket

[Bitbucket Terraform Provider](https://github.com/terraform-providers/terraform-provider-bitbucket)

| Parameter | Description |
| --- | --- |
| bitbucket_cloud_user          | Bitbucket Username           |
| bitbucket_cloud_password      | Bitbucket password or [App Password](https://confluence.atlassian.com/bitbucket/app-passwords-828781300.html) |
| bitbucket_cloud_owner         | The owner of the repositories. Can be you or any team you have write access to|
| bitbucket_cloud_repos         | Specify the repositories for which WebHooks should be created. Format: ["repo1","repo2"] |
| bitbucket_cloud_desc          | The name / description to show in the UI          |
| bitbucket_cloud_events        | Bitbucket [Events](https://confluence.atlassian.com/bitbucket/event-payloads-740262817.html) to track           |

## OpsGenie

[Rest API Terraform Provider](https://github.com/Mastercard/terraform-provider-restapi)

| Parameter | Description |
| --- | --- |
| opsgenie_api_url        | [OpsGenie API URL](https://docs.opsgenie.com/docs/api-overview). Do not add the trailing "/". If using the EU instance of Opsgenie, the URL needs to be https://api.eu.opsgenie.com for requests to be executed.                 |
| opsgenie_key            | [OpsGenie API Key](https://docs.opsgenie.com/docs/api-integration)              |

## Sumologic to Opsgenie Webhook

| Parameter | Description |
| --- | --- |
| opsgenie_priority             | [Opsgenie Alert Priority](https://docs.opsgenie.com/docs/priority-field)|