# Sumo Logic - SDO Terraform
# Configure Sumo Logic credentials and App installation options.

# Sumo Logic
# Please replace <YOUR SUMO ACCESS ID> (including brackets) with your Sumo Access ID. https://help.sumologic.com/Manage/Security/Access-Keys
sumo_access_id          = ""
# Please replace <YOUR SUMO ACCESS KEY> (including brackets) with your Sumo Access KEY.
sumo_access_key         = ""
# Please update with your deployment, refer: https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security
deployment              = "us1"
# Example: https://api.sumologic.com/api/ Please update with your sumologic api endpoint. Refer, https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security
sumo_api_endpoint       = "https://api.sumologic.com/api/"
# The Sumo Logic apps will be installed in a folder specified by this value under your personal folder in Sumo Logic.
app_installation_folder = "Software Development Optimization - Getting Started"

# Sumo Logic Apps and Collection. Options are : all, app, fer, collection and none.
# app - for only installing the app
# fer - for only installing the fers
# collection - for configuring collection in Sumo Logic (fers, the sources) and/or in other systems (webhooks).
# all - for installing every component of the setup

# For Jenkins, collection is not configured in Jenkins, choosing collection will create the source in Sumo and will configure the FERs.
# For CircleCI App, "all","none","app" and "collection" are the valid options, choosing all will install the app and create source in Sumo
# For CircleCI_SDO_plugin, "all","none","fer" and "collection" are valid options, choosing collection will create sources and fers to be used on SDO dasboards
# For sdo, app and none are the valid options.
install_jira_cloud      = "none"
install_jira_server     = "none"
install_bitbucket_cloud = "none"
install_opsgenie        = "none"
install_pagerduty       = "none"
install_github          = "all"
install_gitlab          = "none"
install_jenkins         = "none"
install_sdo             = "none"
install_circleci_SDO_plugin = "none"
install_circleci        = "none"

# Sumo Logic App source category
jira_cloud_sc  = "SDO/Jira/Cloud"
jira_server_sc = "SDO/Jira/ServerEvents"
bitbucket_sc   = "SDO/Bitbucket"
opsgenie_sc    = "SDO/Opsgenie"
pagerduty_sc   = "SDO/Pagerduty"
github_sc      = "SDO/Github"
gitlab_sc      = "SDO/Gitlab"
jenkins_sc     = "SDO/Jenkins"
circleci_app_sc = "SDO/CircleCI"


# This feature is in Beta. To participate contact your Sumo account executive.
# install_opsgenie should be all or collection for the below option install_sumo_to_opsgenie_webhook to be true. https://help.sumologic.com/Manage/Connections-and-Integrations/Webhook-Connections/Webhook_Connection_for_Opsgenie
install_sumo_to_opsgenie_webhook        = "false"

# This feature is in Beta. To participate contact your Sumo account executive.
# You can modify the file sumo_to_opsgenie_webhook.json.tmpl for customizing payload.
install_sumo_to_jiracloud_webhook       = "false"

# This feature is in Beta. To participate contact your Sumo account executive.
# You can modify the file sumo_to_jiracloud_webhook.json.tmpl for customizing payload.
install_sumo_to_jiraserver_webhook      = "false"

# This feature is in Beta. To participate contact your Sumo account executive.
# You can modify the file sumo_to_jiraserver_webhook.json.tmpl for customizing payload.
install_sumo_to_jiraservicedesk_webhook = "false"

# You can modify the file sumo_to_jiraservicedesk_webhook.json.tmpl for customizing payload.
install_sumo_to_pagerduty_webhook       = "false"



