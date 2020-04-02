# Sumo Logic - Atlassian Terraform
# Configure Jira Cloud, Jira Server, OpsGenie, BitBucket credentials and parameters.


# Jira Cloud
jira_cloud_url      = "https://arunpatyal.atlassian.net"
jira_cloud_user     = "arunpatyal0809@gmail.com"
jira_cloud_password = "AVQYnQwD1IdI2GylyUQx99B6" # Password or API Key, To generate API Key: https://confluence.atlassian.com/cloud/api-tokens-938839638.html
jira_cloud_jql      = ""                         #jql = "project = Sumo" See, https://support.atlassian.com/jira-software-cloud/docs/what-is-advanced-searching-in-jira-cloud/
// See https://developer.atlassian.com/cloud/jira/platform/webhooks/ for supported events
jira_cloud_events = ["jira:issue_created", "jira:issue_updated", "jira:issue_deleted",
  "issue_property_set", "issue_property_deleted", "comment_created", "comment_updated", "comment_deleted",
  "worklog_created", "worklog_updated", "worklog_deleted",
  "attachment_created", "attachment_deleted", "issuelink_created", "issuelink_deleted",
  "project_created", "project_updated", "project_deleted",
  "jira:version_released", "jira:version_unreleased", "jira:version_created", "jira:version_moved", "jira:version_updated", "jira:version_deleted", "jira:version_deleted",
  "user_created", "user_updated", "user_deleted",
  "option_voting_changed", "option_watching_changed", "option_watching_changed", "option_unassigned_issues_changed", "option_subtasks_changed", "option_attachments_changed", "option_issuelinks_changed", "option_timetracking_changed",
  "sprint_created", "sprint_deleted", "sprint_updated", "sprint_started", "sprint_closed",
  "board_created", "board_updated", "board_deleted", "board_configuration_changed",
"jira_expression_evaluation_failed"]


# Jira Server
# This script configures Jira Server WebHooks. Jira Server Logs collection needs to be configured as explained in Step 1 [here](https://help.sumologic.com/07Sumo-Logic-Apps/08App_Development/Jira/Collect_Logs_for_Jira#step-1-set-up-local-file-sources-on-an-installed-collector).
# Configure the log collection and update the variable jira_server_access_log_category with the selected source category.
jira_server_access_logs_sourcecategory = "Atlassian/Jira/Server*"
jira_server_url                        = "http://localhost:8080"
jira_server_user                       = "arunpatyal0809"
jira_server_password                   = "Qazwsx@2!" # Needs to be the password. API Key is not supported on Jira Server yet: https://jira.atlassian.com/browse/JRASERVER-67869?_ga=2.198461357.302520551.1583314185-1454539139.1580206139&error=login_required&error_description=Login+required&state=d3142ec3-6eb1-4207-bdd7-ce6b93900aa1
jira_server_jql                        = ""
// See https://developer.atlassian.com/server/jira/platform/webhooks/ for supported events
jira_server_events = ["jira:issue_created", "jira:issue_updated", "jira:issue_deleted",
  "jira:worklog_updated", "issuelink_created", "issuelink_deleted",
  "worklog_created", "worklog_updated", "worklog_deleted", "project_created", "project_updated", "project_deleted",
  "jira:version_released", "jira:version_unreleased", "jira:version_created", "jira:version_moved", "jira:version_updated", "jira:version_deleted", "jira:version_deleted",
  "user_created", "user_updated", "user_deleted",
  "option_voting_changed", "option_watching_changed", "option_unassigned_issues_changed", "option_subtasks_changed", "option_attachments_changed", "option_issuelinks_changed", "option_timetracking_changed",
  "sprint_created", "sprint_deleted", "sprint_updated", "sprint_started", "sprint_closed",
"board_created", "board_updated", "board_deleted", "board_configuration_changed"]


# Bitbucket Cloud
# Parameter Description: https://www.terraform.io/docs/providers/bitbucket/r/hook.html
bitbucket_cloud_user     = "arunpatyalsumo"
bitbucket_cloud_password = "PeJ6NrdjQfRdR8u7zvYD"      # App Passwords also work. To generate App Password see: https://confluence.atlassian.com/bitbucket/app-passwords-828781300.html
bitbucket_cloud_owner    = "arunpatyalsumo"            # The owner of this repository. Can be you or any team you have write access to.
bitbucket_cloud_repos    = ["repo1", "repo2"]          # Specify the repositories for which WebHooks should be created. Format: ["repo1","repo2"]
bitbucket_cloud_desc     = "Send events to Sumo Logic" # The name / description to show in the UI.
# Events: https://confluence.atlassian.com/bitbucket/event-payloads-740262817.html
bitbucket_cloud_events = [
  "repo:push", "repo:fork", "repo:updated", "repo:commit_comment_created"
  , "repo:commit_status_updated", "repo:commit_status_created"
  , "issue:created", "issue:updated", "issue:comment_created"
  , "pullrequest:created", "pullrequest:updated", "pullrequest:approved", "pullrequest:unapproved", "pullrequest:fulfilled", "pullrequest:rejected"
  , "pullrequest:comment_created", "pullrequest:comment_updated", "pullrequest:comment_deleted"
]


# OpsGenie
opsgenie_api_url = "https://api.opsgenie.com"             # Do not add the trailing /. If using the EU instance of Opsgenie, the URL needs to be https://api.eu.opsgenie.com for requests to be executed.
opsgenie_key     = "0a850a50-aa06-40ea-b37c-a2d9b96d6805" # https://docs.opsgenie.com/docs/api-key-management