####### BELOW ARE REQUIRED PARAMETERS FOR TERRAFORM SCRIPT #######
# Visit - https://help.sumologic.com/Solutions/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution#sumo-logic-access-configuration-required

sumologic_environment     = ""   # Please replace <YOUR SUMO DEPLOYMENT> (including brackets) with au, ca, de, eu, jp, us2, in, fed or us1.
sumologic_access_id       = ""
sumologic_access_key      = ""
sumologic_organization_id = ""  # Please replace <YOUR SUMO ORG ID> (including brackets) with your Sumo Logic Organization ID.
aws_account_alias         = ""  # Please replace <YOUR AWS ACCOUNT ALIAS> with an AWS account alias for identification in Sumo Logic Explorer View, metrics and logs.
# Example: https://api.sumologic.com/api/ Please update with your sumologic api endpoint. Refer, https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security
sumo_api_endpoint         = ""  #"<YOUR SUMOLOGIC API ENDPOINT>"

# # passing values
# executeTest1 = "true"
# executeTest2 = "true"
# executeTest3 = "true"
# executeTest4 = "true"
# collector_id = ""
# s3_name = ""
# create_collector = false
# collect_elb = "true"
# collect_classic_lb = "true"
# collect_cloudtrail = "true"
# collect_rce = "Xray Source"
# collect_logs_cloudwatch = "Kinesis Firehose Log Source"
# collect_metric_cloudwatch = "CloudWatch Metrics Source"
# create_s3_bucket = false