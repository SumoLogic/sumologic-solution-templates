# Sumo Logic - Atlassian Terraform
# Configure Sumo Logic Webhook configuration options. Some features are in Beta. To participate contact your Sumo account executive.


# Sumo Logic to Opsgenie Webhook - This feature is in Beta. To participate contact your Sumo account executive.
opsgenie_priority = "P3"


# Sumo Logic to Jira Cloud Webhook - This feature is in Beta. To participate contact your Sumo account executive.
# https://developer.atlassian.com/cloud/jira/platform/rest/v2/#api-rest-api-2-issue-post
jira_cloud_issuetype  = "Bug" # Refer: https://confluence.atlassian.com/adminjiracloud/issue-types-844500742.html
jira_cloud_priority   = "3"
jira_cloud_projectkey = "<JIRA CLOUD PROJECT KEY>"                # Please replace <JIRA CLOUD PROJECT KEY> (including brackets) with your Jira cloud project key. Refer, https://support.atlassian.com/jira-core-cloud/docs/edit-a-projects-details/
jira_cloud_auth       = "<JIRA CLOUD BASIC AUTHORIZATION HEADER>" # Please replace <JIRA CLOUD BASIC AUTHORIZATION HEADER> (including brackets) with the Basic Authorization Header for JIRA cloud as explained here: https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Cloud#prerequisite


# Sumo Logic to Jira Server Webhook - This feature is in Beta. To participate contact your Sumo account executive.
# https://docs.atlassian.com/software/jira/docs/api/REST/7.6.1/#api/2/issue-createIssue
jira_server_issuetype  = "Bug"                                           # Refer: https://confluence.atlassian.com/adminjiraserver/defining-issue-type-field-values-938847087.html
jira_server_priority   = "3"                                             # Refer: https://confluence.atlassian.com/adminjiraserver/associating-priorities-with-projects-939514001.html
jira_server_projectkey = "<YOUR JIRA SERVER PROJECT KEY>"                # Please replace <YOUR JIRA SERVER PROJECT KEY> (including brackets) with your Jira server project key.
jira_server_auth       = "<YOUR JIRA SERVER BASIC AUTHORIZATION HEADER>" # Please replace <YOUR JIRA SERVER BASIC AUTHORIZATION HEADER> (including brackets) with the Basic Authorization Header for JIRA server as explained here See: https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Server#prerequisite

# Sumo Logic to Jira Service Desk Webhook - This feature is in Beta. To participate contact your Sumo account executive.
jira_servicedesk_url        = "https://<EXAMPLE>.atlassian.net"
jira_servicedesk_issuetype  = "IT Help"
jira_servicedesk_priority   = "3"
jira_servicedesk_projectkey = "<JIRA SERVICE DESK PROJECT KEY>"                # Please replace <JIRA SERVICE DESK PROJECT KEY> (including brackets) with your Jira service desk project key.
jira_servicedesk_auth       = "<JIRA SERVICE DESK BASIC AUTHORIZATION HEADER>" # Please replace <JIRA SERVICE DESK BASIC AUTHORIZATION HEADER> (including brackets) with the Basic Authorization Header for JIRA Service Desk as explained here: https://help.sumologic.com/Beta/Webhook_Connection_for_Jira_Service_Desk#prerequisite