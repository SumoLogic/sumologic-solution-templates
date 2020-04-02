# Sumo Logic - Atlassian Terraform
# Configure Sumo Logic Webhook configuration options.


# Sumo Logic to Opsgenie Webhook
opsgenie_priority = "P3"


# Sumo Logic to Jira Cloud Webhook - This feature is in Beta. To participate contact your Sumo account executive.
# https://developer.atlassian.com/cloud/jira/platform/rest/v2/#api-rest-api-2-issue-post
jira_cloud_issuetype  = "Bug"
jira_cloud_priority   = "3"
jira_cloud_projectkey = "WOZ"
jira_cloud_auth       = "Basic YXJ1bnBhdHlhbDA4MDlAZ21haWwuY29tOkFWUVluUXdEMUlkSTJHeWx5VVF4OTlCNg==" # Basic Authorization Header. See: https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Cloud#prerequisite


# Sumo Logic to Jira Server Webhook - This feature is in Beta. To participate contact your Sumo account executive.
# https://docs.atlassian.com/software/jira/docs/api/REST/7.6.1/#api/2/issue-createIssue
jira_server_issuetype  = "Bug"
jira_server_priority   = "3"
jira_server_projectkey = "WOZ"
jira_server_auth       = "Basic YXJ1bnBhdHlhbDA4MDk6UWF6d3N4QDIh" #Basic Authorization Header. See: https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Server#prerequisite