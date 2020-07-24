# sumologic-sdp-terraform

The Sumo Logic Software Delivery Performance (SDP) solution provides an established framework to simplify the monitoring and troubleshooting of your software delivery infrastructure.
* This Terraform script installs the Sumo Logic Software Delivery Performance (SDP) solution collection and Applications in the personal folder of the Sumo Logic user whose access keys have been used.
* If you need additional copies of the Applications within Sumo Logic, install the respective Apps from the Sumo Logic App catalog.

## Getting Started

#### Requirements

* [Terraform 0.12.20+](https://www.terraform.io/downloads.html)
* [curl](https://curl.haxx.se/download.html)
* Required Terraform providers (tested on mentioned versions), these providers are automatically installed on `terraform init`:
  * [Template](https://www.terraform.io/docs/providers/template/index.html) "~> 2.1"
  * [Null](https://www.terraform.io/docs/providers/null/index.html) "~> 2.1"
  * [BitBucket Terraform Provider](https://www.terraform.io/docs/providers/bitbucket/index.html) "~> 1.2"
  * [Sumo Logic Terraform Provider](https://www.terraform.io/docs/providers/sumologic/index.html) "~> 2.0"
  * [Github Terraform Provider](https://www.terraform.io/docs/providers/github/index.html) "~> 2.8"
  * [Pagerduty Terraform Provider](https://www.terraform.io/docs/providers/pagerduty/index.html) "~> 1.7"


* Required Third Party Terraform providers (tested on mentioned versions), these providers need explicit installation as explained [here](https://www.terraform.io/docs/configuration/providers.html#third-party-plugins):
  * [Jira Terraform Provider](https://github.com/fourplusone/terraform-provider-jira) "~> 0.1.11"
  * [Rest API Terraform Provider](https://github.com/Mastercard/terraform-provider-restapi) "~> 1.12"

#### Setup working directory

1. Clone the repository:

```shell
$ git clone https://github.com/SumoLogic/sumologic-solution-templates.git
```
2. Install [Terraform](https://www.terraform.io/) and make sure it's on your PATH.
3. Install the required third party terraform providers ([Jira Terraform Provider](https://github.com/fourplusone/terraform-provider-jira), [Rest API Terraform Provider](https://github.com/Mastercard/terraform-provider-restapi) ) as explained [here](https://www.terraform.io/docs/configuration/providers.html#third-party-plugins) and on respective provider documentation.
4. Initialize the Terraform working directory and download the official providers by navigating to the directory `sumologic-solution-templates/software-delivery-performance-terraform` and running `terraform init`. This will install the required Terraform providers i.e. [Sumo Logic Terraform Provider](https://www.terraform.io/docs/providers/sumologic/index.html), [Template](https://www.terraform.io/docs/providers/template/index.html), [Null](https://www.terraform.io/docs/providers/null/index.html), [BitBucket Terraform Provider](https://www.terraform.io/docs/providers/bitbucket/index.html), [Github Terraform Provider](https://www.terraform.io/docs/providers/github/index.html) and [Pagerduty Terraform Provider](https://www.terraform.io/docs/providers/pagerduty/index.html).
5. You can choose which applications and Webhooks to install by updating the flags `install_jira_cloud`, `install_jira_server`, `install_bitbucket_cloud`,`install_opsgenie`,`install_github`,`install_pagerduty`,`install_sumo_to_opsgenie_webhook`, `install_sumo_to_jiraserver_webhook`, `install_sumo_to_jiraservicedesk_webhook`, `install_sumo_to_jiracloud_webhook` and `install_sumo_to_pagerduty_webhook` in `sumologic.auto.tfvars`. By default, all components except `Sumologic to Opsgenie Webhook` and `Sumologic to Jira Webhooks` are installed.
`Sumologic to Opsgenie Webhook` and `Sumologic to Jira Webhooks` are in Beta. To participate contact your Sumo account executive.
6. Update the placeholder values in `sumologic.auto.tfvars`, `atlassian.auto.tfvars`, `pagerduty.auto.tfvars`, `github.auto.tfvars`, `sumologic_fer.auto.tfvars` and `sumologic_webhooks.auto.tfvars` so they correspond with your Sumo Logic, Atlassian, Github and Pagerduty environments. See the [list of input parameters](#configurable-parameters) below.

#### Deploy Sumo Logic - SDP Solution

To deploy Sumo Logic - SDP Solution, navigate to the directory `sumologic-solution-templates/software-delivery-performance-terraform` and execute the below commands:

```shell
$ terraform plan
$ terraform apply
```
#### Uninstall Sumo Logic - SDP Solution

To uninstall the solution, navigate to the directory `sumologic-solution-templates/software-delivery-performance-terraform` and execute the below command:

```shell
$ terraform destroy
```
There are times when you want to plan the destroy prior to executing the command. To do so, add the -destroy flag to the terraform plan command and then apply the destroy command, for example:

```shell
$ terraform plan -destroy
$ terraform destroy
```


## Configurable Parameters

Configure the following parameters in `sumologic.auto.tfvars`, `atlassian.auto.tfvars`, `github.auto.tfvars`, `pagerduty.auto.tfvars`, `sumologic_fer.auto.tfvars` and `webhooks.auto.tfvars`.

### Sumo Logic

[Sumo Logic Terraform Provider](https://github.com/SumoLogic/sumologic-terraform-provider)

Configure these parameters in `sumologic.auto.tfvars`.

Note: `Sumologic to Opsgenie Webhook` and `Sumologic to Jira Webhooks` are in Beta. To participate contact your Sumo account executive.

| Parameter |Description |Default Value
| --- | --- | --- |
| sumo_access_id            | [Sumo Logic Access ID](https://help.sumologic.com/Manage/Security/Access-Keys)  |       |
| sumo_access_key           | [Sumo Logic Access Key](https://help.sumologic.com/Manage/Security/Access-Keys) |       |
| deployment                | [Sumo Logic Deployment](https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security)                                                                   | us1   |
| sumo_api_endpoint         | [Sumo Logic API Endpoint](https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security). Make sure the trailing "/" is present.                    | https://api.sumologic.com/api/v1/  |
| app_installation_folder   | The Sumo Logic apps will be installed in a folder under your personal folder in Sumo Logic.| SDP|
| install_jira_cloud        | Install [Sumo Logic Application and WebHooks for Jira Cloud](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jira_Cloud)            | true  |
| install_jira_server       | Install [Sumo Logic Application and WebHooks for Jira Server](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jira) | true  |
| install_bitbucket_cloud   | Install [Sumo Logic Application and WebHooks for BitBucket Cloud](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Bitbucket)       | true  |       |
| install_opsgenie          | Install [Sumo Logic Application and WebHooks for Opsgenie](https://help.sumologic.com/07Sumo-Logic-Apps/18SAAS_and_Cloud_Apps/Opsgenie)      | true  |
| install_github            | Install [Sumo Logic Application and WebHooks for Github](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/GitHub)      | true  |
| install_pagerduty         | Install [Sumo Logic Application and WebHooks for Pagerduty](https://help.sumologic.com/07Sumo-Logic-Apps/18SAAS_and_Cloud_Apps/PagerDuty_V2)      | true  |
| install_sumo_to_opsgenie_webhook | Install [Sumo Logic to Opsgenie WebHook](https://help.sumologic.com/Beta/Webhook_Connection_for_Opsgenie). `install_opsgenie` should be true for this option to be true. |  false  |
| install_sumo_to_jiracloud_webhook| Install [Sumo Logic to Jira Cloud WebHook](https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Cloud) | false |
| install_sumo_to_jiraserver_webhook| Install [Sumo Logic to Jira Server WebHook](https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Server) | false |
| install_sumo_to_jiraservicedesk_webhook| Install [Sumo Logic to Jira Service Desk WebHook](https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Service_desk) | false |
| install_sumo_to_pagerduty_webhook| Install [Sumo Logic to Pagerduty WebHook](https://help.sumologic.com/Manage/Connections-and-Integrations/Webhook-Connections/Webhook-Connection-for-PagerDuty) | true |
| jira_cloud_sc        | Source Category for [Jira Cloud](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jira_Cloud)            | SDP/Jira/Cloud  |
| jira_server_sc       | Source Category for [Jira Server](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jira)                 | SDP/Jira/Server/Events  |
| bitbucket_sc         | Source Category for [BitBucket Cloud](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Bitbucket)        | SDP/Bitbucket  |       |
| opsgenie_sc          | Source Category for [Opsgenie](https://help.sumologic.com/07Sumo-Logic-Apps/18SAAS_and_Cloud_Apps/Opsgenie)            | SDP/Opsgenie  |
| pagerduty_sc         | Source Category for [Pagrduty](https://help.sumologic.com/07Sumo-Logic-Apps/18SAAS_and_Cloud_Apps/PagerDuty_V2)        | SDP/Pagerduty  |
| github_sc            | Source Category for [Github](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/GitHub)                    | SDP/Github  |
| jenkins_sc           | Source Category for [Jenkins](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jenkins)                  | SDP/Jenkins  |

### Sumo Logic Field Extraction Rules

[Sumo Logic Terraform Provider](https://github.com/SumoLogic/sumologic-terraform-provider)

Configure these parameters in `sumologic_fer.auto.tfvars`. There are a set of FER's for the SDP Apps. Each FER needs a `scope` and a `parse expression`. In most cases default values will suffice, if required you can edit the `scope` and `parse expression` as per your requirements.

| Parameter |Description |
| --- | --- |
| (app)_pull_request_fer_scope           | [FER](https://help.sumologic.com/Manage/Field-Extractions/Create-a-Field-Extraction-Rule)  |
| (app)_pull_request_fer_parse           | [FER](https://help.sumologic.com/Manage/Field-Extractions/Create-a-Field-Extraction-Rule) |

`app` can be jira_cloud, jira_server, github, bitbucket, pagerduty, opsgenie or jenkins.


## Jira Cloud

[Jira Terraform Provider](https://github.com/fourplusone/terraform-provider-jira)

Configure these parameters in `atlassian.auto.tfvars`.

| Parameter | Description |
| --- | --- |
| jira_cloud_url        | Jira Cloud URL                |
| jira_cloud_user       | Jira Cloud Username           |
| jira_cloud_password   | Jira Cloud Password or [API Key](https://confluence.atlassian.com/cloud/api-tokens-938839638.html)|
| jira_cloud_jql        | Jira Cloud [Query Language](https://support.atlassian.com/jira-software-cloud/docs/what-is-advanced-searching-in-jira-cloud/) Example: "project = Sumo"|
| jira_cloud_events     | Jira Cloud [Events](https://developer.atlassian.com/cloud/jira/platform/webhooks/)|

## Sumo Logic to Jira Cloud Webhook

This feature is in Beta. To participate contact your Sumo account executive.
Configure these parameters in `webhooks.auto.tfvars`.

| Parameter | Description |
| --- | --- |
| jira_cloud_auth             | [Basic Authorization Header](https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Cloud#prerequisite)|
| jira_cloud_projectkey       | Jira Cloud [Project Key](https://support.atlassian.com/jira-core-cloud/docs/edit-a-projects-details/)                   |
| jira_cloud_issuetype        | Jira Cloud [Issue Type](https://confluence.atlassian.com/adminjiracloud/issue-types-844500742.html), for example 'Bug' |
| jira_cloud_priority         | Issue Priority, for example 3            |

## Sumo Logic to Jira Service Desk Webhook

This feature is in Beta. To participate contact your Sumo account executive.
Configure these parameters in `webhooks.auto.tfvars`.

| Parameter | Description |
| --- | --- |
| jira_servicedesk_url              | Jira Service Desk URL, can be same as Jira Cloud URL|
| jira_servicedesk_auth             | [Basic Authorization Header](https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Service_Desk#prerequisite)|
| jira_servicedesk_projectkey       | Jira Service Desk [Project Key](https://support.atlassian.com/jira-core-cloud/docs/edit-a-projects-details/)                   |
| jira_servicedesk_issuetype        | Jira Service Desk [Issue Type](https://confluence.atlassian.com/adminjiracloud/issue-types-844500742.html), for example 'Bug' |
| jira_servicedesk_priority         | Issue Priority, for example 3            |


## Jira Server

[Jira Terraform Provider](https://github.com/fourplusone/terraform-provider-jira)

Configure these parameters in `atlassian.auto.tfvars`.

#### Note: This script configures Jira Server WebHooks and creates resources in Sumo Logic. Jira Server Logs collection needs to be configured as explained in Step 1 [here](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jira/Collect_Logs_for_Jira#step-1-set-up-local-file-sources-on-an-installed-collector). Configure the log collection and update the variable `jira_server_access_logs_sourcecategory` in `atlassian.auto.tfvars` with the selected source category.

| Parameter | Description |
| --- | --- |
| jira_server_access_logs_sourcecategory| Jira Server Access Logs Source Category, default "SDP/Jira/Server*", refer [this](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jira/Collect_Logs_for_Jira#step-1-set-up-local-file-sources-on-an-installed-collector) link.|
| jira_server_url        | Jira Server URL                |
| jira_server_user       | Jira Server Username           |
| jira_server_password   | Needs to be the password. API Key is not supported on Jira Server yet.           |
| jira_server_jql        | Jira Server [Query](https://support.atlassian.com/jira-software-cloud/docs/what-is-advanced-searching-in-jira-cloud/) Language Example: "project = Sumo" |
| jira_server_events     | Jira Server [Events](https://developer.atlassian.com/server/jira/platform/webhooks/) |

## Sumo Logic to Jira Server Webhook

This feature is in Beta. To participate contact your Sumo account executive.
Configure these parameters in `webhooks.auto.tfvars`.

| Parameter | Description |
| --- | --- |
| jira_server_auth             | [Basic Authorization Header](https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Server#prerequisite)|
| jira_server_projectkey       | Jira Server [Project Key](https://confluence.atlassian.com/adminjiraserver/defining-a-project-938847066.html)                   |
| jira_server_issuetype        | Jira Server [Issue Type](https://confluence.atlassian.com/adminjiraserver/defining-issue-type-field-values-938847087.html), for example 'Bug' |
| jira_server_priority         | Issue [Priority](https://confluence.atlassian.com/adminjiraserver/associating-priorities-with-projects-939514001.html), for example 3            |

## Bitbucket

[Bitbucket Terraform Provider](https://github.com/terraform-providers/terraform-provider-bitbucket)

Configure these parameters in `atlassian.auto.tfvars`.

#### Note: This script configures Bitbucket WebHooks and creates resources in Sumo Logic. Configure the [Bitbucket CI/CD Pipeline to Collect Deploy Events](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Bitbucket/Collect_Logs_for_Bitbucket_App#Step_3:_Configure_the_Bitbucket_CI.2FCD_Pipeline_to_Collect_Deploy_Events) as defined in Sumo Logic [help](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Bitbucket/Collect_Logs_for_Bitbucket_App).

| Parameter | Description |
| --- | --- |
| bitbucket_cloud_user          | Bitbucket Username           |
| bitbucket_cloud_password      | Bitbucket password or [App Password](https://confluence.atlassian.com/bitbucket/app-passwords-828781300.html) |
| bitbucket_cloud_owner         | The owner of the repositories. Can be you or any team you have write access to|
| bitbucket_cloud_repos         | Specify the repositories for which WebHooks should be created. Format: ["repo1","repo2"] |
| bitbucket_cloud_desc          | The name / description to show in the UI          |
| bitbucket_cloud_events        | Bitbucket [Events](https://confluence.atlassian.com/bitbucket/event-payloads-740262817.html) to track           |

## Opsgenie

[Rest API Terraform Provider](https://github.com/Mastercard/terraform-provider-restapi)

Configure these parameters in `atlassian.auto.tfvars`.

| Parameter | Description |
| --- | --- |
| opsgenie_api_url        | [Opsgenie API URL](https://docs.opsgenie.com/docs/api-overview). Do not add the trailing "/". If using the EU instance of Opsgenie, the URL needs to be https://api.eu.opsgenie.com for requests to be executed.                 |
| opsgenie_key            | [Opsgenie API Key](https://docs.opsgenie.com/docs/api-integration)              |

## Sumo Logic to Opsgenie Webhook

This feature is in Beta. To participate contact your Sumo account executive.
Configure these parameters in `webhooks.auto.tfvars`.

| Parameter | Description |
| --- | --- |
| opsgenie_priority             | [Opsgenie Alert Priority](https://docs.opsgenie.com/docs/priority-field)|

## Pagerduty

[Pagerduty Terraform Provider](https://www.terraform.io/docs/providers/pagerduty/index.html)

Configure these parameters in `pagerduty.auto.tfvars`.

| Parameter | Description |
| --- | --- |
| pagerduty_api_key        | [Pagerduty API Key](https://support.pagerduty.com/docs/generating-api-keys#section-generating-a-general-access-rest-api-key). |
| pagerduty_services_pagerduty_webhooks       | List of Pagerduty Service IDs. Example, ["P1QWK8J","PK9FKW3"]. You can get these from the URL after opening a specific service in Pagerduty. These are used for Pagerduty to Sumo Logic webhooks.              |

## Sumo Logic to Pagerduty Webhook

Configure these parameters in `webhooks.auto.tfvars`.

| Parameter | Description |
| --- | --- |
| pagerduty_services_sumo_webhooks             | [Sumo Logic to Pagerduty Webhook](https://help.sumologic.com/Manage/Connections-and-Integrations/Webhook-Connections/Webhook-Connection-for-PagerDuty). List of Pagerduty Service IDs. Example, ["P1QWK8J","PK9FKW3"]. You can get these from the URL after opening a specific service in Pagerduty. These are used for Sumo Logic to Pagerduty Webhooks. |

## Github

Configure these parameters in `github.auto.tfvars`.

| Parameter | Description |
| --- | --- |
| github_token             | [Github Token](https://github.com/settings/tokens)|
| github_organization      | Organization Name. |
| github_repo_webhook_create| Create webhooks at repo level. Default "true".|
| github_repository_names  | List of repository names for which webhooks need to be created. Example, ["repo1","repo2"]  |
| github_org_webhook_create| Create webhooks at org level. Default "false".|
| github_repo_events       | List of repository [events](https://docs.github.com/en/developers/webhooks-and-events/webhook-events-and-payloads) which should be sent to Sumo Logic. Example, ["create","delete","fork"] |
| github_org_events        | List of organization level [events](https://docs.github.com/en/developers/webhooks-and-events/webhook-events-and-payloads) which should be sent to Sumo Logic. Example, ["create","delete","fork"] |

## Jenkins

To configure Jenkins, please follow the [step 3](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jenkins/Collect_Logs_and_Metrics_for_Jenkins#step-3-install-the-jenkins-plugin), [step 4](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jenkins/Collect_Logs_and_Metrics_for_Jenkins#step-4-configure-jenkins-plugin) and optionally [step 5](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jenkins/Collect_Logs_and_Metrics_for_Jenkins#step-5-optional-advanced-configuration) to install and configure the Jenkins Sumo Logic plugin.

In [step 4](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jenkins/Collect_Logs_and_Metrics_for_Jenkins#step-4-configure-jenkins-plugin), a source category is configured which is utilized by the plugin, specify the same source category in the below mentioned parameter in `sumologic.auto.tfvars`.

| Parameter | Description |
| --- | --- |
| jenkins_sc   | [Jenkins Source Category](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jenkins/Collect_Logs_and_Metrics_for_Jenkins#step-4-configure-jenkins-plugin).|

## License

The SDP Terraform is licensed under the apache v2.0 license.

## Issues

Raise issues at [Issues](https://github.com/SumoLogic/sumologic-solution-templates/issues)

## Contributing

* Fork the project on [Github](https://github.com/SumoLogic/sumologic-solution-templates).
* Make your feature addition or fix bug, write tests and commit.
* Create a pull request with one of the maintainer as Reviewer.