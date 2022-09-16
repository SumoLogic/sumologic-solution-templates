####### BELOW ARE REQUIRED PARAMETERS FOR TERRAFORM SCRIPT #######
# Visit - https://help.sumologic.com/Observability_Solution/Application_Component_Solution/

sumologic_environment     = ""   # Please replace <YOUR SUMO DEPLOYMENT> (including brackets) with au, ca, de, eu, jp, us2, in, fed or us1.
sumologic_access_id       = ""   # Please replace <YOUR SUMO ACCESS ID> (including brackets) with your Sumo Logic Access ID.
sumologic_access_key      = ""   # Please replace <YOUR SUMO ACCESS KEY> (including brackets) with your Sumo Logic Access KEY.
sumologic_organization_id = ""   # Please replace <YOUR SUMO ORG ID> (including brackets) with your Sumo Logic Organization ID.

apps_folder_installation_location = "Personal Folder" # Please specify the location where the sumologic apps/dashboards will be installed.
share_apps_folder_with_org = true # Set this to true to share with view permissions with the entire sumologic org.

# Specify the database engine types comma separated from the following list of supported db engines - memcached,cassandra,elasticsearch,sqlserver,mongodb,mysql,postgresql,redis,mariadb,couchbase,oracle.
database_engines = "memcached"

# Specify the data source for which you want to enable the monitors. By default it's enabled for all.
# Example to enable for clusters starting with prod prefix set below parameter to db_system=memcached AND db_cluster=prod*
# memcached_data_source = "db_system=memcached"

# Set it to false to enable the monitors. By default they are disabled
# monitors_disabled=false


connection_notifications = []
# To configure notification via pagerduty or webhook, uncomment below lines and
# replace <CONNECTION_ID> with the connection id of the webhook connection.
# The webhook connection id can be retrieved by calling the Monitors API(https://api.sumologic.com/docs/#operation/listConnections)
# connection_notifications = [
#     {
#       connection_type       = "PagerDuty",
#       connection_id         = "<CONNECTION_ID>",
#       payload_override      = "{\"service_key\": \"your_pagerduty_api_integration_key\",\"event_type\": \"trigger\",\"description\": \"Alert: Triggered {{TriggerType}} for Monitor {{Name}}\",\"client\": \"Sumo Logic\",\"client_url\": \"{{QueryUrl}}\"}",
#       run_for_trigger_types = ["Critical", "ResolvedCritical"]
#     },
#     {
#       connection_type       = "Webhook",
#       connection_id         = "<CONNECTION_ID>",
#       payload_override      = "",
#       run_for_trigger_types = ["Critical", "ResolvedCritical"]
#     }
#   ]

email_notifications = []
# Uncomment below lines and update the recipients list to send notification from the monitors as email
# email_notifications = [
#    {
#      connection_type       = "Email",
#      recipients            = ["abc@example.com"],
#      subject               = "Monitor Alert: {{TriggerType}} on {{Name}}",
#      time_zone             = "PST",
#      message_body          = "Triggered {{TriggerType}} Alert on {{Name}}: {{QueryURL}}",
#      run_for_trigger_types = ["Critical", "ResolvedCritical"]
#    }
#  ]

