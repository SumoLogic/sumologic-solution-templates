# Sumo Logic - Atlassian Terraform
# Configure Sumo Logic, Jira Cloud, Jira Server (Onprem), OpsGenie, BitBucket credentials and installation options.

# Sumologic
sumo_access_id = "" # https://help.sumologic.com/Manage/Security/Access-Keys
sumo_access_key = ""
environment = "us1" # https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security
sumo_api_endpoint = "https://api.sumologic.com/api/v1/" # Make sure the trailing "/" is present. https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security
app_installation_folder = "Atlassian" # The Sumo Logic apps will be installed in a folder under your personal folder in Sumo Logic.

# Sumo Logic Apps and Webhooks
install_jira_cloud = "true"
install_jira_on_prem = "true"
install_bitbucket_cloud = "true"
install_opsgenie = "true"
# install_opsgenie should be true for the below option install_sumo_to_opsgenie_webhook to be true. https://help.sumologic.com/Manage/Connections-and-Integrations/Webhook-Connections/Webhook_Connection_for_Opsgenie
install_sumo_to_opsgenie_webhook = "false" # This feature is in Beta. To participate contact your Sumo account executive. You can modify the file sumo_to_opsgenie_webhook.json.tmpl for customizing payload.
install_atlassian_app = "true"
install_sumo_to_jiracloud_webhook = "false" # This feature is in Beta. To participate contact your Sumo account executive. You can modify the file sumo_to_jiracloud_webhook.json.tmpl for customizing payload.
install_sumo_to_jiraserver_webhook = "false" # This feature is in Beta. To participate contact your Sumo account executive. You can modify the file sumo_to_jiraserver_webhook.json.tmpl for customizing payload.

# Jira Cloud
jira_cloud_url = "https://<example>.atlassian.net"
jira_cloud_user = ""
jira_cloud_password = "" # Password or API Key, To generate API Key: https://confluence.atlassian.com/cloud/api-tokens-938839638.html
jira_cloud_jql = "" #jql = "project = Sumo" See, https://support.atlassian.com/jira-software-cloud/docs/what-is-advanced-searching-in-jira-cloud/
// See https://developer.atlassian.com/cloud/jira/platform/webhooks/ for supported events
jira_cloud_events = ["jira:issue_created", "jira:issue_updated","jira:issue_deleted",
"issue_property_set","issue_property_deleted","comment_created","comment_updated","comment_deleted",
"worklog_created","worklog_updated","worklog_deleted",
"attachment_created","attachment_deleted","issuelink_created","issuelink_deleted",
"project_created","project_updated","project_deleted",
"jira:version_released","jira:version_unreleased","jira:version_created","jira:version_moved","jira:version_updated","jira:version_deleted","jira:version_deleted",
"user_created","user_updated","user_deleted",
"option_voting_changed","option_watching_changed","option_watching_changed","option_unassigned_issues_changed","option_subtasks_changed","option_attachments_changed","option_issuelinks_changed","option_timetracking_changed",
"sprint_created","sprint_deleted","sprint_updated","sprint_started","sprint_closed",
"board_created","board_updated","board_deleted","board_configuration_changed",
"jira_expression_evaluation_failed"]

# Sumologic to Jira Cloud Webhook - This feature is in Beta. To participate contact your Sumo account executive.
# https://developer.atlassian.com/cloud/jira/platform/rest/v2/#api-rest-api-2-issue-post
jira_cloud_issuetype = "Bug"
jira_cloud_priority = "3"
jira_cloud_projectkey = "project"
jira_cloud_auth = "" #Basic Authorization Header. See: https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Cloud#prerequisite

# Jira On Prem/Server
# This script configures Jira Server WebHooks. Jira Server Logs collection needs to be configured as explained in Step 1 [here](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jira/Collect_Logs_for_Jira#step-1-set-up-local-file-sources-on-an-installed-collector).
# Configure the log collection and update the variable jira_on_prem_access_log_category with the selected source category.
jira_on_prem_access_logs_sourcecategory = "Atlassian/Jira/Server*"
jira_on_prem_url = ""
jira_on_prem_user = ""
jira_on_prem_password = "" # Needs to be the password. API Key is not supported on Jira Server yet: https://jira.atlassian.com/browse/JRASERVER-67869?_ga=2.198461357.302520551.1583314185-1454539139.1580206139&error=login_required&error_description=Login+required&state=d3142ec3-6eb1-4207-bdd7-ce6b93900aa1
jira_on_prem_jql = ""
// See https://developer.atlassian.com/server/jira/platform/webhooks/ for supported events
jira_on_prem_events = ["jira:issue_created", "jira:issue_updated","jira:issue_deleted",
"jira:worklog_updated","issuelink_created","issuelink_deleted",
"worklog_created","worklog_updated","worklog_deleted","project_created","project_updated","project_deleted",
"jira:version_released","jira:version_unreleased","jira:version_created","jira:version_moved","jira:version_updated","jira:version_deleted","jira:version_deleted",
"user_created","user_updated","user_deleted",
"option_voting_changed","option_watching_changed","option_unassigned_issues_changed","option_subtasks_changed","option_attachments_changed","option_issuelinks_changed","option_timetracking_changed",
"sprint_created","sprint_deleted","sprint_updated","sprint_started","sprint_closed",
"board_created","board_updated","board_deleted","board_configuration_changed"]

# Sumologic to Jira Server Webhook - This feature is in Beta. To participate contact your Sumo account executive.
# https://docs.atlassian.com/software/jira/docs/api/REST/7.6.1/#api/2/issue-createIssue
jira_server_issuetype = "Bug"
jira_server_priority = "3"
jira_server_projectkey = "project"
jira_server_auth = "" #Basic Authorization Header. See: https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Server#prerequisite

# Bitbucket Cloud
# Parameter Description: https://www.terraform.io/docs/providers/bitbucket/r/hook.html
bitbucket_cloud_user = ""
bitbucket_cloud_password = "" # App Passwords also work. To generate App Password see: https://confluence.atlassian.com/bitbucket/app-passwords-828781300.html
bitbucket_cloud_owner = "" # The owner of the repositories. Can be you or any team you have write access to.
bitbucket_cloud_repos  = [] # Specify the repositories for which WebHooks should be created. Format: ["repo1","repo2"]
bitbucket_cloud_desc = "Send events to Sumo Logic" # The name / description to show in the UI.
# Events: https://confluence.atlassian.com/bitbucket/event-payloads-740262817.html
bitbucket_cloud_events = [
    "repo:push", "repo:fork" , "repo:updated", "repo:commit_comment_created"
    ,"repo:commit_status_updated","repo:commit_status_created"
    , "issue:created", "issue:updated", "issue:comment_created"
    , "pullrequest:created", "pullrequest:updated", "pullrequest:approved", "pullrequest:unapproved" , "pullrequest:fulfilled", "pullrequest:rejected"
    , "pullrequest:comment_created", "pullrequest:comment_updated", "pullrequest:comment_deleted"
  ]

# OpsGenie
opsgenie_api_url = "https://api.opsgenie.com" # Do not add the trailing /. If using the EU instance of Opsgenie, the URL needs to be https://api.eu.opsgenie.com for requests to be executed. https://docs.opsgenie.com/docs/api-overview
opsgenie_key = "" # https://docs.opsgenie.com/docs/api-key-management

# Sumologic to Opsgenie Webhook
opsgenie_priority = "P3"