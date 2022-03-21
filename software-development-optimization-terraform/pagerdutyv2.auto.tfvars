# Sumo Logic - SDO Terraform
# Configure Pagerduty credentials and parameters.

# Please replace <YOUR PAGERDUTY API KEY> (including brackets) with your Pagerduty key, to generate the key, refer: https://support.pagerduty.com/docs/generating-api-keys#section-generating-a-general-access-rest-api-key
pagerduty_api_key                     = "<YOUR PAGERDUTY API KEY>"
# Please replace <SERVICE1> and <SERVICE2> (including > brackets) with your Pagerduty service IDs. You can get these from the URL after opening a specific service. These are used for Pagerduty to Sumo Logic webhooks.
# Examples: ["P6HHD","PHGBUY"] or ["P76GFB"]
pagerduty_services_pagerduty_webhooks = ["<SERVICE1>","<SERVICE2>"]