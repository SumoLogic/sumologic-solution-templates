# Sumo Logic - Atlassian Terraform
# Configure Sumo Logic credentials and App installation options.

# Sumo Logic
sumo_access_id          = "suZGHyWOCpae0J" # https://help.sumologic.com/Manage/Security/Access-Keys
sumo_access_key         = "Cp4PFmcX95yMFQOQctToPjGwoYpQcy8YGUN4ZsbLUqFsm6ZiSW8zVrznOhZX8MGh"
deployment              = "us1"                                    # https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security
sumo_api_endpoint       = "https://nite-api.sumologic.net/api/v1/" # https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security
app_installation_folder = "Atlassian"                              # The Sumo Logic apps will be installed in a folder under your personal folder in Sumo Logic.

# Sumo Logic Apps and Webhooks
install_jira_cloud      = "true"
install_jira_server     = "true"
install_bitbucket_cloud = "true"
install_opsgenie        = "true"
# install_opsgenie should be true for the below option install_sumo_to_opsgenie_webhook to be true. https://help.sumologic.com/Manage/Connections-and-Integrations/Webhook-Connections/Webhook_Connection_for_Opsgenie
install_sumo_to_opsgenie_webhook   = "true" # You can modify the file sumo_to_opsgenie_webhook.json.tmpl for customizing payload. This feature is in Beta. To participate contact your Sumo account executive.
install_atlassian_app              = "true"
install_sumo_to_jiracloud_webhook  = "true"  # This feature is in Beta. To participate contact your Sumo account executive. You can modify the file sumo_to_jiracloud_webhook.json.tmpl for customizing payload.
install_sumo_to_jiraserver_webhook = "false" # This feature is in Beta. To participate contact your Sumo account executive. You can modify the file sumo_to_jiraserver_webhook.json.tmpl for customizing payload.
